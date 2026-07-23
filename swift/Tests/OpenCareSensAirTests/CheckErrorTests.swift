// CheckErrorTests.swift
// Tests for CheckError, ported from check_error.c.
// Each error detector is tested independently following Red-Green-Refactor.
//
// MEDICAL SAFETY: These tests verify that error detection matches the C
// implementation exactly. Incorrect error codes can suppress or fabricate
// glucose readings, leading to dangerous insulin dosing decisions.

import XCTest
@testable import OpenCareSensAir

final class CheckErrorTests: XCTestCase {

    private let eps: Double = 1e-10

    private var devInfo: DeviceInfo!
    private var algoArgs: AlgorithmState!
    private var debug: DebugOutput!

    override func setUp() {
        super.setUp()
        devInfo = DeviceInfo()
        algoArgs = AlgorithmState()
        debug = DebugOutput()

        // Typical factory defaults
        devInfo.err1Seq = [23, 50, 100]
        devInfo.err1NLast = 288
        devInfo.err1Multi = [10, 10]
        devInfo.err2Seq = [100, 48, 24]
        devInfo.err2StartSeq = 289
        devInfo.err2Cummax = 1
        devInfo.err2Glu = 100.0
        devInfo.maximumValue = 500.0
        devInfo.kalmanDeltaT = 5
        devInfo.err345Seq2 = 5
        devInfo.err345Seq4 = [0, 0, 12, 0, 0]
        devInfo.err32Dt = [10, 15]
        devInfo.err32N = [3, 5]
        devInfo.slope100 = 100.0
    }

    // ======================================================================
    // shiftArrays — FIFO maintenance
    // ======================================================================

    func testErrGluArrShiftsAndAppends() {
        for i in 0..<288 {
            algoArgs.errGluArr[i] = Double(i)
        }

        CheckError.shiftArrays(algoArgs, debug, 150.7)

        XCTAssertEqual(1.0, algoArgs.errGluArr[0], accuracy: eps, "first element should be old [1]")
        XCTAssertEqual(287.0, algoArgs.errGluArr[286], accuracy: eps, "second-to-last")
        XCTAssertEqual(151.0, algoArgs.errGluArr[287], accuracy: eps, "last element = round(150.7)")
    }

    func testErr128BufferShiftsAndAppends() {
        for i in 0..<36 {
            algoArgs.err128CgmCNoiseRevisedValue[i] = Double(i) * 10.0
        }
        debug.tranInA5min = 42.5

        CheckError.shiftArrays(algoArgs, debug, 100.0)

        XCTAssertEqual(10.0, algoArgs.err128CgmCNoiseRevisedValue[0], accuracy: eps)
        XCTAssertEqual(350.0, algoArgs.err128CgmCNoiseRevisedValue[34], accuracy: eps)
        XCTAssertEqual(42.5, algoArgs.err128CgmCNoiseRevisedValue[35], accuracy: eps)
    }

    func testRoundUsesHalfAwayFromZero() {
        CheckError.shiftArrays(algoArgs, debug, 100.5)
        XCTAssertEqual(101.0, algoArgs.errGluArr[287], accuracy: eps)

        CheckError.shiftArrays(algoArgs, debug, -0.5)
        XCTAssertEqual(-1.0, algoArgs.errGluArr[287], accuracy: eps)
    }

    func testNanGlucosePreserved() {
        CheckError.shiftArrays(algoArgs, debug, Double.nan)
        XCTAssertTrue(algoArgs.errGluArr[287].isNaN)
    }

    // ======================================================================
    // err32 — timing gap detection
    // ======================================================================

    func testNoErrorOnFirstReading() {
        algoArgs.err32PrevTime = 0

        let bits = CheckError.detectErr32(devInfo, algoArgs, debug, 1, 1000)

        XCTAssertEqual(0, bits)
        XCTAssertEqual(0, debug.errorCode32)
    }

    func testNoErrorWhenSeqOne() {
        algoArgs.err32PrevTime = 100

        let bits = CheckError.detectErr32(devInfo, algoArgs, debug, 1, 400)

        XCTAssertEqual(0, bits)
    }

    func testNoErrorWithinThreshold() {
        // err32_dt[1] = 15 => threshold2 = 15*60 = 900s
        algoArgs.err32PrevTime = 1000

        let bits = CheckError.detectErr32(devInfo, algoArgs, debug, 5, 1800)

        XCTAssertEqual(0, bits)
        XCTAssertEqual(0, debug.errorCode32)
    }

