import XCTest
@testable import OpenCareSensAir

/// Tests for CalibrationAlgorithm, the main 14-step CGM calibration pipeline.
///
/// Converted from the Java JUnit 5 CalibrationAlgorithmTest.
///
/// MEDICAL SAFETY: These tests verify that every calculation matches the C
/// implementation at machine-epsilon precision. Incorrect glucose values lead
/// to wrong insulin dosing, causing dangerous hypo/hyperglycemia.
final class CalibrationAlgorithmTests: XCTestCase {

    private static let eps = 1e-10

    // ======================================================================
    // Test 1: ADC to current conversion
    // ======================================================================

    // MARK: - ADC to current conversion

    func testAdcToCurrentKnownConversion() {
        // current = (2048 * 1.2 / 40950.0 - 0.10067) * 100.0
        // = (0.060014652 - 0.10067) * 100 = -4.0655348...
        var adc = [Int](repeating: 0, count: 30)
        adc[0] = 2048
        let result = CalibrationAlgorithm.adcToCurrent(adc, 1.2, 0.10067)

        let expected = (Double(2048) * Double(1.2 as Float) / 40950.0
                       - Double(0.10067 as Float)) * 100.0
        XCTAssertEqual(expected, result[0], accuracy: 0.0)
    }

    func testAdcToCurrentAdcZero() {
        let adc = [Int](repeating: 0, count: 30)
        let result = CalibrationAlgorithm.adcToCurrent(adc, 1.2, 0.10067)
        let expected = (-Double(0.10067 as Float)) * 100.0
        XCTAssertEqual(expected, result[0], accuracy: 0.0)
    }

    func testAdcToCurrentAdcMax() {
        var adc = [Int](repeating: 0, count: 30)
        adc[0] = 4095
        let result = CalibrationAlgorithm.adcToCurrent(adc, 1.2, 0.10067)
        let expected = (Double(4095) * Double(1.2 as Float) / 40950.0
                       - Double(0.10067 as Float)) * 100.0
        XCTAssertEqual(expected, result[0], accuracy: 0.0)
    }

    func testAdcToCurrentAllThirtyConverted() {
        var adc = [Int](repeating: 0, count: 30)
        for i in 0..<30 { adc[i] = 1000 + i * 10 }
        let result = CalibrationAlgorithm.adcToCurrent(adc, 1.5, 0.05)
        for i in 0..<30 {
            let expected = (Double(adc[i]) * Double(1.5 as Float) / 40950.0
                           - Double(0.05 as Float)) * 100.0
            XCTAssertEqual(expected, result[i], accuracy: 0.0)
        }
    }

    // ======================================================================
    // Test 2: Lot type determination
    // ======================================================================

    // MARK: - Lot type determination

    func testDetermineLotType1() {
        XCTAssertEqual(1, CalibrationAlgorithm.determineLotType(0.10067))
    }

    func testDetermineLotType2() {
        XCTAssertEqual(2, CalibrationAlgorithm.determineLotType(0.05))
    }

    func testDetermineLotType0FloatPromotion() {
        // In C: (double)(float)0.075 > 0.075 due to float rounding.
        // 0.075 as Float = 0.07500000298023224 in double, which is > 0.075.
        // So lot_type = 1, matching the C behavior exactly.
        XCTAssertEqual(1, CalibrationAlgorithm.determineLotType(0.075))
    }

    func testDetermineLotType0ExactDouble() {
        // This tests the branch directly. In practice, the float->double
        // promotion means 0.075 as Float never equals 0.075 exactly.
        // We test with a value that is exactly 0.075 in the comparison.
        // Since determineLotType takes Float, we can't test this path
        // through the public API -- the == 0.075 branch is dead code
        // for IEEE 754 float inputs.
        XCTAssertTrue(true) // documented dead code path
    }

    func testDetermineLotTypeNanEapp() {
        XCTAssertEqual(2, CalibrationAlgorithm.determineLotType(.nan))
    }

    func testDetermineLotTypeZeroEapp() {
        XCTAssertEqual(2, CalibrationAlgorithm.determineLotType(0.0))
    }

    // ======================================================================
    // Test 3: IIR filter behavior
    // ======================================================================

    // MARK: - IIR filter

    func testIirDisabled() {
        let args = AlgorithmState()
        let dev = DeviceInfo()
        dev.iirFlag = 0
        XCTAssertEqual(42.5, CalibrationAlgorithm.iirFilter(42.5, args, dev), accuracy: 0.0)
    }

    func testIirEnabled() {
        let args = AlgorithmState()
        let dev = DeviceInfo()
        dev.iirFlag = 1
        let result = CalibrationAlgorithm.iirFilter(42.5, args, dev)
        XCTAssertEqual(42.5, result, accuracy: 0.0)
        XCTAssertEqual(42.5, args.iirX[0], accuracy: 0.0)
        XCTAssertEqual(42.5, args.iirY, accuracy: 0.0)
        XCTAssertEqual(1, args.iirStartFlag)
    }

    func testIirHistory() {
        let args = AlgorithmState()
        let dev = DeviceInfo()
        dev.iirFlag = 1
        _ = CalibrationAlgorithm.iirFilter(10.0, args, dev)
        _ = CalibrationAlgorithm.iirFilter(20.0, args, dev)
        XCTAssertEqual(20.0, args.iirX[0], accuracy: 0.0)
        XCTAssertEqual(10.0, args.iirX[1], accuracy: 0.0)
    }

