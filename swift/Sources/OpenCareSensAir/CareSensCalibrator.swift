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
    private static let stateVersion = 1

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

    /// Serialize the current calibrator state for persistence.
    ///
    /// The returned byte array can be stored in UserDefaults, a database,
    /// or any other storage mechanism. Use ``restoreState(_:config:)`` to
    /// reconstruct the calibrator later.
    ///
    /// - Returns: serialized state bytes
    /// - Warning: Not yet implemented. AlgorithmState contains a very large
    ///   number of fields; proper binary serialization will be added in a
    ///   future revision. Calling this method will terminate with
    ///   `fatalError`.
    public func saveState() -> Data {
        // TODO: Implement binary serialization of AlgorithmState.
        // AlgorithmState is a reference type with ~200 fields including many
        // large arrays. Implementing Codable or a manual binary serializer
        // requires enumerating every field. This will be addressed in a
        // follow-up commit.
        fatalError("CareSensCalibrator.saveState() is not yet implemented")
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
    /// - Warning: Not yet implemented. See ``saveState()`` for details.
    ///   Calling this method will terminate with `fatalError`.
    public static func restoreState(_ stateData: Data, config: SensorConfig) -> CareSensCalibrator {
        // TODO: Implement binary deserialization of AlgorithmState.
        // See saveState() for context.
        fatalError("CareSensCalibrator.restoreState() is not yet implemented")
    }
}