    func testErrorWhenDtExceedsThreshold2() {
        // threshold2 = 15*60 = 900s, dt = 1000s > 900s
        algoArgs.err32PrevTime = 1000

        let bits = CheckError.detectErr32(devInfo, algoArgs, debug, 5, 2001)

        XCTAssertEqual(32, bits)
        XCTAssertEqual(1, debug.errorCode32)
    }

    func testStateUpdated() {
        CheckError.detectErr32(devInfo, algoArgs, debug, 7, 5000)

        XCTAssertEqual(Int64(5000), algoArgs.err32PrevTime)
        XCTAssertEqual(7, algoArgs.err32PrevSeq)
    }

    // ======================================================================
    // err8 — range/warmup (inactive in factory-cal mode)
    // ======================================================================

    func testAlwaysZero() {
        CheckError.detectErr8(algoArgs, debug)

        XCTAssertEqual(0, debug.errorCode8)
        XCTAssertEqual(0, algoArgs.err8ResultPrev)
    }

    // ======================================================================
    // err1 — contact/noise detection
    // ======================================================================

    func testInactiveBeforeThreshold() {
        devInfo.err1Seq[0] = 23

        let bits = CheckError.detectErr1(devInfo, algoArgs, debug, 23)

        XCTAssertEqual(0, bits)
        XCTAssertEqual(0, debug.errorCode1)
    }

    func testNIncrements() {
        devInfo.err1Seq[0] = 23
        algoArgs.err1N = 0
        debug.tranInA = Array(repeating: 0.0, count: 30)
        debug.tranInA1min = Array(repeating: 0.0, count: 5)

        CheckError.detectErr1(devInfo, algoArgs, debug, 24)
        XCTAssertEqual(1, algoArgs.err1N)
        XCTAssertEqual(1, debug.err1N)

        CheckError.detectErr1(devInfo, algoArgs, debug, 25)
        XCTAssertEqual(2, algoArgs.err1N)
    }

    func testEpochReset() {
        devInfo.err1Seq[0] = 23
        devInfo.err1NLast = 5
        devInfo.err1Multi = [3, 2]

        // Set up accumulators to have known state
        algoArgs.err1N = 5
        algoArgs.err1ThSseDMean1 = 50.0  // mean = 10.0
        algoArgs.err1ThDiff1 = 20.0       // mean = 4.0
        debug.tranInA5min = 99.0

        CheckError.detectErr1(devInfo, algoArgs, debug, 24)

        // Seeds: sse_seed = 10*3 = 30, diff_seed = 4*2 = 8
        XCTAssertEqual(30.0, algoArgs.err1ThSseDMean1, accuracy: eps)
        XCTAssertEqual(30.0, algoArgs.err1ThSseDMean2, accuracy: eps)
        XCTAssertEqual(30.0, algoArgs.err1ThSseDMean, accuracy: eps)
        XCTAssertEqual(8.0, algoArgs.err1ThDiff1, accuracy: eps)
        XCTAssertEqual(8.0, algoArgs.err1ThDiff2, accuracy: eps)
        XCTAssertEqual(8.0, algoArgs.err1ThDiff, accuracy: eps)

        // Flags set
        XCTAssertEqual(1, algoArgs.err1Isfirst0)
        XCTAssertEqual(1, algoArgs.err1Isfirst1)
        XCTAssertEqual(1, algoArgs.err1Isfirst2)

        // n reset to 0
        XCTAssertEqual(0, algoArgs.err1N)
        XCTAssertEqual(0, debug.err1N)

        // tran_5min stored for next avg_diff
        XCTAssertEqual(99.0, algoArgs.err1ISseDMean4h[99], accuracy: eps)
    }

    func testIsfirst2ResetAfterFirstStep() {
        devInfo.err1Seq[0] = 23
        algoArgs.err1N = 0
        algoArgs.err1Isfirst2 = 1
        debug.tranInA = Array(repeating: 0.0, count: 30)
        debug.tranInA1min = Array(repeating: 0.0, count: 5)

        CheckError.detectErr1(devInfo, algoArgs, debug, 24)

        XCTAssertEqual(0, algoArgs.err1Isfirst2)
    }

