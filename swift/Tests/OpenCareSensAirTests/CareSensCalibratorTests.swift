import XCTest
@testable import OpenCareSensAir

/// Tests for the CareSensCalibrator public API facade.
///
/// These tests verify that the facade correctly wraps the internal calibration
/// pipeline and provides a clean, safe interface for host apps.
final class CareSensCalibratorTests: XCTestCase {

    private static let eps = 1e-10

    // ======================================================================
    // Helper: create a typical sensor config (lot type 1)
    // ======================================================================

    private static func createTypicalConfig() -> SensorConfig {
        return SensorConfig.Builder()
            .eapp(0.10067)
            .vref(1.2)
            .slope100(2.5)
            .slope(0.025)
            .slopeRatio(1.0)
            .t90(10.0)
            .basicWarmup(5)
            .err345Seq2(5)
            .iirFlag(1)
            .sensorStartTime(100)
            .maximumValue(500.0)
            .wSgX100([-3, 12, 17, 12, 17, 12, -3])
            .err1Seq([23, 50, 100])
            .err1NLast(288)
            .err1Multi([10, 10])
            .err2Seq([100, 48, 24])
            .err2StartSeq(289)
            .err2Cummax(1)
            .err2Glu(100.0)
            .err345Seq4([0, 0, 12, 0, 0])
            .err32Dt([10, 15])
            .err32N([3, 5])
            .kalmanDeltaT(5)
            .build()
    }

    private static func createAdcSamples(_ value: Int) -> [Int] {
        return [Int](repeating: value, count: 30)
    }

    // ======================================================================
    // setUp (used by processReading tests)
    // ======================================================================

    private var calibrator: CareSensCalibrator!

    override func setUp() {
        super.setUp()
        calibrator = CareSensCalibrator(Self.createTypicalConfig())
    }

    // ======================================================================
    // MARK: - SensorConfig tests
    // ======================================================================

    func testBuilderValues() {
        let config = SensorConfig.Builder()
            .eapp(0.10067)
            .vref(1.2)
            .slope100(2.5)
            .lot("LOT123")
            .sensorId("SENS456")
            .sensorStartTime(12345)
            .basicWarmup(5)
            .err345Seq2(5)
            .build()

        XCTAssertEqual(config.eapp, 0.10067)
        XCTAssertEqual(config.vref, 1.2)
        XCTAssertEqual(config.slope100, 2.5)
        XCTAssertEqual(config.lot, "LOT123")
        XCTAssertEqual(config.sensorId, "SENS456")
        XCTAssertEqual(config.sensorStartTime, Int64(12345))
        XCTAssertEqual(config.basicWarmup, 5)
        XCTAssertEqual(config.err345Seq2, 5)
    }

    func testBuilderValidation() throws {
        // Java: assertThrows(IllegalStateException.class, () -> new SensorConfig.Builder().build())
        // Swift equivalent would be: XCTAssertThrowsError(try SensorConfig.Builder().build())
        // but build() uses precondition() which crashes rather than throwing.
        throw XCTSkip("Swift uses precondition() instead of throwing errors")
    }

    func testBuilderValidationVrefZero() throws {
        // Java: assertThrows(IllegalStateException.class, () -> new SensorConfig.Builder().slope100(2.5f).build())
        // Swift's build() uses precondition() which crashes rather than throwing.
        throw XCTSkip("Swift uses precondition() instead of throwing errors")
    }

    func testBuilderValidationSlope100Zero() throws {
        // Java: assertThrows(IllegalStateException.class, () -> new SensorConfig.Builder().vref(1.2f).build())
        // Swift's build() uses precondition() which crashes rather than throwing.
        throw XCTSkip("Swift uses precondition() instead of throwing errors")
    }

    func testBuilderMinimal() {
        let config = SensorConfig.Builder()
            .vref(1.2)
            .slope100(2.5)
            .build()
        XCTAssertEqual(config.vref, 1.2)
        XCTAssertEqual(config.slope100, 2.5)
    }

    func testBuilderImmutability() {
        let builder = SensorConfig.Builder()
            .eapp(0.10067)
            .vref(1.2)
            .slope100(2.5)
            .basicWarmup(5)
            .err345Seq2(5)

        let config = builder.build()

        // Mutate the builder after build
        builder.vref(9.9)
        builder.slope100(9.9)

        // Config must retain original values
        XCTAssertEqual(config.vref, 1.2)
        XCTAssertEqual(config.slope100, 2.5)
    }