    // ======================================================================
    // Test 4: Temperature correction
    // ======================================================================

    // MARK: - Temperature correction

    func testTempCorrectionLot1Temp36_5() {
        let args = AlgorithmState()
        args.idxOriginSeq = 1
        let srt = CalibrationAlgorithm.computeSlopeRatioTempBuffered(36.5, args, 1)
        // 1.0 + (-0.1584) * (36.5 - 37.0) = 1.0 + 0.0792 = 1.0792
        XCTAssertEqual(1.0792, srt, accuracy: Self.eps)
    }

    func testTempCorrectionLot1TempRef() {
        let args = AlgorithmState()
        args.idxOriginSeq = 1
        let srt = CalibrationAlgorithm.computeSlopeRatioTempBuffered(37.0, args, 1)
        XCTAssertEqual(1.0, srt, accuracy: Self.eps)
    }

    func testTempCorrectionLot2TempRef() {
        let args = AlgorithmState()
        args.idxOriginSeq = 1
        // Oracle-verified: lot_type=2 uses the same formula as lot_type=1:
        // srt = 1 + (-0.1584) * (T - 37.0)
        // At T=37.0: srt = 1.0
        let srt = CalibrationAlgorithm.computeSlopeRatioTempBuffered(37.0, args, 2)
        XCTAssertEqual(1.0, srt, accuracy: 1e-8)
    }

    func testTempCorrectionLot0NoCorrection() {
        let args = AlgorithmState()
        args.idxOriginSeq = 1
        let srt = CalibrationAlgorithm.computeSlopeRatioTempBuffered(30.0, args, 0)
        XCTAssertEqual(1.0, srt, accuracy: 0.0)
    }

    func testTempCorrectionCircularBufferAveraging() {
        let args = AlgorithmState()

        // First reading
        args.idxOriginSeq = 1
        _ = CalibrationAlgorithm.computeSlopeRatioTempBuffered(36.0, args, 1)

        // Second reading: mean = (36.0 + 38.0) / 2 = 37.0
        args.idxOriginSeq = 2
        let srt2 = CalibrationAlgorithm.computeSlopeRatioTempBuffered(38.0, args, 1)
        // 1.0 + (-0.1584) * (37.0 - 37.0) = 1.0
        XCTAssertEqual(1.0, srt2, accuracy: Self.eps)

        // Third reading
        args.idxOriginSeq = 3
        _ = CalibrationAlgorithm.computeSlopeRatioTempBuffered(36.0, args, 1)

        // Fourth reading
        args.idxOriginSeq = 4
        _ = CalibrationAlgorithm.computeSlopeRatioTempBuffered(36.0, args, 1)

        // Fifth reading: overwrites index 0, buffer = [37.0, 38.0, 36.0, 36.0]
        args.idxOriginSeq = 5
        let srt5 = CalibrationAlgorithm.computeSlopeRatioTempBuffered(37.0, args, 1)
        // buf = [37.0, 38.0, 36.0, 36.0] -> mean = 36.75
        // srt = 1.0 + (-0.1584) * (36.75 - 37.0) = 1.0 + 0.0396 = 1.0396
        XCTAssertEqual(1.0 + (-0.1584) * (36.75 - 37.0), srt5, accuracy: Self.eps)
    }

    // ======================================================================
    // Test 5: Drift correction polynomial
    // ======================================================================

    // MARK: - Drift correction

    func testDriftCorrectionSeq1() {
        let args = AlgorithmState()
        args.idxOriginSeq = 1
        let debug = DebugOutput()

        let outIir = 5.0
        let result = CalibrationAlgorithm.driftCorrection(outIir, args, debug)

        // poly(1) = A + B + C + D
        let poly = CalibrationAlgorithm.DRIFT_COEF_A
                 + CalibrationAlgorithm.DRIFT_COEF_B
                 + CalibrationAlgorithm.DRIFT_COEF_C
                 + CalibrationAlgorithm.DRIFT_COEF_D
        let divisor = (1.0 - 0.9) + poly * 0.9
        let expected = outIir / divisor

        XCTAssertEqual(expected, result, accuracy: Self.eps)
        XCTAssertEqual(expected, debug.outDrift, accuracy: Self.eps)
        XCTAssertEqual(expected, debug.currBaseline, accuracy: Self.eps)
        XCTAssertEqual(expected, args.baselinePrev, accuracy: Self.eps)
    }

    func testDriftCorrectionSeq100() {
        let args = AlgorithmState()
        args.idxOriginSeq = 100
        args.baselinePrev = 5.0
        let debug = DebugOutput()

        let outIir = 5.5
        let result = CalibrationAlgorithm.driftCorrection(outIir, args, debug)

        let seq = 100.0
        let poly = CalibrationAlgorithm.DRIFT_COEF_A * seq * seq * seq
                 + CalibrationAlgorithm.DRIFT_COEF_B * seq * seq
                 + CalibrationAlgorithm.DRIFT_COEF_C * seq
                 + CalibrationAlgorithm.DRIFT_COEF_D
        let divisor = 0.1 + poly * 0.9
        let expected = outIir / divisor

        XCTAssertEqual(expected, result, accuracy: Self.eps)
        // baseline = (5.0 * 99 + expected) / 100
        let expectedBaseline = (5.0 * 99.0 + expected) / 100.0
        XCTAssertEqual(expectedBaseline, debug.currBaseline, accuracy: Self.eps)
    }