    func testISseDMeanComputation() {
        devInfo.err1Seq[0] = 0
        algoArgs.err1N = 0
        algoArgs.err1PrevLast1minCurr = 100.0

        // Set up tran_inA_1min: [110, 120, 130, 140, 150]
        debug.tranInA1min = [110.0, 120.0, 130.0, 140.0, 150.0]

        // Set tran_inA[30] to match linear interpolation exactly => sse=0
        debug.tranInA = Array(repeating: 0.0, count: 30)
        var prev = 100.0
        for k in 0..<5 {
            let target = debug.tranInA1min[k]
            let delta = (target - prev) / 6.0
            for j in 0..<6 {
                debug.tranInA[k * 6 + j] = prev + delta * Double(j + 1)
            }
            prev = target
        }

        CheckError.detectErr1(devInfo, algoArgs, debug, 1)

        XCTAssertEqual(0.0, debug.err1ISseDMean, accuracy: eps, "exact match => zero SSE")
    }

    func testISseDMeanWithDeviation() {
        devInfo.err1Seq[0] = 0
        algoArgs.err1N = 0
        algoArgs.err1PrevLast1minCurr = 100.0

        debug.tranInA1min = [100.0, 100.0, 100.0, 100.0, 100.0]

        // All tran_inA values at 100.0 (matching the interpolation)
        debug.tranInA = Array(repeating: 100.0, count: 30)
        // Add deviation of 1.0 at position 0
        debug.tranInA[0] = 101.0

        CheckError.detectErr1(devInfo, algoArgs, debug, 1)

        // sse = 1^2 / 30 = 1/30
        XCTAssertEqual(1.0 / 30.0, debug.err1ISseDMean, accuracy: eps)
    }

    func testFirstEpochAccumulation() {
        devInfo.err1Seq[0] = 0
        algoArgs.err1Isfirst0 = 0 // first epoch
        algoArgs.err1N = 0
        algoArgs.err1PrevLast1minCurr = 0.0

        debug.tranInA = Array(repeating: 0.0, count: 30)
        debug.tranInA1min = Array(repeating: 0.0, count: 5)

        // First step: n becomes 1, th_sse_d_mean1 = i_sse
        CheckError.detectErr1(devInfo, algoArgs, debug, 1)
        let iSse1 = debug.err1ISseDMean
        XCTAssertEqual(iSse1, algoArgs.err1ThSseDMean1, accuracy: eps)
        XCTAssertEqual(iSse1, algoArgs.err1ThSseDMean, accuracy: eps)

        // Second step: th_sse_d_mean1 += i_sse
        algoArgs.err1PrevLast1minCurr = debug.tranInA1min[4]
        CheckError.detectErr1(devInfo, algoArgs, debug, 2)
        let iSse2 = debug.err1ISseDMean
        XCTAssertEqual(iSse1 + iSse2, algoArgs.err1ThSseDMean1, accuracy: eps)
    }

    func testAvgDiffZeroOnFirstStep() {
        devInfo.err1Seq[0] = 0
        algoArgs.err1N = 0
        debug.tranInA = Array(repeating: 0.0, count: 30)
        debug.tranInA1min = Array(repeating: 0.0, count: 5)

        CheckError.detectErr1(devInfo, algoArgs, debug, 1)

        XCTAssertEqual(0.0, debug.err1CurrentAvgDiff, accuracy: eps)
    }

    func testAvgDiffComputedCorrectly() {
        devInfo.err1Seq[0] = 0
        algoArgs.err1N = 0
        debug.tranInA = Array(repeating: 0.0, count: 30)
        debug.tranInA1min = Array(repeating: 0.0, count: 5)
        debug.tranInA5min = 50.0

        CheckError.detectErr1(devInfo, algoArgs, debug, 1)
        // stored tran_5min=50

        debug.tranInA5min = 55.0
        CheckError.detectErr1(devInfo, algoArgs, debug, 2)

        XCTAssertEqual(5.0, debug.err1CurrentAvgDiff, accuracy: eps)
    }