    // ======================================================================
    // MARK: - CalibrationResult tests
    // ======================================================================

    func testValidResult() {
        let r = CalibrationResult(
            glucoseMgdl: 120.0, trendRate: 1.5, errorCode: 0, stage: 1, calAvailableFlag: 1,
            smoothedGlucose: [Double](repeating: 0.0, count: 6),
            smoothedSeq: [Int](repeating: 0, count: 6),
            smoothedFixedFlag: [Int](repeating: 0, count: 6))
        XCTAssertTrue(r.isValid)
        XCTAssertFalse(r.hasError)
        XCTAssertEqual(r.glucoseMgdl, 120.0)
        XCTAssertEqual(r.trendRate, 1.5)
        XCTAssertEqual(r.stage, 1)
    }

    func testErrorResult() {
        let r = CalibrationResult(
            glucoseMgdl: 120.0, trendRate: 1.5, errorCode: 1, stage: 1, calAvailableFlag: 0,
            smoothedGlucose: [Double](repeating: 0.0, count: 6),
            smoothedSeq: [Int](repeating: 0, count: 6),
            smoothedFixedFlag: [Int](repeating: 0, count: 6))
        XCTAssertFalse(r.isValid)
        XCTAssertTrue(r.hasError)
        XCTAssertEqual(r.errorCode, 1)
    }

    func testLowGlucose() {
        let r = CalibrationResult(
            glucoseMgdl: 30.0, trendRate: 0.0, errorCode: 0, stage: 1, calAvailableFlag: 0,
            smoothedGlucose: [Double](repeating: 0.0, count: 6),
            smoothedSeq: [Int](repeating: 0, count: 6),
            smoothedFixedFlag: [Int](repeating: 0, count: 6))
        XCTAssertFalse(r.isValid)
    }

    func testHighGlucose() {
        let r = CalibrationResult(
            glucoseMgdl: 550.0, trendRate: 0.0, errorCode: 0, stage: 1, calAvailableFlag: 0,
            smoothedGlucose: [Double](repeating: 0.0, count: 6),
            smoothedSeq: [Int](repeating: 0, count: 6),
            smoothedFixedFlag: [Int](repeating: 0, count: 6))
        XCTAssertFalse(r.isValid)
    }

    func testMmolConversion() {
        let r = CalibrationResult(
            glucoseMgdl: 180.0, trendRate: 0.0, errorCode: 0, stage: 1, calAvailableFlag: 0,
            smoothedGlucose: [Double](repeating: 0.0, count: 6),
            smoothedSeq: [Int](repeating: 0, count: 6),
            smoothedFixedFlag: [Int](repeating: 0, count: 6))
        XCTAssertEqual(180.0 / 18.0182, r.glucoseMmol, accuracy: 1e-6)
    }

    func testTrendAvailable() {
        let available = CalibrationResult(
            glucoseMgdl: 120.0, trendRate: 1.5, errorCode: 0, stage: 1, calAvailableFlag: 0,
            smoothedGlucose: [Double](repeating: 0.0, count: 6),
            smoothedSeq: [Int](repeating: 0, count: 6),
            smoothedFixedFlag: [Int](repeating: 0, count: 6))
        XCTAssertTrue(available.isTrendAvailable)

        let notAvailable = CalibrationResult(
            glucoseMgdl: 120.0, trendRate: 100.0, errorCode: 0, stage: 1, calAvailableFlag: 0,
            smoothedGlucose: [Double](repeating: 0.0, count: 6),
            smoothedSeq: [Int](repeating: 0, count: 6),
            smoothedFixedFlag: [Int](repeating: 0, count: 6))
        XCTAssertFalse(notAvailable.isTrendAvailable)
    }

    func testTrendNanNotAvailable() {
        let r = CalibrationResult(
            glucoseMgdl: 120.0, trendRate: .nan, errorCode: 0, stage: 1, calAvailableFlag: 0,
            smoothedGlucose: [Double](repeating: 0.0, count: 6),
            smoothedSeq: [Int](repeating: 0, count: 6),
            smoothedFixedFlag: [Int](repeating: 0, count: 6))
        XCTAssertFalse(r.isTrendAvailable)
    }

    func testTrendInfinityNotAvailable() {
        let r = CalibrationResult(
            glucoseMgdl: 120.0, trendRate: .infinity, errorCode: 0, stage: 1, calAvailableFlag: 0,
            smoothedGlucose: [Double](repeating: 0.0, count: 6),
            smoothedSeq: [Int](repeating: 0, count: 6),
            smoothedFixedFlag: [Int](repeating: 0, count: 6))
        XCTAssertFalse(r.isTrendAvailable)
    }

