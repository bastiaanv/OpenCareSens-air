// CareSensCalibrator.swift
// Main facade for CareSens Air CGM calibration.
//
// This is the primary entry point for iOS CGM apps to integrate the
// CareSens Air calibration algorithm. It wraps the internal 14-step
// calibration pipeline behind a simple API.

import Foundation
//
// Usage:
//
//   let config = SensorConfig.Builder()
//       .eapp(0.10067)
//       .vref(1.2)
//       .slope100(2.5)
//       .basicWarmup(5)
//       .err345Seq2(5)
//       .wSgX100([-3, 12, 17, 12, 17, 12, -3])
//       .sensorStartTime(sensorStartUnixSeconds)
//       .build()
//
//   let calibrator = CareSensCalibrator(config)
//
//   let result = calibrator.processReading(
//       sequenceNumber: seqNumber,
//       timestamp: timestampSeconds,
//       adcSamples: adcSamples,
//       temperature: temperature
//   )
//
//   if result.isValid {
//       let glucose = result.glucoseMgdl
//       let trend = result.trendRate
//   }
//
// This class is NOT thread-safe. Use external synchronization if calling
// from multiple threads, or (recommended) use one instance per thread.

/// Main facade for CareSens Air CGM calibration.
public final class CareSensCalibrator {

    private let deviceInfo: DeviceInfo
    private var state: AlgorithmState
    private let calList: CalibrationList
    public private(set) var readingsProcessed: Int

    /// Serialization format version. Increment when AlgorithmState layout changes.
    static let stateVersion = 1

    /// Create a new calibrator for a CareSens Air sensor.
    ///
    /// - Parameter config: sensor factory calibration parameters (from BLE advertisement).
    public init(_ config: SensorConfig) {
        self.deviceInfo = config.toDeviceInfo()
        self.state = AlgorithmState()
        self.calList = CalibrationList()
        self.readingsProcessed = 0
    }

    /// Process one raw CGM reading through the full calibration pipeline.
    ///
    /// Call this once per sensor reading (typically every 5 minutes).
    /// The calibrator maintains internal state between calls, so readings
    /// must be processed in order.
    ///
    /// - Parameters:
    ///   - seqNumber: sensor sequence number (starts at 1, increments each reading)
    ///   - timestamp: measurement time in Unix seconds
    ///   - adcSamples: 30 raw ADC sample values from the sensor
    ///   - temperature: skin temperature in degrees Celsius
    /// - Returns: immutable calibration result
    /// - Precondition: `adcSamples` must have exactly 30 elements.
    public func processReading(seqNumber: Int, timestamp: Int64,
                               adcSamples: [Int], temperature: Double) -> CalibrationResult {
        precondition(adcSamples.count == 30,
                     "adcSamples must have exactly 30 elements, got \(adcSamples.count)")

        // Build internal input
        let input = CgmInput()
        input.seqNumber = seqNumber
        input.measurementTimeStandard = timestamp
        input.temperature = temperature
        for i in 0..<30 {
            input.workout[i] = adcSamples[i]
        }

        // Run the pipeline
        let output = AlgorithmOutput()
        let debug = DebugOutput()
        CalibrationAlgorithm.process(
            deviceInfo: deviceInfo,
            cgmInput: input,
            calInput: calList,
            algoArgs: state,
            algoOutput: output,
            algoDebug: debug
        )

        readingsProcessed += 1

        // Build immutable result
        return CalibrationResult(
            glucoseMgdl: output.resultGlucose,
            trendRate: output.trendrate,
            errorCode: output.errcode,
            stage: output.currentStage,
            calAvailableFlag: output.calAvailableFlag,
            smoothedGlucose: output.smoothResultGlucose,
            smoothedSeq: output.smoothSeq,
            smoothedFixedFlag: output.smoothFixedFlag
        )
    }