    func testFirstEpochThDiffNaN() {
        devInfo.err1Seq[0] = 0
        algoArgs.err1Isfirst0 = 0 // first epoch
        algoArgs.err1N = 0
        debug.tranInA = Array(repeating: 0.0, count: 30)
        debug.tranInA1min = Array(repeating: 0.0, count: 5)

        CheckError.detectErr1(devInfo, algoArgs, debug, 1)

        XCTAssertTrue(algoArgs.err1ThDiff1.isNaN)
        XCTAssertTrue(algoArgs.err1ThDiff2.isNaN)
        XCTAssertTrue(algoArgs.err1ThDiff.isNaN)
    }

    func testSecondEpochThDiff2NaN() {
        devInfo.err1Seq[0] = 0
        algoArgs.err1Isfirst0 = 1 // second epoch
        algoArgs.err1N = 0
        algoArgs.err1ThDiff1 = 42.0
        debug.tranInA = Array(repeating: 0.0, count: 30)
        debug.tranInA1min = Array(repeating: 0.0, count: 5)

        CheckError.detectErr1(devInfo, algoArgs, debug, 1)

        XCTAssertEqual(42.0, algoArgs.err1ThDiff1, accuracy: eps, "th_diff1 frozen in second epoch")
        XCTAssertTrue(algoArgs.err1ThDiff2.isNaN, "th_diff2 goes NaN")
    }

    // ======================================================================
    // err2 — rate-of-change / delay error
    // ======================================================================

    func testAllNanBeforeActivation() {
        devInfo.err2Seq[2] = 24

        let bits = CheckError.detectErr2(devInfo, algoArgs, debug, 100.0, 10)

        XCTAssertEqual(0, bits)
        XCTAssertTrue(debug.err2DelayRoc.isNaN)
        XCTAssertTrue(debug.err2DelaySlopeSharp.isNaN)
        XCTAssertTrue(debug.err2DelayRocCummax.isNaN)
        XCTAssertTrue(debug.err2Cummax.isNaN)
        XCTAssertTrue(debug.err2CrtCv.isNaN)
    }

    func testGlucoseWindowShifts() {
        devInfo.err2Seq[2] = 100 // inactive

        // Set initial values
        for i in 0..<6 {
            algoArgs.err2CummaxForetime[i] = Double(i + 1) * 10.0
        }

        CheckError.detectErr2(devInfo, algoArgs, debug, 200.0, 1)

        XCTAssertEqual(20.0, algoArgs.err2CummaxForetime[0], accuracy: eps)
        XCTAssertEqual(60.0, algoArgs.err2CummaxForetime[4], accuracy: eps)
        XCTAssertEqual(200.0, algoArgs.err2CummaxForetime[5], accuracy: eps)
    }

    func testRocZeroOnFirstStep() {
        devInfo.err2Seq[2] = 5

        CheckError.detectErr2(devInfo, algoArgs, debug, 100.0, 5)

        XCTAssertEqual(0.0, debug.err2DelayRoc, accuracy: eps)
    }

    func testRocComputed() {
        devInfo.err2Seq[2] = 5

        CheckError.detectErr2(devInfo, algoArgs, debug, 100.0, 5)
        CheckError.detectErr2(devInfo, algoArgs, debug, 125.0, 6)

        // roc = (round(125) - round(100)) / 5.0 = 25/5 = 5.0
        XCTAssertEqual(5.0, debug.err2DelayRoc, accuracy: eps)
    }

    func testCummaxTracking() {
        devInfo.err2Seq[2] = 5

        CheckError.detectErr2(devInfo, algoArgs, debug, 100.0, 5)
        XCTAssertEqual(0.0, debug.err2DelayRocCummax, accuracy: eps)
        XCTAssertEqual(100.0, debug.err2DelayGluCummax, accuracy: eps)

        CheckError.detectErr2(devInfo, algoArgs, debug, 120.0, 6)
        XCTAssertEqual(4.0, debug.err2DelayRocCummax, accuracy: eps) // |20/5| = 4
        XCTAssertEqual(120.0, debug.err2DelayGluCummax, accuracy: eps)

        // Lower glucose: cummax should NOT decrease
        CheckError.detectErr2(devInfo, algoArgs, debug, 110.0, 7)
        XCTAssertEqual(4.0, debug.err2DelayRocCummax, accuracy: eps, "cummax should not decrease")
        XCTAssertEqual(120.0, debug.err2DelayGluCummax, accuracy: eps, "glu cummax stays")
    }

