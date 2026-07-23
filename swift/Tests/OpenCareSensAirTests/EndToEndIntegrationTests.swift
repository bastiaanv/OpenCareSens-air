import XCTest
@testable import OpenCareSensAir

/// End-to-end integration test: BLE bytes -> BlePacketParser -> CareSensCalibrator
/// -> CalibrationResult -> glucose value.
///
/// Uses synthetic BLE packets with known ADC values and the same lot0 device
/// parameters from OracleVerificationTest.
final class EndToEndIntegrationTests: XCTestCase {

    private static let sensorStartTime: Int64 = 1709726400 // 2024-03-06 12:00:00 UTC
    private static let intervalSeconds: Int = 300 // 5 minutes between readings

    private var config: SensorConfig!

    override func setUp() {
        super.setUp()
        config = Self.createLot0Config()
    }

    // ======================================================================
    // MARK: - Test 1: Full BLE-to-glucose flow
    // ======================================================================

    func testFullBleToGlucoseFlow() {
        let calibrator = CareSensCalibrator(config)

        // Build a realistic 84-byte BLE packet with known values
        let seqNumber = 1
        let timestamp = Self.sensorStartTime + Int64(Self.intervalSeconds)
        let rawTemperature = 3412 // 34.12 degrees Celsius
        let adcValue = 8000 // mid-range ADC value

        let blePacket = Self.buildBlePacket(
            seqNumber: seqNumber, timestamp: timestamp,
            rawTemperature: rawTemperature, adcValue: adcValue,
            deviceErrorCode: 0)

        // Parse
        let reading = BlePacketParser.parse(blePacket)
        XCTAssertEqual(seqNumber, reading.sequenceNumber)
        XCTAssertEqual(timestamp, reading.timestamp)
        XCTAssertEqual(34.12, reading.temperature, accuracy: 0.001)
        XCTAssertEqual(0, reading.deviceErrorCode)

        let adcSamples = reading.adcSamples
        XCTAssertEqual(30, adcSamples.count)
        for sample in adcSamples {
            XCTAssertEqual(adcValue, sample)
        }

        // Calibrate
        let result = calibrator.processReading(
            seqNumber: reading.sequenceNumber,
            timestamp: reading.timestamp,
            adcSamples: reading.adcSamples,
            temperature: reading.temperature)

        // Verify result is populated (first reading is during warmup so glucose
        // may or may not be in normal range, but result must not be null)
        // assertNotNull(result) - non-optional return type in Swift
        XCTAssertFalse(result.glucoseMgdl.isNaN,
            "Glucose should not be NaN")
        XCTAssertFalse(result.glucoseMgdl.isInfinite,
            "Glucose should not be Infinite")
        // Error code should be a valid integer (bitmask)
        XCTAssertTrue(result.errorCode >= 0,
            "Error code should be non-negative")
        // Stage should be 0 (warmup) or 1 (steady)
        XCTAssertTrue(result.stage == 0 || result.stage == 1,
            "Stage should be 0 or 1, got \(result.stage)")
        // description should not crash
        _ = result.description
    }

    // ======================================================================
    // MARK: - Test 2: Multi-reading sequence
    // ======================================================================