    func testTrendNegInfinityNotAvailable() {
        let r = CalibrationResult(
            glucoseMgdl: 120.0, trendRate: -.infinity, errorCode: 0, stage: 1, calAvailableFlag: 0,
            smoothedGlucose: [Double](repeating: 0.0, count: 6),
            smoothedSeq: [Int](repeating: 0, count: 6),
            smoothedFixedFlag: [Int](repeating: 0, count: 6))
        XCTAssertFalse(r.isTrendAvailable)
    }

    func testDefensiveCopies() {
        let sg: [Double] = [100.0, 101.0, 102.0, 103.0, 104.0, 105.0]
        let r = CalibrationResult(
            glucoseMgdl: 120.0, trendRate: 0.0, errorCode: 0, stage: 1, calAvailableFlag: 0,
            smoothedGlucose: sg,
            smoothedSeq: [Int](repeating: 0, count: 6),
            smoothedFixedFlag: [Int](repeating: 0, count: 6))
        var copy1 = r.smoothedGlucose
        copy1[0] = 999.0
        XCTAssertEqual(r.smoothedGlucose[0], 100.0)
    }

    func testToStringFormat() {
        let r = CalibrationResult(
            glucoseMgdl: 120.5, trendRate: 1.5, errorCode: 0, stage: 1, calAvailableFlag: 0,
            smoothedGlucose: [Double](repeating: 0.0, count: 6),
            smoothedSeq: [Int](repeating: 0, count: 6),
            smoothedFixedFlag: [Int](repeating: 0, count: 6))
        let s = r.description
        XCTAssertTrue(s.contains("120.5"))
        XCTAssertTrue(s.contains("stage=1"))
    }

    // ======================================================================
    // MARK: - CareSensCalibrator construction
    // ======================================================================

    func testNullConfig() throws {
        // Java: assertThrows(NullPointerException.class, () -> new CareSensCalibrator(null))
        // In Swift, SensorConfig is a non-optional struct, so passing nil is not possible.
        throw XCTSkip("Not applicable: SensorConfig is non-optional in Swift")
    }

    func testInitialState() {
        let cal = CareSensCalibrator(Self.createTypicalConfig())
        XCTAssertEqual(0, cal.readingsProcessed)
        XCTAssertFalse(cal.isWarmedUp)
    }

    // ======================================================================
    // MARK: - processReading
    // ======================================================================

    func testNullAdc() throws {
        // Java: assertThrows(IllegalArgumentException.class, () ->
        //     calibrator.processReading(1, 1000L, null, 36.5))
        // In Swift, [Int] is non-optional; nil cannot be passed. The equivalent
        // validation (wrong array length) uses precondition() which crashes
        // rather than throwing.
        throw XCTSkip("Swift uses precondition() for ADC validation instead of throwing")
    }

    func testWrongAdcLength() throws {
        // Java: assertThrows(IllegalArgumentException.class, () ->
        //     calibrator.processReading(1, 1000L, new int[10], 36.5))
        // Swift's processReading uses precondition() which crashes rather than throwing.
        throw XCTSkip("Swift uses precondition() for ADC validation instead of throwing")
    }

    func testFirstReading() {
        let result = calibrator.processReading(
            seqNumber: 1, timestamp: 1000,
            adcSamples: Self.createAdcSamples(2000), temperature: 36.5)

        // assertNotNull(result) - non-optional return type in Swift
        XCTAssertEqual(result.stage, 0) // warmup
        XCTAssertEqual(1, calibrator.readingsProcessed)
        XCTAssertTrue(result.glucoseMgdl.isFinite)
    }

    func testReadingCounter() {
        for i in 1...3 {
            _ = calibrator.processReading(
                seqNumber: i, timestamp: Int64(i * 300),
                adcSamples: Self.createAdcSamples(2000), temperature: 36.5)
        }
        XCTAssertEqual(3, calibrator.readingsProcessed)
    }