    func testCrtNoFireNormalGlucose() {
        devInfo.err2Seq[2] = 5
        devInfo.maximumValue = 500.0
        devInfo.err2Cummax = 1

        // glucose=100 < maximumValue*cummax (500*1=500) + cummax (1) = 501
        CheckError.detectErr2(devInfo, algoArgs, debug, 100.0, 5)

        XCTAssertEqual(0, debug.err2CrtCurrent[1])
        XCTAssertEqual(0, debug.err2Condi[0])
        XCTAssertEqual(0, debug.err2Condi[1])
    }

    func testCrtCurrentFiresOnHighGlucose() {
        devInfo.err2Seq[2] = 5
        devInfo.maximumValue = 500.0
        devInfo.err2Cummax = 1
        devInfo.err2Seq[1] = 48
        devInfo.kalmanDeltaT = 5
        devInfo.err2Glu = 100.0

        // gluThrCurr = 500*1 + 1 = 501
        // gluThrBase = 500*1 = 500
        // gluThrG1 = 500*1 + 100/1 = 600
        // Fill errGluArr with high values
        for i in 0..<algoArgs.errGluArr.count {
            algoArgs.errGluArr[i] = 700.0
        }

        CheckError.detectErr2(devInfo, algoArgs, debug, 700.0, 5)

        XCTAssertEqual(1, debug.err2CrtCurrent[1], "crt_c1 should fire")
    }

    func testCrtCombinedFires() {
        devInfo.err2Seq[2] = 5
        devInfo.maximumValue = 500.0
        devInfo.err2Cummax = 1
        devInfo.err2Seq[1] = 48
        devInfo.kalmanDeltaT = 5
        devInfo.err2Glu = 100.0
        devInfo.err2StartSeq = 3 // so crtG0Threshold = 1

        // Fill all glucose values high enough
        for i in 0..<algoArgs.errGluArr.count {
            algoArgs.errGluArr[i] = 700.0
        }

        let bits = CheckError.detectErr2(devInfo, algoArgs, debug, 700.0, 5)

        // crt_c1=1 (both current and lagged > threshold)
        // crt_g1=1 (both current and lagged > gluThrG1=600)
        // condi[1] = crt_c1 && crt_g1 = 1
        XCTAssertEqual(1, debug.err2Condi[1])
        XCTAssertEqual(2, bits, "err2 bit should be set")
    }

    func testErr2CummaxTracking() {
        devInfo.err2Seq[2] = 5
        devInfo.err2StartSeq = 10

        debug.tranInA5min = 50.0
        CheckError.detectErr2(devInfo, algoArgs, debug, 100.0, 8)
        XCTAssertTrue(debug.err2Cummax.isNaN, "before start_seq: NaN")

        debug.tranInA5min = 50.0
        CheckError.detectErr2(devInfo, algoArgs, debug, 100.0, 10)
        XCTAssertEqual(50.0, debug.err2Cummax, accuracy: eps, "first at start_seq")

        debug.tranInA5min = 60.0
        CheckError.detectErr2(devInfo, algoArgs, debug, 100.0, 11)
        XCTAssertEqual(60.0, debug.err2Cummax, accuracy: eps, "cummax increases")

        debug.tranInA5min = 40.0
        CheckError.detectErr2(devInfo, algoArgs, debug, 100.0, 12)
        XCTAssertEqual(60.0, debug.err2Cummax, accuracy: eps, "cummax does not decrease")
    }

    func testSlopeSharpRegression() {
        devInfo.err2Seq[2] = 5

        // Fill window with known linear: [10, 20, 30, 40, 50, 60]
        for i in 0..<6 {
            algoArgs.err2CummaxForetime[i] = Double(i + 1) * 10.0
        }

        // seq=6 >= 6 => slopeN=6, start=0
        // x=[0,1,2,3,4,5], y=[10,20,30,40,50,60]
        // slope = 10.0
        CheckError.detectErr2(devInfo, algoArgs, debug, 70.0, 6)

        XCTAssertEqual(10.0, debug.err2DelaySlopeSharp, accuracy: eps)
    }

    func testDelayFieldsInactive() {
        devInfo.err2Seq[2] = 5

        CheckError.detectErr2(devInfo, algoArgs, debug, 100.0, 5)

        XCTAssertTrue(debug.err2DelayRevisedValue.isNaN)
        XCTAssertTrue(debug.err2DelayRocTrimmedMean.isNaN)
        XCTAssertTrue(debug.err2DelaySlopeTrimmedMean.isNaN)
        XCTAssertTrue(debug.err2DelayGluTrimmedMean.isNaN)
        XCTAssertEqual(0, debug.err2DelayFlag)
    }