    /// Whether the sensor has completed its warmup period.
    ///
    /// During warmup, glucose values may be less accurate. The warmup
    /// period is defined by the sensor's factory calibration parameters
    /// (typically 5-10 readings).
    public var isWarmedUp: Bool {
        readingsProcessed > 0 && state.idxOriginSeq > deviceInfo.err345Seq2
    }

    // ======================================================================
    // State serialization
    // ======================================================================

    /// Error type for calibrator state serialization/deserialization failures.
    public enum StateError: Error, Equatable {
        /// The state data is empty.
        case emptyData
        /// The state data is corrupted or not a valid serialized state.
        case corruptedData
        /// The serialized state version does not match the expected version.
        case incompatibleVersion(expected: Int, found: Int)
    }

    /// Serialize the current calibrator state for persistence.
    ///
    /// The returned `Data` uses a simple binary format:
    /// - 4 bytes: magic number (0x4F435341 = "OCSA")
    /// - 4 bytes: version (Int32, big-endian)
    /// - 4 bytes: readingsProcessed (Int32, big-endian)
    /// - Remaining: JSON-encoded `AlgorithmState`
    ///
    /// The returned data can be stored in UserDefaults, a database,
    /// or any other storage mechanism. Use ``restoreState(_:config:)`` to
    /// reconstruct the calibrator later.
    ///
    /// - Returns: serialized state data
    public func saveState() -> Data {
        var data = Data()
        // Magic number: "OCSA" in big-endian
        let magic: UInt32 = 0x4F435341
        data.append(contentsOf: withUnsafeBytes(of: magic.bigEndian) { Array($0) })
        // Version
        let version = Int32(CareSensCalibrator.stateVersion)
        data.append(contentsOf: withUnsafeBytes(of: version.bigEndian) { Array($0) })
        // Readings processed
        let readings = Int32(readingsProcessed)
        data.append(contentsOf: withUnsafeBytes(of: readings.bigEndian) { Array($0) })
        // JSON-encoded AlgorithmState
        let encoder = JSONEncoder()
        if let stateData = try? encoder.encode(state) {
            data.append(stateData)
        }
        return data
    }

    /// Restore a calibrator from previously saved state.
    ///
    /// The `config` must match the sensor that produced the saved state.
    /// Using a different sensor's config with saved state from another sensor
    /// will produce incorrect glucose values.
    ///
    /// - Parameters:
    ///   - stateData: serialized state from ``saveState()``
    ///   - config: sensor factory calibration parameters
    /// - Returns: restored calibrator
    /// - Throws: `StateError` if the data is empty, corrupted, or has an
    ///   incompatible version.
    public static func restoreState(_ stateData: Data, config: SensorConfig) throws -> CareSensCalibrator {
        guard !stateData.isEmpty else {
            throw StateError.emptyData
        }

        // Minimum: 4 (magic) + 4 (version) + 4 (readings) = 12 bytes
        guard stateData.count >= 12 else {
            throw StateError.corruptedData
        }

        // Read and validate magic number
        let magic = stateData.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }
        guard magic.bigEndian == 0x4F435341 else {
            throw StateError.corruptedData
        }

        // Read version
        let version = Int(stateData.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: 4, as: Int32.self) }.bigEndian)
        guard version == stateVersion else {
            throw StateError.incompatibleVersion(expected: stateVersion, found: version)
        }

        // Read readingsProcessed
        let readingsProcessed = Int(stateData.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: 8, as: Int32.self) }.bigEndian)

        // Decode AlgorithmState from the JSON payload after the 12-byte header
        let jsonData = stateData.subdata(in: 12..<stateData.count)
        let decoder = JSONDecoder()
        let restoredState: AlgorithmState
        do {
            restoredState = try decoder.decode(AlgorithmState.self, from: jsonData)
        } catch {
            throw StateError.corruptedData
        }

        let calibrator = CareSensCalibrator(config)
        calibrator.state = restoredState
        calibrator.readingsProcessed = readingsProcessed
        return calibrator
    }
}