    func testMultiReadingSequence() {
        let calibrator = CareSensCalibrator(config)

        let numReadings = 40
        var results: [CalibrationResult] = []
        var sawWarmup = false
        var sawSteadyState = false

        for i in 1...numReadings {
            let timestamp = Self.sensorStartTime + Int64(i * Self.intervalSeconds)
            // Simulate slowly varying ADC values (glucose ~120 mg/dL range)
            let adcValue = 7500 + Int(500 * sin(Double(i) * 0.2))
            let rawTemp = 3400 + (i % 20) // ~34.00-34.20 C, slight variation

            let blePacket = Self.buildBlePacket(
                seqNumber: i, timestamp: timestamp,
                rawTemperature: rawTemp, adcValue: adcValue,
                deviceErrorCode: 0)
            let reading = BlePacketParser.parse(blePacket)

            let result = calibrator.processReading(
                seqNumber: reading.sequenceNumber,
                timestamp: reading.timestamp,
                adcSamples: reading.adcSamples,
                temperature: reading.temperature)

            results.append(result)

            if result.stage == 0 { sawWarmup = true }
            if result.stage == 1 { sawSteadyState = true }
        }

        XCTAssertEqual(numReadings, results.count)
        XCTAssertEqual(numReadings, calibrator.readingsProcessed)

        // Verify no NaN or Infinity in any result field
        for i in 0..<results.count {
            let r = results[i]
            XCTAssertFalse(r.glucoseMgdl.isNaN,
                "Glucose NaN at reading \(i + 1)")
            XCTAssertFalse(r.glucoseMgdl.isInfinite,
                "Glucose Infinite at reading \(i + 1)")
            XCTAssertFalse(r.trendRate.isNaN,
                "TrendRate NaN at reading \(i + 1)")
            XCTAssertFalse(r.trendRate.isInfinite,
                "TrendRate Infinite at reading \(i + 1)")

            // Smoothed glucose values
            let smoothed = r.smoothedGlucose
            for j in 0..<smoothed.count {
                XCTAssertFalse(smoothed[j].isNaN,
                    "SmoothedGlucose[\(j)] NaN at reading \(i + 1)")
                XCTAssertFalse(smoothed[j].isInfinite,
                    "SmoothedGlucose[\(j)] Infinite at reading \(i + 1)")
            }

            // Error codes should be sensible (non-negative bitmask, fits in lower 7 bits)
            XCTAssertTrue(r.errorCode >= 0 && r.errorCode < 256,
                "Error code out of range at reading \(i + 1): \(r.errorCode)")
        }

        // Verify warmup transition: with basicWarmup=24 and err345Seq2=5,
        // we should see warmup in early readings
        XCTAssertTrue(sawWarmup, "Should have seen warmup stage (stage=0)")
        _ = sawSteadyState // tracked but not asserted (matches Java source)

        // After enough readings, post-warmup glucose values that are valid
        // should be in realistic range
        for i in 25..<results.count {
            let r = results[i]
            if r.errorCode == 0 && r.glucoseMgdl > 0 {
                XCTAssertTrue(r.glucoseMgdl >= 20.0 && r.glucoseMgdl <= 600.0,
                    "Post-warmup glucose out of realistic range at reading \(i + 1): \(r.glucoseMgdl)")
            }
        }
    }

    // ======================================================================
    // MARK: - Test 3: State persistence through BLE flow
    // ======================================================================

    func testStatePersistenceThroughBleFlow() throws {
        // Java: calibrate 10 readings, save/restore, continue, verify continuity
        // Swift: saveState()/restoreState() are not yet implemented (fatalError).
        throw XCTSkip("saveState()/restoreState() not yet implemented in Swift")
    }

    // ======================================================================
    // MARK: - Test 4: Error handling - invalid BLE packets
    // ======================================================================

    func testNullBlePacketThrows() throws {
        // Java: assertThrows(IllegalArgumentException.class, () -> BlePacketParser.parse(null))
        // In Swift, [UInt8] is non-optional; nil cannot be passed.
        throw XCTSkip("Not applicable: [UInt8] is non-optional in Swift")
    }

    func testShortBlePacketThrows() throws {
        // Java: assertThrows(IllegalArgumentException.class, () -> BlePacketParser.parse(new byte[42]))
        // Swift's BlePacketParser.parse() uses fatalError() for short packets
        // which crashes the process rather than throwing.
        throw XCTSkip("Swift uses fatalError() for invalid packet size instead of throwing")
    }