    func testWarmupTransition() {
        XCTAssertFalse(calibrator.isWarmedUp)

        // Feed readings through warmup (err345Seq2=5)
        for s in 1...5 {
            _ = calibrator.processReading(
                seqNumber: s, timestamp: Int64(s * 300),
                adcSamples: Self.createAdcSamples(2000), temperature: 36.5)
        }
        XCTAssertFalse(calibrator.isWarmedUp) // seq 5 is still <= err345Seq2

        // Reading 6 should transition to steady state
        let r6 = calibrator.processReading(
            seqNumber: 6, timestamp: 1800,
            adcSamples: Self.createAdcSamples(2000), temperature: 36.5)
        XCTAssertTrue(calibrator.isWarmedUp)
        XCTAssertEqual(1, r6.stage)
    }

    func testTrendDefault() {
        let result = calibrator.processReading(
            seqNumber: 1, timestamp: 1000,
            adcSamples: Self.createAdcSamples(2000), temperature: 36.5)
        XCTAssertEqual(result.trendRate, 100.0)
        XCTAssertFalse(result.isTrendAvailable)
    }

    func testSmoothedLength() {
        let result = calibrator.processReading(
            seqNumber: 1, timestamp: 1000,
            adcSamples: Self.createAdcSamples(2000), temperature: 36.5)
        XCTAssertEqual(result.smoothedGlucose.count, 6)
        XCTAssertEqual(result.smoothedSeq.count, 6)
        XCTAssertEqual(result.smoothedFixedFlag.count, 6)
    }

    func testGlucoseFinite() {
        let result = calibrator.processReading(
            seqNumber: 10, timestamp: 5000,
            adcSamples: Self.createAdcSamples(2000), temperature: 36.5)
        XCTAssertTrue(result.glucoseMgdl.isFinite)
    }

    // ======================================================================
    // MARK: - State persistence
    // ======================================================================

    func testSaveRestoreCount() throws {
        let config = Self.createTypicalConfig()
        let cal = CareSensCalibrator(config)

        for s in 1...3 {
            _ = cal.processReading(
                seqNumber: s, timestamp: Int64(s * 300),
                adcSamples: Self.createAdcSamples(2000), temperature: 36.5)
        }
        XCTAssertEqual(3, cal.readingsProcessed)

        let saved = cal.saveState()
        XCTAssertFalse(saved.isEmpty)

        let restored = try CareSensCalibrator.restoreState(saved, config: config)
        XCTAssertEqual(3, restored.readingsProcessed)
    }

    func testSaveRestoreContinuity() throws {
        let config = Self.createTypicalConfig()
        let cal = CareSensCalibrator(config)

        // Feed 5 readings
        for s in 1...5 {
            _ = cal.processReading(
                seqNumber: s, timestamp: Int64(s * 300),
                adcSamples: Self.createAdcSamples(2000), temperature: 36.5)
        }

        // Save state
        let saved = cal.saveState()

        // Process reading 6 on original
        let r6original = cal.processReading(
            seqNumber: 6, timestamp: 1800,
            adcSamples: Self.createAdcSamples(2000), temperature: 36.5)

        // Process reading 6 on restored
        let restored = try CareSensCalibrator.restoreState(saved, config: config)
        let r6restored = restored.processReading(
            seqNumber: 6, timestamp: 1800,
            adcSamples: Self.createAdcSamples(2000), temperature: 36.5)

        // Results should be identical
        XCTAssertEqual(r6original.glucoseMgdl, r6restored.glucoseMgdl, accuracy: 0.0)
        XCTAssertEqual(r6original.trendRate, r6restored.trendRate, accuracy: 0.0)
        XCTAssertEqual(r6original.errorCode, r6restored.errorCode)
        XCTAssertEqual(r6original.stage, r6restored.stage)
    }

    func testRestoreEmpty() throws {
        XCTAssertThrowsError(try CareSensCalibrator.restoreState(Data(), config: Self.createTypicalConfig())) { error in
            XCTAssertEqual(error as? CareSensCalibrator.StateError, .emptyData)
        }
    }

    func testRestoreGarbage() throws {
        let garbage = Data([1, 2, 3])
        XCTAssertThrowsError(try CareSensCalibrator.restoreState(garbage, config: Self.createTypicalConfig())) { error in
            XCTAssertEqual(error as? CareSensCalibrator.StateError, .corruptedData)
        }
    }