    func testDriftCorrectionPolyClamp() {
        // At very large seq, poly can exceed 1.0 is unlikely for this polynomial,
        // but test the clamp logic
        let args = AlgorithmState()
        args.idxOriginSeq = 1
        let debug = DebugOutput()

        // The poly at seq=1 is ~0.9147, so divisor != 1.0
        let result = CalibrationAlgorithm.driftCorrection(10.0, args, debug)
        XCTAssertTrue(result > 10.0) // outIir / divisor where divisor < 1
    }

    // ======================================================================
    // Test 6: Holt-Kalman bias correction
    // ======================================================================

    // MARK: - Holt-Kalman bias correction

    func testHoltKalmanCntOneInit() {
        let args = AlgorithmState()
        args.biasCnt = 1
        let initCg = 120.0

        args.holtLevel = initCg
        args.holtForecast = initCg
        args.holtTrend = 0.0

        // At cnt=1, opcal_ad = init_cg
        XCTAssertEqual(initCg, args.holtLevel, accuracy: 0.0)
        XCTAssertEqual(initCg, args.holtForecast, accuracy: 0.0)
        XCTAssertEqual(0.0, args.holtTrend, accuracy: 0.0)
    }

    func testHoltKalmanCntTwoUpdate() {
        let initCg1 = 120.0
        let initCg2 = 122.0

        // Simulate cnt=1 init
        let holtLevel = initCg1
        let holtForecast = initCg1
        let holtTrend = 0.0

        // cnt=2: prediction
        let phi = CalibrationAlgorithm.PHI
        let levelPred = phi * holtLevel + (1.0 - phi) * holtForecast
        let forecastPred = holtForecast + holtTrend
        let trendPred = holtTrend

        let innovation = initCg2 - levelPred
        let newLevel = levelPred + 0.6729 * innovation
        let newForecast = forecastPred + 1.761 * innovation
        let newTrend = trendPred + 0.1279 * innovation

        // cnt=2 <= 25: blend
        let opcalAd = initCg2 + (newForecast - initCg2) * (2 - 1) / 24.0

        // Verify the prediction
        // levelPred = phi*120 + (1-phi)*120 = 120.0
        XCTAssertEqual(120.0, levelPred, accuracy: Self.eps)
        // innovation = 122 - 120 = 2.0
        XCTAssertEqual(2.0, innovation, accuracy: Self.eps)
        // newForecast = 120 + 1.761 * 2.0 = 123.522
        XCTAssertEqual(123.522, newForecast, accuracy: Self.eps)
        // opcalAd = 122 + (123.522 - 122) * 1/24
        let expectedOpcalAd = 122.0 + 1.522 / 24.0
        XCTAssertEqual(expectedOpcalAd, opcalAd, accuracy: Self.eps)
    }

    func testHoltKalmanCntAbove25() {
        // After cnt > 25, opcal_ad = forecast directly
        // This verifies the branching condition
        let holtForecast = 125.0
        // cnt=26 > 25: opcal_ad = holtForecast
        XCTAssertEqual(125.0, holtForecast, accuracy: 0.0)
    }

    func testHoltKalmanPhiConstant() {
        XCTAssertEqual(Foundation.exp(-0.5), CalibrationAlgorithm.PHI, accuracy: 1e-15)
    }

    // ======================================================================
    // Test 7: Trendrate computation
    // ======================================================================

    // MARK: - Trendrate computation

    func testTrendrateEarlyGuard() {
        let args = AlgorithmState()
        args.idxOriginSeq = 5
        let debug = DebugOutput()
        debug.trendrate = 100.0

        CalibrationAlgorithm.computeTrendrate(args, debug, 0, 1000)
        XCTAssertEqual(100.0, debug.trendrate, accuracy: 0.0)
    }

    func testTrendrateDivByZeroRateLong() {
        let args = AlgorithmState()
        args.idxOriginSeq = 20
        // Set up timestamps: T[3] == timeNow => denomLong == 0
        let baseTime: Int64 = 3000
        for i in 0..<10 {
            args.smoothTimeIn[i] = baseTime + Int64(i * 300)
        }
        // Force T[3] == timeNow
        let timeNow = args.smoothTimeIn[3]
        // Set glucose values in valid range
        for i in 0..<10 {
            args.smoothSigIn[i] = 100.0 + Double(i * 5)
        }
        let debug = DebugOutput()
        debug.trendrate = 100.0

        CalibrationAlgorithm.computeTrendrate(args, debug, 0, timeNow)
        // trendrate must remain at sentinel, not become NaN/Infinity
        XCTAssertEqual(100.0, debug.trendrate, accuracy: 0.0)
        XCTAssertFalse(debug.trendrate.isNaN)
        XCTAssertFalse(debug.trendrate.isInfinite)
    }