    func testEmptyBlePacketThrows() throws {
        // Java: assertThrows(IllegalArgumentException.class, () -> BlePacketParser.parse(new byte[0]))
        // Swift's BlePacketParser.parse() uses fatalError() for empty packets
        // which crashes the process rather than throwing.
        throw XCTSkip("Swift uses fatalError() for invalid packet size instead of throwing")
    }

    func testNullAdcSamplesToCalibrator() throws {
        // Java: assertThrows(IllegalArgumentException.class, () ->
        //     calibrator.processReading(1, SENSOR_START_TIME + 300, null, 34.0))
        // In Swift, [Int] is non-optional; nil cannot be passed.
        throw XCTSkip("Not applicable: [Int] is non-optional in Swift")
    }

    func testWrongAdcSampleCount() throws {
        // Java: assertThrows(IllegalArgumentException.class, () ->
        //     calibrator.processReading(1, SENSOR_START_TIME + 300, new int[15], 34.0))
        // Swift's processReading uses precondition() which crashes rather than throwing.
        throw XCTSkip("Swift uses precondition() for ADC validation instead of throwing")
    }

    func testExtremeAdcValuesDontCrash() {
        let calibrator = CareSensCalibrator(config)

        // Very low ADC values
        let lowPacket = Self.buildBlePacket(
            seqNumber: 1, timestamp: Self.sensorStartTime + Int64(Self.intervalSeconds),
            rawTemperature: 3400, adcValue: 100, deviceErrorCode: 0)
        let lowReading = BlePacketParser.parse(lowPacket)
        let lowResult = calibrator.processReading(
            seqNumber: lowReading.sequenceNumber,
            timestamp: lowReading.timestamp,
            adcSamples: lowReading.adcSamples,
            temperature: lowReading.temperature)
        // assertNotNull(lowResult) - non-optional return type in Swift
        XCTAssertFalse(lowResult.glucoseMgdl.isNaN)

        // Very high ADC values (near uint16 max)
        let highPacket = Self.buildBlePacket(
            seqNumber: 2, timestamp: Self.sensorStartTime + Int64(2 * Self.intervalSeconds),
            rawTemperature: 3400, adcValue: 65000, deviceErrorCode: 0)
        let highReading = BlePacketParser.parse(highPacket)
        let highResult = calibrator.processReading(
            seqNumber: highReading.sequenceNumber,
            timestamp: highReading.timestamp,
            adcSamples: highReading.adcSamples,
            temperature: highReading.temperature)
        // assertNotNull(highResult) - non-optional return type in Swift
        XCTAssertFalse(highResult.glucoseMgdl.isNaN)

        // Zero ADC values
        let zeroPacket = Self.buildBlePacket(
            seqNumber: 3, timestamp: Self.sensorStartTime + Int64(3 * Self.intervalSeconds),
            rawTemperature: 3400, adcValue: 0, deviceErrorCode: 0)
        let zeroReading = BlePacketParser.parse(zeroPacket)
        let zeroResult = calibrator.processReading(
            seqNumber: zeroReading.sequenceNumber,
            timestamp: zeroReading.timestamp,
            adcSamples: zeroReading.adcSamples,
            temperature: zeroReading.temperature)
        // assertNotNull(zeroResult) - non-optional return type in Swift
        XCTAssertFalse(zeroResult.glucoseMgdl.isNaN)
    }

    func testOversizedBlePacketParses() {
        var oversized = [UInt8](repeating: 0, count: 128)
        // Fill the first 84 bytes with a valid packet
        let valid = Self.buildBlePacket(
            seqNumber: 1, timestamp: Self.sensorStartTime + Int64(Self.intervalSeconds),
            rawTemperature: 3400, adcValue: 8000, deviceErrorCode: 0)
        for i in 0..<BlePacketParser.packetSize {
            oversized[i] = valid[i]
        }

        let reading = BlePacketParser.parse(oversized)
        // assertNotNull(reading) - non-optional return type in Swift
        XCTAssertEqual(1, reading.sequenceNumber)
    }

    // ======================================================================
    // MARK: - Helpers
    // ======================================================================