    func testRestoreIncompatibleVersion() throws {
        // Build a binary payload with a wrong version number
        var badData = Data()
        // Magic number
        let magic: UInt32 = 0x4F435341
        badData.append(contentsOf: withUnsafeBytes(of: magic.bigEndian) { Array($0) })
        // Wrong version (999)
        let badVersion: Int32 = 999
        badData.append(contentsOf: withUnsafeBytes(of: badVersion.bigEndian) { Array($0) })
        // readingsProcessed = 0
        let readings: Int32 = 0
        badData.append(contentsOf: withUnsafeBytes(of: readings.bigEndian) { Array($0) })
        // Empty JSON for AlgorithmState
        badData.append(Data("{}\0".utf8))

        XCTAssertThrowsError(try CareSensCalibrator.restoreState(badData, config: Self.createTypicalConfig())) { error in
            guard case .incompatibleVersion(let expected, let found) = error as? CareSensCalibrator.StateError else {
                XCTFail("Expected incompatibleVersion error, got \(error)")
                return
            }
            XCTAssertEqual(expected, CareSensCalibrator.stateVersion)
            XCTAssertEqual(found, 999)
        }
    }

    // ======================================================================
    // MARK: - Oracle verification through facade
    // ======================================================================

    func testLot1Consistency() {
        let cal = CareSensCalibrator(Self.createTypicalConfig())

        var prevGlucose = Double.nan
        for s in 1...10 {
            let r = cal.processReading(
                seqNumber: s, timestamp: Int64(s * 300),
                adcSamples: Self.createAdcSamples(2000), temperature: 36.5)
            XCTAssertTrue(r.glucoseMgdl.isFinite,
                "Glucose should be finite at seq \(s)")

            if s > 1 {
                // Glucose should not wildly jump with constant inputs
                let delta = abs(r.glucoseMgdl - prevGlucose)
                XCTAssertTrue(delta < 50.0,
                    "Glucose delta should be small with constant input, got \(delta)")
            }
            prevGlucose = r.glucoseMgdl
        }
    }

    func testLot2Processing() {
        let lot2Config = SensorConfig.Builder()
            .eapp(0.05)
            .vref(1.2)
            .slope100(2.5)
            .slope(0.025)
            .slopeRatio(1.0)
            .t90(10.0)
            .basicWarmup(5)
            .err345Seq2(5)
            .iirFlag(1)
            .sensorStartTime(100)
            .maximumValue(500.0)
            .wSgX100([-3, 12, 17, 12, 17, 12, -3])
            .err1Seq([23, 50, 100])
            .err1NLast(288)
            .err1Multi([10, 10])
            .err2Seq([100, 48, 24])
            .err2StartSeq(289)
            .err2Cummax(1)
            .err2Glu(100.0)
            .err345Seq4([0, 0, 12, 0, 0])
            .err32Dt([10, 15])
            .err32N([3, 5])
            .kalmanDeltaT(5)
            .build()

        let cal = CareSensCalibrator(lot2Config)

        let r = cal.processReading(
            seqNumber: 1, timestamp: 1000,
            adcSamples: Self.createAdcSamples(2500), temperature: 36.5)
        // assertNotNull(r) - non-optional return type in Swift
        XCTAssertTrue(r.glucoseMgdl.isFinite)
    }

    func testFacadeMatchesPipeline() {
        // Verify the facade produces the same output as calling
        // CalibrationAlgorithm.process() directly.
        let config = Self.createTypicalConfig()
        let cal = CareSensCalibrator(config)

        let seq = 1
        let time: Int64 = 1000
        let adc = Self.createAdcSamples(2000)
        let temp = 36.5

        // Through facade
        let facadeResult = cal.processReading(
            seqNumber: seq, timestamp: time,
            adcSamples: adc, temperature: temp)

        // Direct pipeline call
        let di = config.toDeviceInfo()
        let state = AlgorithmState()
        let calList = CalibrationList()
        let input = CgmInput()
        input.seqNumber = seq
        input.measurementTimeStandard = time
        input.temperature = temp
        for i in 0..<30 {
            input.workout[i] = adc[i]
        }
        let output = AlgorithmOutput()
        let debug = DebugOutput()
        CalibrationAlgorithm.process(
            deviceInfo: di,
            cgmInput: input,
            calInput: calList,
            algoArgs: state,
            algoOutput: output,
            algoDebug: debug)

        // Verify facade matches direct call
        XCTAssertEqual(output.resultGlucose, facadeResult.glucoseMgdl, accuracy: 0.0)
        XCTAssertEqual(output.trendrate, facadeResult.trendRate, accuracy: 0.0)
        XCTAssertEqual(output.errcode, facadeResult.errorCode)
        XCTAssertEqual(output.currentStage, facadeResult.stage)
    }
}