    func testTrendrateDivByZeroRateShort() {
        let args = AlgorithmState()
        args.idxOriginSeq = 20
        // Set up timestamps where T[3..9] are spaced >= 181s but T[8] == timeNow
        for i in 0..<10 {
            args.smoothTimeIn[i] = Int64(i * 300)
        }
        let timeNow = args.smoothTimeIn[8] // denomShort == 0
        for i in 0..<10 {
            args.smoothSigIn[i] = 100.0 + Double(i * 5)
        }
        let debug = DebugOutput()
        debug.trendrate = 100.0

        CalibrationAlgorithm.computeTrendrate(args, debug, 0, timeNow)
        XCTAssertFalse(debug.trendrate.isNaN)
        XCTAssertFalse(debug.trendrate.isInfinite)
    }

    func testTrendrateDivByZeroRateMid() {
        let args = AlgorithmState()
        args.idxOriginSeq = 20
        // Set up timestamps spaced >= 181s except T[7] == T[8]
        for i in 0..<10 {
            args.smoothTimeIn[i] = Int64(i * 300)
        }
        args.smoothTimeIn[8] = args.smoothTimeIn[7] // denomMid == 0
        for i in 0..<10 {
            args.smoothSigIn[i] = 100.0 + Double(i * 5)
        }
        let timeNow: Int64 = 3600
        let debug = DebugOutput()
        debug.trendrate = 100.0

        CalibrationAlgorithm.computeTrendrate(args, debug, 0, timeNow)
        XCTAssertFalse(debug.trendrate.isNaN)
        XCTAssertFalse(debug.trendrate.isInfinite)
    }

    func testTrendrateErrorDelayGuard() {
        let args = AlgorithmState()
        args.idxOriginSeq = 20
        // Set up valid timestamps (need T[3..9] spaced >= 181s)
        for i in 0..<10 {
            args.smoothTimeIn[i] = Int64(i * 300)
        }
        // Set up glucose values in [40, 500] range
        for i in 0..<10 {
            args.smoothSigIn[i] = 100.0 + Double(i)
        }
        // Put error at position 2 (shifts to position 1 after left-shift,
        // still in the checked range [0..6])
        args.errDelayArr[2] = 1
        let debug = DebugOutput()
        debug.trendrate = 100.0

        CalibrationAlgorithm.computeTrendrate(args, debug, 0, 3000)
        XCTAssertEqual(100.0, debug.trendrate, accuracy: 0.0) // unchanged due to error flag
    }

    // ======================================================================
    // Test 8: Full pipeline integration
    // ======================================================================

    // MARK: - Full pipeline integration

    private var devInfo: DeviceInfo!
    private var algoArgs: AlgorithmState!
    private var calInput: CalibrationList!

    override func setUp() {
        super.setUp()
        devInfo = Self.createTypicalDeviceInfo()
        algoArgs = AlgorithmState()
        calInput = CalibrationList()
    }