    // ======================================================================
    // err4 — signal quality
    // ======================================================================

    func testSeq1Initialization() {
        debug.tranInA5min = 42.0

        CheckError.detectErr4(devInfo, algoArgs, debug, 1)

        XCTAssertEqual(42.0, debug.err4Min, accuracy: eps)
        XCTAssertTrue(debug.err4Range.isNaN)
        XCTAssertTrue(debug.err4MinDiff.isNaN)
        XCTAssertEqual(42.0, algoArgs.err4InA[0], accuracy: eps, "stored for next step")
    }

    func testRunningMinTracked() {
        debug.tranInA5min = 50.0
        CheckError.detectErr4(devInfo, algoArgs, debug, 1)

        debug.tranInA5min = 40.0
        CheckError.detectErr4(devInfo, algoArgs, debug, 2)
        XCTAssertEqual(40.0, debug.err4Min, accuracy: eps)

        debug.tranInA5min = 45.0
        CheckError.detectErr4(devInfo, algoArgs, debug, 3)
        XCTAssertEqual(40.0, debug.err4Min, accuracy: eps, "min stays at 40")
    }

    func testRangeIsConsecutiveDifference() {
        debug.tranInA5min = 50.0
        CheckError.detectErr4(devInfo, algoArgs, debug, 1)

        debug.tranInA5min = 53.0
        CheckError.detectErr4(devInfo, algoArgs, debug, 2)
        XCTAssertEqual(3.0, debug.err4Range, accuracy: eps)

        debug.tranInA5min = 48.0
        CheckError.detectErr4(devInfo, algoArgs, debug, 3)
        XCTAssertEqual(-5.0, debug.err4Range, accuracy: eps, "can be negative")
    }

    func testMinDiffTracking() {
        devInfo.err345Seq2 = 5

        debug.tranInA5min = 50.0
        CheckError.detectErr4(devInfo, algoArgs, debug, 1)

        // seq=2: before err345_seq2
        debug.tranInA5min = 53.0
        CheckError.detectErr4(devInfo, algoArgs, debug, 2)
        XCTAssertEqual(0.0, debug.err4MinDiff, accuracy: eps, "0 before threshold")

        // seq=3, 4: still before
        debug.tranInA5min = 48.0
        CheckError.detectErr4(devInfo, algoArgs, debug, 3)
        XCTAssertEqual(0.0, debug.err4MinDiff, accuracy: eps)

        debug.tranInA5min = 40.0
        CheckError.detectErr4(devInfo, algoArgs, debug, 4)
        XCTAssertEqual(0.0, debug.err4MinDiff, accuracy: eps)

        // seq=5: starts tracking, diff = |40 - 40| = 0
        debug.tranInA5min = 40.0
        CheckError.detectErr4(devInfo, algoArgs, debug, 5)
        XCTAssertEqual(0.0, debug.err4MinDiff, accuracy: eps, "diff at seq=5")

        // seq=6: diff = |45 - 40| = 5, min_diff stays at 0
        debug.tranInA5min = 45.0
        CheckError.detectErr4(devInfo, algoArgs, debug, 6)
        XCTAssertEqual(0.0, debug.err4MinDiff, accuracy: eps, "min_diff stays at 0")
    }