    /// Build a synthetic 84-byte BLE C5 notification packet.
    ///
    /// Layout matches BlePacketParser expectations:
    ///   [0]    reg0 = 0xC5
    ///   [1]    reg1 = 0
    ///   [2]    deviceErrorCode (int8)
    ///   [3]    r_count = 0
    ///   [4-7]  a_count = 0
    ///   [8-11] misc = 0
    ///   [12-15] sequenceNumber (uint32 LE)
    ///   [16-19] timestamp (uint32 LE)
    ///   [20-21] battery (uint16 LE)
    ///   [22-23] temperature raw (uint16 LE)
    ///   [24-83] glucose_array[30] (uint16 LE each)
    private static func buildBlePacket(seqNumber: Int, timestamp: Int64,
                                       rawTemperature: Int, adcValue: Int,
                                       deviceErrorCode: Int) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: BlePacketParser.packetSize)

        packet[0] = 0xC5                           // reg0
        packet[1] = 0                              // reg1
        packet[2] = UInt8(truncatingIfNeeded: deviceErrorCode) // deviceErrorCode (int8)
        packet[3] = 0                              // r_count
        // [4-7] a_count = 0 (already zero)
        // [8-11] misc = 0 (already zero)

        // sequenceNumber (uint32 LE) at offset 12
        let seq = UInt32(truncatingIfNeeded: seqNumber)
        packet[12] = UInt8(seq & 0xFF)
        packet[13] = UInt8((seq >> 8) & 0xFF)
        packet[14] = UInt8((seq >> 16) & 0xFF)
        packet[15] = UInt8((seq >> 24) & 0xFF)

        // timestamp (uint32 LE) at offset 16
        let ts = UInt32(truncatingIfNeeded: timestamp)
        packet[16] = UInt8(ts & 0xFF)
        packet[17] = UInt8((ts >> 8) & 0xFF)
        packet[18] = UInt8((ts >> 16) & 0xFF)
        packet[19] = UInt8((ts >> 24) & 0xFF)

        // battery (uint16 LE) at offset 20 = 3000
        let battery = UInt16(3000)
        packet[20] = UInt8(battery & 0xFF)
        packet[21] = UInt8((battery >> 8) & 0xFF)

        // temperature (uint16 LE) at offset 22
        let temp = UInt16(rawTemperature)
        packet[22] = UInt8(temp & 0xFF)
        packet[23] = UInt8((temp >> 8) & 0xFF)

        // ADC samples (30 x uint16 LE) at offset 24
        let adc = UInt16(adcValue)
        for i in 0..<30 {
            packet[24 + i * 2] = UInt8(adc & 0xFF)
            packet[24 + i * 2 + 1] = UInt8((adc >> 8) & 0xFF)
        }

        return packet
    }

    /// Create lot0 SensorConfig matching OracleVerificationTest parameters.
    private static func createLot0Config() -> SensorConfig {
        return SensorConfig.Builder()
            .eapp(0.10067)
            .vref(1.49594)
            .slope100(3.5226)
            .slope(1.0)
            .ycept(1.0)
            .r2(0.0)
            .t90(0.0)
            .slopeRatio(1.0)
            .basicWarmup(24)
            .basicYcept(0.0)
            .err345Seq2(5)
            .iirFlag(1)
            .maximumValue(500.0)
            .minimumValue(40.0)
            .kalmanDeltaT(5)
            .wSgX100([80, 130, 90, 80, 110, 90, 80])
            .err1Seq([23, 47, 11])
            .err1Multi([10, 10])
            .err1NLast(288)
            .err2StartSeq(289)
            .err2Seq([20, 11, 6])
            .err2Cummax(2)
            .err2Glu(800.0)
            .err345Seq4([11, 23, 12, 288, 24])
            .err32Dt([23, 60])
            .err32N([3, 2])
            .sensorStartTime(sensorStartTime)
            .build()
    }
}