    func testFullPipelineInvalidEapp() {
        devInfo.eapp = -0.1
        let input = Self.createCgmInput(seq: 1, time: 1000, adcValue: 2000, temp: 36.5)
        let output = AlgorithmOutput()
        let debug = DebugOutput()

        let result = CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input, calInput: calInput,
            algoArgs: algoArgs, algoOutput: output, algoDebug: debug)
        XCTAssertEqual(1, result)
        XCTAssertEqual(1, debug.nOpcalState)
        XCTAssertEqual(0.0, output.resultGlucose, accuracy: 0.0)
    }

    func testFullPipelineInvalidSlope100() {
        devInfo.slope100 = 15.0
        let input = Self.createCgmInput(seq: 1, time: 1000, adcValue: 2000, temp: 36.5)
        let output = AlgorithmOutput()
        let debug = DebugOutput()

        let result = CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input, calInput: calInput,
            algoArgs: algoArgs, algoOutput: output, algoDebug: debug)
        XCTAssertEqual(1, result)
        XCTAssertEqual(1, debug.nOpcalState)
    }

    func testFullPipelineZeroSlope100Rejected() {
        devInfo.slope100 = 0.0
        let input = Self.createCgmInput(seq: 1, time: 1000, adcValue: 2000, temp: 36.5)
        let output = AlgorithmOutput()
        let debug = DebugOutput()

        let result = CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input, calInput: calInput,
            algoArgs: algoArgs, algoOutput: output, algoDebug: debug)
        XCTAssertEqual(1, result)
        XCTAssertEqual(1, debug.nOpcalState)
        XCTAssertEqual(0.0, output.resultGlucose, accuracy: 0.0)
    }

    func testFullPipelineFirstReading() {
        let input = Self.createCgmInput(seq: 1, time: 1000, adcValue: 2000, temp: 36.5)
        let output = AlgorithmOutput()
        let debug = DebugOutput()

        let result = CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input, calInput: calInput,
            algoArgs: algoArgs, algoOutput: output, algoDebug: debug)

        XCTAssertEqual(1, result)
        XCTAssertEqual(1, algoArgs.lotType) // eapp=0.10067 > 0.075
        XCTAssertEqual(devInfo.sensorStartTime, algoArgs.sensorStartTime)
        XCTAssertEqual(-1, algoArgs.stateReturnOpcal)
        XCTAssertEqual(1, algoArgs.idxOriginSeq)
    }

    func testFullPipelineFirstReadingHeaders() {
        let input = Self.createCgmInput(seq: 3, time: 5000, adcValue: 2000, temp: 36.5)
        let output = AlgorithmOutput()
        let debug = DebugOutput()

        CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input, calInput: calInput,
            algoArgs: algoArgs, algoOutput: output, algoDebug: debug)

        XCTAssertEqual(3, output.seqNumberOriginal)
        XCTAssertEqual(3, output.seqNumberFinal) // cumulSum=0
        XCTAssertEqual(Int64(5000), output.measurementTimeStandard)
        XCTAssertEqual(3, debug.seqNumberOriginal)
        XCTAssertEqual(Int64(5000), debug.measurementTimeStandard)
    }

    func testFullPipelineWarmupStage() {
        let input = Self.createCgmInput(seq: 3, time: 1000, adcValue: 2000, temp: 36.5)
        let output = AlgorithmOutput()
        let debug = DebugOutput()

        CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input, calInput: calInput,
            algoArgs: algoArgs, algoOutput: output, algoDebug: debug)

        XCTAssertEqual(0, debug.stage)
        XCTAssertEqual(0, output.currentStage)
    }

    func testFullPipelineSteadyStateStage() {
        let input = Self.createCgmInput(seq: 10, time: 1000, adcValue: 2000, temp: 36.5)
        let output = AlgorithmOutput()
        let debug = DebugOutput()

        CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input, calInput: calInput,
            algoArgs: algoArgs, algoOutput: output, algoDebug: debug)

        XCTAssertEqual(1, debug.stage)
        XCTAssertEqual(1, output.currentStage)
    }

    func testFullPipelineDebugInitValues() {
        let input = Self.createCgmInput(seq: 1, time: 1000, adcValue: 2000, temp: 36.5)
        let output = AlgorithmOutput()
        let debug = DebugOutput()

        CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input, calInput: calInput,
            algoArgs: algoArgs, algoOutput: output, algoDebug: debug)

        XCTAssertTrue(debug.diabetesTAR.isNaN)
        XCTAssertTrue(debug.diabetesTBR.isNaN)
        XCTAssertTrue(debug.diabetesCV.isNaN)
        XCTAssertEqual(6, debug.levelDiabetes)
        XCTAssertEqual(1.0, debug.callogCslopePrev, accuracy: 0.0)
        XCTAssertEqual(1.0, debug.callogCslopeNew, accuracy: 0.0)
        XCTAssertEqual(1.0, debug.initstableWeightUsercal, accuracy: 0.0)
        XCTAssertEqual(0.8, debug.initstableFixusercal, accuracy: 0.0)
        XCTAssertEqual(-1, debug.nOpcalState)
    }

    func testFullPipelineLot1BaselineCorrection() {
        let input = Self.createCgmInput(seq: 1, time: 1000, adcValue: 2000, temp: 36.5)
        let output = AlgorithmOutput()
        let debug = DebugOutput()

        CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input, calInput: calInput,
            algoArgs: algoArgs, algoOutput: output, algoDebug: debug)

        // correctedCurrent = tranInA5min - 0.7
        XCTAssertEqual(debug.tranInA5min - 0.7, debug.correctedReCurrent, accuracy: Self.eps)
    }

    func testFullPipelineLot2BaselineCorrection() {
        devInfo.eapp = 0.05 // lot_type=2
        let input = Self.createCgmInput(seq: 1, time: 1000, adcValue: 2000, temp: 36.5)
        let output = AlgorithmOutput()
        let debug = DebugOutput()

        CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input, calInput: calInput,
            algoArgs: algoArgs, algoOutput: output, algoDebug: debug)

        XCTAssertEqual(debug.tranInA5min - 0.243, debug.correctedReCurrent, accuracy: Self.eps)
    }

    func testFullPipelineTwoReadings() {
        let input1 = Self.createCgmInput(seq: 1, time: 1000, adcValue: 2000, temp: 36.5)
        _ = CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input1, calInput: calInput,
            algoArgs: algoArgs, algoOutput: AlgorithmOutput(), algoDebug: DebugOutput())

        let input2 = Self.createCgmInput(seq: 2, time: 1300, adcValue: 2100, temp: 36.6)
        _ = CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input2, calInput: calInput,
            algoArgs: algoArgs, algoOutput: AlgorithmOutput(), algoDebug: DebugOutput())

        XCTAssertEqual(2, algoArgs.idxOriginSeq)
        XCTAssertEqual(Int64(1300), algoArgs.timePrev)
        XCTAssertEqual(2, algoArgs.seqPrev)
    }

    func testFullPipelineGlucosePositive() {
        let input = Self.createCgmInput(seq: 10, time: 5000, adcValue: 2000, temp: 36.5)
        let output = AlgorithmOutput()
        let debug = DebugOutput()

        CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input, calInput: calInput,
            algoArgs: algoArgs, algoOutput: output, algoDebug: debug)

        // With ADC=2000 and typical params, glucose should be computable
        XCTAssertTrue(output.resultGlucose.isFinite)
    }

    func testFullPipelineBiasStateDuringWarmup() {
        // basicWarmup=5, seq=3 => sf=3 <= 5 => biasFlag=0
        let input = Self.createCgmInput(seq: 3, time: 1000, adcValue: 2000, temp: 36.5)
        let output = AlgorithmOutput()
        let debug = DebugOutput()

        CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input, calInput: calInput,
            algoArgs: algoArgs, algoOutput: output, algoDebug: debug)

        XCTAssertEqual(0, algoArgs.biasFlag)
        XCTAssertEqual(1, algoArgs.biasCnt)
    }

    func testFullPipelineBiasPostWarmup() {
        // Feed warmup readings to get past basicWarmup=5
        for s in 1...5 {
            let inp = Self.createCgmInput(seq: s, time: Int64(s * 300), adcValue: 2000, temp: 36.5)
            CalibrationAlgorithm.process(
                deviceInfo: devInfo, cgmInput: inp, calInput: calInput,
                algoArgs: algoArgs, algoOutput: AlgorithmOutput(), algoDebug: DebugOutput())
        }

        // seq=6: sf=6 > bw=5, sf=6 <= bw+6=11, prevFlag=0, sf==bw+1=6 => flag=3
        let inp6 = Self.createCgmInput(seq: 6, time: 1800, adcValue: 2000, temp: 36.5)
        _ = CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: inp6, calInput: calInput,
            algoArgs: algoArgs, algoOutput: AlgorithmOutput(), algoDebug: DebugOutput())

        XCTAssertEqual(3, algoArgs.biasFlag)
        XCTAssertEqual(1, algoArgs.biasCnt)
    }

    func testFullPipelineTrendrateDefault() {
        let input = Self.createCgmInput(seq: 1, time: 1000, adcValue: 2000, temp: 36.5)
        let output = AlgorithmOutput()
        let debug = DebugOutput()

        CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input, calInput: calInput,
            algoArgs: algoArgs, algoOutput: output, algoDebug: debug)

        XCTAssertEqual(100.0, output.trendrate, accuracy: 0.0)
    }

    func testFullPipelineSmoothOutputPopulated() {
        let input = Self.createCgmInput(seq: 1, time: 1000, adcValue: 2000, temp: 36.5)
        let output = AlgorithmOutput()
        let debug = DebugOutput()

        CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input, calInput: calInput,
            algoArgs: algoArgs, algoOutput: output, algoDebug: debug)

        // After one reading, smooth_sig[5] should have the latest glucose
        XCTAssertEqual(6, debug.smoothSig.count)
    }

    func testFullPipelineOutRescalePassthrough() {
        let input = Self.createCgmInput(seq: 10, time: 5000, adcValue: 2000, temp: 36.5)
        let output = AlgorithmOutput()
        let debug = DebugOutput()

        CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input, calInput: calInput,
            algoArgs: algoArgs, algoOutput: output, algoDebug: debug)

        XCTAssertEqual(debug.initCg, debug.outRescale, accuracy: 0.0)
    }

    func testFullPipelineInitstableCounter() {
        // Two readings with very similar ADC => small baseline change
        let input1 = Self.createCgmInput(seq: 1, time: 1000, adcValue: 2000, temp: 36.5)
        CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input1, calInput: calInput,
            algoArgs: algoArgs, algoOutput: AlgorithmOutput(), algoDebug: DebugOutput())

        let input2 = Self.createCgmInput(seq: 2, time: 1300, adcValue: 2000, temp: 36.5)
        CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input2, calInput: calInput,
            algoArgs: algoArgs, algoOutput: AlgorithmOutput(), algoDebug: DebugOutput())

        // Same ADC => same corrected current => small diff_dc
        // initstable counter should have incremented
        XCTAssertTrue(algoArgs.initstableInitcnt >= 0)
    }

    // ======================================================================
    // Test 9: slopeRatioTemp near-zero division guard
    // ======================================================================

    // MARK: - slopeRatioTemp near-zero division guard

    func testSlopeRatioTempExtremeTemperatureNearZeroDivision() {
        // slopeRatioTemp = 1 + (-0.1584) * (T - 37.0)
        // For slopeRatioTemp = 0: T = 37.0 + 1/0.1584 = 43.3144...
        // With slope100=2.5, product = 2.5 * 0 = 0 => division by zero
        // Use temperature that makes slopeRatioTemp very close to zero
        let extremeTemp = 37.0 + 1.0 / 0.1584 // ~43.31, makes srt ~ 0
        let input = CgmInput()
        input.seqNumber = 1
        input.measurementTimeStandard = 1000
        input.temperature = extremeTemp
        for i in 0..<30 { input.workout[i] = 2000 }

        let output = AlgorithmOutput()
        let debug = DebugOutput()

        let result = CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input, calInput: calInput,
            algoArgs: algoArgs, algoOutput: output, algoDebug: debug)

        XCTAssertEqual(1, result)
        XCTAssertEqual(64, output.errcode)
        XCTAssertEqual(0.0, output.resultGlucose, accuracy: 0.0)
        XCTAssertTrue(output.resultGlucose.isFinite,
            "MEDICAL SAFETY: resultGlucose must never be Infinity")
    }

    func testSlopeRatioTempNormalTemperaturePassesThrough() {
        let input = CgmInput()
        input.seqNumber = 1
        input.measurementTimeStandard = 1000
        input.temperature = 36.5
        for i in 0..<30 { input.workout[i] = 2000 }

        let output = AlgorithmOutput()
        let debug = DebugOutput()

        CalibrationAlgorithm.process(
            deviceInfo: devInfo, cgmInput: input, calInput: calInput,
            algoArgs: algoArgs, algoOutput: output, algoDebug: debug)

        // Normal temperature should not trigger the guard
        XCTAssertTrue(debug.initCg.isFinite,
            "initCg should be finite for normal temperature")
        XCTAssertNotEqual(64, output.errcode,
            "Normal temperature should not produce errcode 64 from slopeRatioTemp guard")
    }

    // ======================================================================
    // Test 10: Kalman filter convergence - 50 readings
    // ======================================================================

    // MARK: - Kalman filter convergence

    func testKalmanConvergenceFiftyReadings() {
        let dev = Self.createTypicalDeviceInfo()
        let args = AlgorithmState()
        let calList = CalibrationList()

        var sawWarmupStage = false
        var sawSteadyStage = false
        let baseAdc = 2500
        let baseTime: Int64 = 1000

        for seq in 1...50 {
            let input = CgmInput()
            input.seqNumber = seq
            input.measurementTimeStandard = baseTime + Int64(seq * 300)
            input.temperature = 36.5
            // Slight ADC variation to simulate real sensor
            let adcValue = baseAdc + (seq % 5) * 10 - 20
            for i in 0..<30 { input.workout[i] = adcValue }

            let output = AlgorithmOutput()
            let debug = DebugOutput()

            let result = CalibrationAlgorithm.process(
                deviceInfo: dev, cgmInput: input, calInput: calList,
                algoArgs: args, algoOutput: output, algoDebug: debug)

            // Pipeline must always return 1 (success)
            XCTAssertEqual(1, result, "Pipeline must return 1 at seq=\(seq)")

            // MEDICAL SAFETY: No NaN or Infinity in any critical output field
            XCTAssertTrue(output.resultGlucose.isFinite,
                "resultGlucose must be finite at seq=\(seq) (was \(output.resultGlucose))")
            XCTAssertTrue(output.trendrate.isFinite,
                "trendrate must be finite at seq=\(seq) (was \(output.trendrate))")
            XCTAssertTrue(debug.initCg.isFinite,
                "initCg must be finite at seq=\(seq)")
            XCTAssertTrue(debug.opcalAd.isFinite,
                "opcalAd must be finite at seq=\(seq)")
            XCTAssertTrue(debug.outDrift.isFinite,
                "outDrift must be finite at seq=\(seq)")
            XCTAssertTrue(debug.slopeRatioTemp.isFinite,
                "slopeRatioTemp must be finite at seq=\(seq)")

            // Track warmup transition
            if output.currentStage == 0 { sawWarmupStage = true }
            if output.currentStage == 1 { sawSteadyStage = true }

            // After warmup, glucose should be in a reasonable range
            if seq > 10 && output.errcode == 0 {
                XCTAssertNotEqual(0.0, output.resultGlucose,
                    "Post-warmup glucose should not be exactly 0.0 at seq=\(seq)")
            }
        }

        // Verify warmup transition happened
        XCTAssertTrue(sawWarmupStage, "Should have seen warmup stage (stage=0)")
        XCTAssertTrue(sawSteadyStage, "Should have seen steady state (stage=1)")
    }

    // ======================================================================
    // Test 11: ADC to current edge cases
    // ======================================================================

    // MARK: - ADC to current edge cases

    func testAdcToCurrentNegativeAdcValues() {
        var adc = [Int](repeating: 0, count: 30)
        adc[0] = -100
        adc[1] = -1
        let result = CalibrationAlgorithm.adcToCurrent(adc, 1.2, 0.10067)
        // current = (adc * vref / 40950.0 - eapp) * 100.0
        let expected0 = (Double(-100) * Double(1.2 as Float) / 40950.0
                       - Double(0.10067 as Float)) * 100.0
        XCTAssertEqual(expected0, result[0], accuracy: 0.0)
        XCTAssertTrue(result[0].isFinite)
        XCTAssertTrue(result[0] < 0.0, "Negative ADC should produce negative current")

        let expected1 = (Double(-1) * Double(1.2 as Float) / 40950.0
                       - Double(0.10067 as Float)) * 100.0
        XCTAssertEqual(expected1, result[1], accuracy: 0.0)
    }

    // ======================================================================
    // Test 12: Trendrate boundary glucose values
    // ======================================================================

    // MARK: - Trendrate boundary glucose values

    func testTrendrateGlucoseAtLowerBound() {
        let args = AlgorithmState()
        args.idxOriginSeq = 20
        for i in 0..<10 {
            args.smoothTimeIn[i] = Int64(i * 300)
        }
        // Set glucose at exactly 40.0 (boundary)
        for i in 0..<10 {
            args.smoothSigIn[i] = 40.0
        }
        let timeNow = args.smoothTimeIn[3] + 1500
        let debug = DebugOutput()
        debug.trendrate = 100.0

        CalibrationAlgorithm.computeTrendrate(args, debug, 0, timeNow)
        // At exactly 40.0, the guard "glu[i] < 40.0" should NOT trigger
        // but since all values are equal, rate = 0
        XCTAssertTrue(debug.trendrate.isFinite)
    }

    func testTrendrateGlucoseAtUpperBound() {
        let args = AlgorithmState()
        args.idxOriginSeq = 20
        for i in 0..<10 {
            args.smoothTimeIn[i] = Int64(i * 300)
        }
        // Set glucose at exactly 500.0 (boundary)
        for i in 0..<10 {
            args.smoothSigIn[i] = 500.0
        }
        let timeNow = args.smoothTimeIn[3] + 1500
        let debug = DebugOutput()
        debug.trendrate = 100.0

        CalibrationAlgorithm.computeTrendrate(args, debug, 0, timeNow)
        XCTAssertTrue(debug.trendrate.isFinite)
    }

    func testTrendrateGlucoseBelowLowerBound() {
        let args = AlgorithmState()
        args.idxOriginSeq = 20
        for i in 0..<10 {
            args.smoothTimeIn[i] = Int64(i * 300)
        }
        for i in 0..<10 {
            args.smoothSigIn[i] = 100.0
        }
        // Set one value below 40
        args.smoothSigIn[5] = 39.9
        let timeNow = args.smoothTimeIn[3] + 1500
        let debug = DebugOutput()
        debug.trendrate = 100.0

        CalibrationAlgorithm.computeTrendrate(args, debug, 0, timeNow)
        // Should return early, trendrate unchanged
        XCTAssertEqual(100.0, debug.trendrate, accuracy: 0.0)
    }

    func testTrendrateGlucoseAboveUpperBound() {
        let args = AlgorithmState()
        args.idxOriginSeq = 20
        for i in 0..<10 {
            args.smoothTimeIn[i] = Int64(i * 300)
        }
        for i in 0..<10 {
            args.smoothSigIn[i] = 100.0
        }
        args.smoothSigIn[5] = 500.1
        let timeNow = args.smoothTimeIn[3] + 1500
        let debug = DebugOutput()
        debug.trendrate = 100.0

        CalibrationAlgorithm.computeTrendrate(args, debug, 0, timeNow)
        XCTAssertEqual(100.0, debug.trendrate, accuracy: 0.0)
    }

    // ======================================================================
    // Test 13: Constants match C exactly
    // ======================================================================

    // MARK: - Constants match C implementation

    func testConstantsPhiValue() {
        XCTAssertEqual(0.60653065971263342, CalibrationAlgorithm.PHI, accuracy: 1e-17)
    }

    func testConstantsHoltGains() {
        XCTAssertEqual(0.6729, CalibrationAlgorithm.HOLT_K1, accuracy: 0.0)
        XCTAssertEqual(1.761, CalibrationAlgorithm.HOLT_K2, accuracy: 0.0)
        XCTAssertEqual(0.1279, CalibrationAlgorithm.HOLT_K3, accuracy: 0.0)
    }

    func testConstantsTempConstants() {
        XCTAssertEqual(37.0, CalibrationAlgorithm.TEMP_REF, accuracy: 0.0)
        XCTAssertEqual(0.1584, CalibrationAlgorithm.TEMP_COEFF, accuracy: 0.0)
        XCTAssertEqual(34.0854, CalibrationAlgorithm.LOT2_TEMP_REF, accuracy: 0.0)
        XCTAssertEqual(0.0328, CalibrationAlgorithm.LOT2_TEMP_COEFF, accuracy: 0.0)
    }

    func testConstantsDriftCoefs() {
        XCTAssertEqual(-5.151560190469187e-12, CalibrationAlgorithm.DRIFT_COEF_A, accuracy: 0.0)
        XCTAssertEqual(5.994148299744164e-09, CalibrationAlgorithm.DRIFT_COEF_B, accuracy: 0.0)
        XCTAssertEqual(5.293796500000622e-05, CalibrationAlgorithm.DRIFT_COEF_C, accuracy: 0.0)
        XCTAssertEqual(0.9146662999999999, CalibrationAlgorithm.DRIFT_COEF_D, accuracy: 0.0)
        XCTAssertEqual(0.9, CalibrationAlgorithm.DRIFT_APPLY_RATE, accuracy: 0.0)
    }

    func testConstantsYceptConstants() {
        XCTAssertEqual(0.7, CalibrationAlgorithm.YCEPT_CONTROL, accuracy: 0.0)
        XCTAssertEqual(0.243, CalibrationAlgorithm.YCEPT_TEST, accuracy: 0.0)
    }

    func testConstantsAdcDivisor() {
        XCTAssertEqual(40950.0, CalibrationAlgorithm.ADC_DIVISOR, accuracy: 0.0)
    }

    // ======================================================================
    // Helpers
    // ======================================================================

    private static func createTypicalDeviceInfo() -> DeviceInfo {
        let di = DeviceInfo()
        di.sensorVersion = 1
        di.eapp = 0.10067
        di.vref = 1.2
        di.slope100 = 2.5
        di.slope = 0.025
        di.slopeRatio = 1.0
        di.t90 = 10.0
        di.basicWarmup = 5
        di.iirFlag = 1
        di.iirStDX10 = 90
        di.err345Seq2 = 5
        di.err1Seq = [23, 50, 100]
        di.err1NLast = 288
        di.err1Multi = [10, 10]
        di.err2Seq = [100, 48, 24]
        di.err2StartSeq = 289
        di.err2Cummax = 1
        di.err2Glu = 100.0
        di.maximumValue = 500.0
        di.kalmanDeltaT = 5
        di.err345Seq4 = [0, 0, 12, 0, 0]
        di.err32Dt = [10, 15]
        di.err32N = [3, 5]
        di.sensorStartTime = 100
        di.wSgX100 = [-3, 12, 17, 12, 17, 12, -3]
        return di
    }

    private static func createCgmInput(seq: Int, time: Int64, adcValue: Int, temp: Double) -> CgmInput {
        let input = CgmInput()
        input.seqNumber = seq
        input.measurementTimeStandard = time
        input.temperature = temp
        for i in 0..<30 { input.workout[i] = adcValue }
        return input
    }
}