    func testMinDiffDecreases() {
        devInfo.err345Seq2 = 2

        // seq=1: init min=50
        debug.tranInA5min = 50.0
        CheckError.detectErr4(devInfo, algoArgs, debug, 1)

        // seq=2: tran5min=55 > min=50, no new minimum -> min_diff=0
        debug.tranInA5min = 55.0
        CheckError.detectErr4(devInfo, algoArgs, debug, 2)
        XCTAssertEqual(0.0, debug.err4MinDiff, accuracy: eps, "no new minimum")

        // seq=3: tran5min=53 > min=50, no new minimum -> min_diff=0
        debug.tranInA5min = 53.0
        CheckError.detectErr4(devInfo, algoArgs, debug, 3)
        XCTAssertEqual(0.0, debug.err4MinDiff, accuracy: eps, "no new minimum")

        // seq=4: tran5min=45 < min=50, new minimum -> min_diff = 45-50 = -5
        debug.tranInA5min = 45.0
        CheckError.detectErr4(devInfo, algoArgs, debug, 4)
        XCTAssertEqual(-5.0, debug.err4MinDiff, accuracy: eps, "new min: signed drop")

        // seq=5: tran5min=43 < min=45, new minimum -> min_diff = 43-45 = -2
        debug.tranInA5min = 43.0
        CheckError.detectErr4(devInfo, algoArgs, debug, 5)
        XCTAssertEqual(-2.0, debug.err4MinDiff, accuracy: eps, "new min: signed drop")

        // seq=6: tran5min=50 > min=43, no new minimum -> min_diff=0
        debug.tranInA5min = 50.0
        CheckError.detectErr4(devInfo, algoArgs, debug, 6)
        XCTAssertEqual(0.0, debug.err4MinDiff, accuracy: eps, "no new minimum")
    }

    func testErr4NeverFires() {
        debug.tranInA5min = 0.0
        let bits = CheckError.detectErr4(devInfo, algoArgs, debug, 1)

        XCTAssertEqual(0, bits)
        XCTAssertEqual(0, debug.errorCode4)
    }

    // ======================================================================
    // err128 — CGM noise revision
    // ======================================================================

    func testBasicBehavior() {
        debug.tranInA5min = 77.5

        CheckError.detectErr128(debug)

        XCTAssertEqual(0, debug.err128Flag)
        XCTAssertEqual(77.5, debug.err128RevisedValue, accuracy: eps)
        XCTAssertTrue(debug.err128Normal.isNaN)
    }

    // ======================================================================
    // err16 — sensor drift
    // ======================================================================

    func testNanBeforeActivation() {
        devInfo.err345Seq4[2] = 12

        let bits = CheckError.detectErr16(devInfo, algoArgs, debug, 11)

        XCTAssertEqual(0, bits)
        XCTAssertTrue(debug.err16CgmPlasma.isNaN)
        XCTAssertTrue(debug.err16CgmIsfSmooth.isNaN)
    }

    func testComputesSmoothedValues() {
        devInfo.err345Seq4[2] = 12
        devInfo.slope100 = 120.0 // conv_factor = 1.2

        // Fill errGluArr last 12 with known values
        for i in 0..<12 {
            algoArgs.errGluArr[276 + i] = 100.0
        }
        // Fill err128 noise buffer last 12
        for i in 0..<12 {
            algoArgs.err128CgmCNoiseRevisedValue[24 + i] = 60.0
        }

        CheckError.detectErr16(devInfo, algoArgs, debug, 12)

        // Uniform input => smoother output = input
        // plasma = round(100) = 100
        // ISF_smooth = round(60 / 1.2) = round(50) = 50
        XCTAssertEqual(100.0, debug.err16CgmPlasma, accuracy: eps)
        XCTAssertEqual(50.0, debug.err16CgmIsfSmooth, accuracy: eps)
    }

    func testNanOnAllZeros() {
        devInfo.err345Seq4[2] = 12
        devInfo.slope100 = 100.0

        // Both buffers are all zeros (default)

        CheckError.detectErr16(devInfo, algoArgs, debug, 12)

        XCTAssertTrue(debug.err16CgmPlasma.isNaN, "zero input => NaN plasma")
        XCTAssertTrue(debug.err16CgmIsfSmooth.isNaN, "zero input => NaN ISF")
    }

    func testErr16NeverFires() {
        devInfo.err345Seq4[2] = 12

        for i in 0..<12 {
            algoArgs.errGluArr[276 + i] = 100.0
            algoArgs.err128CgmCNoiseRevisedValue[24 + i] = 50.0
        }

        let bits = CheckError.detectErr16(devInfo, algoArgs, debug, 12)

        XCTAssertEqual(0, bits)
        XCTAssertEqual(0, debug.errorCode16)
    }

    // ======================================================================
    // checkError — full integration
    // ======================================================================

