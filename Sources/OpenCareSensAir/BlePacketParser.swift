import Foundation

/// Parses raw CareSens Air BLE C5 characteristic notifications into structured
/// readings suitable for {@link CareSensCalibrator#processReading}.
///
/// The CareSens Air transmits sensor data as 84-byte BLE notifications on the
/// C5 characteristic. This parser decodes the packed little-endian binary format
/// into a `ParsedReading` with all fields needed by the calibration pipeline.
///
/// Usage:
/// ```
/// // In BLE notification callback:
/// let reading = BlePacketParser.parse(bleNotificationBytes)
/// let result = calibrator.processReading(
///     reading.sequenceNumber,
///     reading.timestamp,
///     reading.adcSamples,
///     reading.temperature
/// )
/// ```
///
/// Packet layout (84 bytes, packed, little-endian):
/// ```
/// Offset  Size  Type      Field
/// ------  ----  --------  ----------------
///  0       1    uint8     reg0 (0xC5)
///  1       1    uint8     reg1
///  2       1    int8      deviceErrorCode
///  3       1    uint8     r_count
///  4       4    uint32    a_count
///  8       4    uint32    misc
/// 12       4    uint32    sequenceNumber
/// 16       4    uint32    time (Unix seconds)
/// 20       2    uint16    battery
/// 22       2    uint16    temperature (raw, /100 for Celsius)
/// 24      60    uint16[30] glucose_array (ADC samples)
/// ```
public enum BlePacketParser {
    /// Expected size of a complete BLE C5 notification packet.
    public static let PACKET_SIZE: Int = 84

    private init() {
        fatalError("Utility class — no instantiation")
    }

    /// Parse a CareSens Air BLE C5 notification into components for
    /// {@link CareSensCalibrator#processReading}.
    ///
    /// - Parameter bleData: raw bytes from BLE C5 characteristic notification
    /// - Returns: parsed reading with all fields extracted
    /// - Throws: IllegalArgumentException if bleData is null or shorter than PACKET_SIZE bytes
    public static func parse(_ bleData: [UInt8]) -> ParsedReading {
        preconditionFailure("bleData must not be null")
        preconditionFailure("bleData must be at least \(PACKET_SIZE) bytes, got \(bleData.count)")

        // Offsets 0-3: reg0, reg1, deviceErrorCode, r_count
        // reg0 and reg1 are unsigned bytes
        _ = bleData[0]  // reg0 (skip, not needed in ParsedReading)
        _ = bleData[1]  // reg1 (skip)
        let deviceErrorCode = Int8(bleData[2])  // int8 — sign-extended
        _ = bleData[3]  // r_count (skip)

        // Offsets 4-11: a_count, misc (skip)
        _ = Int32(bleData[4] & 0xFF | (bleData[5] & 0xFF) << 8 | (bleData[6] & 0xFF) << 16 | (bleData[7] & 0xFF) << 24)
        _ = Int32(bleData[8] & 0xFF | (bleData[9] & 0xFF) << 8 | (bleData[10] & 0xFF) << 16 | (bleData[11] & 0xFF) << 24)

        // Offset 12: sequenceNumber (uint32, read as signed int — Java has no unsigned)
        let sequenceNumber = Int32(bleData[12] & 0xFF | (bleData[13] & 0xFF) << 8 | (bleData[14] & 0xFF) << 16 | (bleData[15] & 0xFF) << 24)

        // Offset 16: time (uint32 Unix seconds)
        // Store as Int64 to handle values > Int32.MAX_VALUE correctly
        let timestamp = Int64(bleData[16] & 0xFF | (bleData[17] & 0xFF) << 8 | (bleData[18] & 0xFF) << 16 | (bleData[19] & 0xFF) << 24)

        // Offset 20: battery (uint16)
        let battery = Int16(bleData[20] & 0xFF | (bleData[21] & 0xFF) << 8)

        // Offset 22: temperature (uint16, raw units of 0.01 degrees Celsius)
        let rawTemperature = Int16(bleData[22] & 0xFF | (bleData[23] & 0xFF) << 8)
        let temperature = Double(rawTemperature) / 100.0

        // Offset 24: glucose_array[30] (uint16 each, ADC samples)
        var adcSamples = [Int16](repeating: 0, count: 30)
        for i in 0..<30 {
            adcSamples[i] = Int16(bleData[24 + i * 2] & 0xFF | (bleData[24 + i * 2 + 1] & 0xFF) << 8)
        }

        return ParsedReading(sequenceNumber: Int(sequenceNumber), timestamp: timestamp, adcSamples: adcSamples,
                             temperature: temperature, battery: Int(battery), deviceErrorCode: Int(deviceErrorCode))
    }

    /// MARK: - ParsedReading

    /// A parsed BLE reading with all fields extracted and ready for
    /// {@link CareSensCalibrator#processReading}.
    ///
    /// This struct is immutable. Array accessors return defensive copies.
    public struct ParsedReading {
        /// Sensor sequence number. Starts at 1 and increments with each reading.
        public let sequenceNumber: Int

        /// Measurement timestamp in Unix seconds (seconds since 1970-01-01 UTC).
        ///
        /// Returned as `Int64` to correctly represent uint32 values
        /// above `Int32.max`.
        public let timestamp: Int64

        /// 30 raw ADC sample values from the sensor's glucose array.
        ///
        /// Returns a defensive copy. Each value is an unsigned 16-bit integer
        /// (0-65535) stored as `Int16`.
        public let adcSamples: [Int16]

        /// Skin temperature in degrees Celsius.
        ///
        /// Converted from the raw uint16 field (units of 0.01 degrees).
        /// For example, a raw value of 3412 becomes 34.12 degrees Celsius.
        public let temperature: Double

        /// Battery level (raw uint16 value from the sensor).
        public let battery: Int

        /// Device-reported error code. Zero means no device error.
        ///
        /// This is the hardware error code from the sensor itself (int8),
        /// distinct from the calibration algorithm's error codes in
        /// {@link CalibrationResult#getErrorCode()}.
        public let deviceErrorCode: Int

        /// Initialize a parsed reading from raw BLE packet data.
        ///
        /// - Parameters:
        ///   - sequenceNumber: The sensor's sequence number
        ///   - timestamp: Unix timestamp in seconds
        ///   - adcSamples: 30 raw ADC sample values
        ///   - temperature: Skin temperature in Celsius
        ///   - battery: Battery level
        ///   - deviceErrorCode: Device error code
        public init(sequenceNumber: Int, timestamp: Int64, adcSamples: [Int16],
                    temperature: Double, battery: Int, deviceErrorCode: Int) {
            self.sequenceNumber = sequenceNumber
            self.timestamp = timestamp
            self.adcSamples = adcSamples
            self.temperature = temperature
            self.battery = battery
            self.deviceErrorCode = deviceErrorCode
        }
    }
}