    func testNormalReadingNoErrors() {
        debug.tranInA5min = 50.0
        debug.tranInA = Array(repeating: 0.0, count: 30)
        debug.tranInA1min = Array(repeating: 0.0, count: 5)

        let errcode = CheckError.checkError(devInfo, algoArgs, debug,
                currentGlucose: 100.0, correctedCurrent: 50.0, seq: 1, timeNow: 1000, stage: 0)

        XCTAssertEqual(0, errcode)
        XCTAssertEqual(1, debug.calAvailableFlag)
    }

    func testTimingGapSetsErr32() {
        algoArgs.err32PrevTime = 1000
        debug.tranInA5min = 50.0
        debug.tranInA = Array(repeating: 0.0, count: 30)
        debug.tranInA1min = Array(repeating: 0.0, count: 5)

        // dt = 2001 - 1000 = 1001 > 15*60=900
        let errcode = CheckError.checkError(devInfo, algoArgs, debug,
                currentGlucose: 100.0, correctedCurrent: 50.0, seq: 5, timeNow: 2001, stage: 0)

        XCTAssertEqual(32, errcode & 32, "err32 bit should be set")
    }

    func testFifoMaintained() {
        debug.tranInA5min = 77.0
        debug.tranInA = Array(repeating: 0.0, count: 30)
        debug.tranInA1min = Array(repeating: 0.0, count: 5)
        algoArgs.errGluArr[287] = 42.0

        CheckError.checkError(devInfo, algoArgs, debug,
                currentGlucose: 150.0, correctedCurrent: 50.0, seq: 1, timeNow: 1000, stage: 0)

        XCTAssertEqual(42.0, algoArgs.errGluArr[286], accuracy: eps, "old [287] shifted to [286]")
        XCTAssertEqual(150.0, algoArgs.errGluArr[287], accuracy: eps, "round(150.0) appended")
        XCTAssertEqual(77.0, algoArgs.err128CgmCNoiseRevisedValue[35], accuracy: eps)
    }

    func testErr128InIntegration() {
        debug.tranInA5min = 55.0
        debug.tranInA = Array(repeating: 0.0, count: 30)
        debug.tranInA1min = Array(repeating: 0.0, count: 5)

        CheckError.checkError(devInfo, algoArgs, debug,
                currentGlucose: 100.0, correctedCurrent: 55.0, seq: 1, timeNow: 1000, stage: 0)

        XCTAssertEqual(0, debug.err128Flag)
        XCTAssertEqual(55.0, debug.err128RevisedValue, accuracy: eps)
        XCTAssertTrue(debug.err128Normal.isNaN)
    }

    func testMultipleErrorBits() {
        // Set up for err32 to fire
        algoArgs.err32PrevTime = 1000
        debug.tranInA5min = 50.0
        debug.tranInA = Array(repeating: 0.0, count: 30)
        debug.tranInA1min = Array(repeating: 0.0, count: 5)

        // err32 fires (dt > threshold2)
        // err2 CRT fires (high glucose)
        devInfo.err2Seq[2] = 2
        devInfo.err2StartSeq = 2
        devInfo.err2Cummax = 1
        devInfo.maximumValue = 500.0
        devInfo.err2Glu = 100.0
        devInfo.kalmanDeltaT = 5
        for i in 0..<algoArgs.errGluArr.count {
            algoArgs.errGluArr[i] = 700.0
        }

        let errcode = CheckError.checkError(devInfo, algoArgs, debug,
                currentGlucose: 700.0, correctedCurrent: 50.0, seq: 5, timeNow: 2001, stage: 0)

        // err32 (32) + err2 (2) = 34
        XCTAssertTrue((errcode & 32) != 0, "err32 should be set")
        XCTAssertTrue((errcode & 2) != 0, "err2 should be set")
    }

    func testSequentialCallsAccumulate() {
        debug.tranInA = Array(repeating: 0.0, count: 30)
        debug.tranInA1min = Array(repeating: 0.0, count: 5)

        for seq in 1...10 {
            debug.tranInA5min = 50.0 + Double(seq)
            let errcode = CheckError.checkError(devInfo, algoArgs, debug,
                    currentGlucose: 100.0 + Double(seq), correctedCurrent: 50.0, seq: seq,
                    timeNow: Int64(1000 + seq * 300), stage: 0)

            XCTAssertEqual(0, errcode, "no errors in normal operation at seq=\(seq)")
        }

        // After 10 calls, last errGluArr should have round(110)
        XCTAssertEqual(110.0, algoArgs.errGluArr[287], accuracy: eps)
    }
}
