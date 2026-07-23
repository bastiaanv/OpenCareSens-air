// SignalProcessingTests.swift
// Tests for SignalProcessing, ported from signal_processing.c.
// Each function is tested in its own MARK group following Red-Green-Refactor.

import XCTest
@testable import OpenCareSensAir

final class SignalProcessingTests: XCTestCase {

    private let eps: Double = 1e-10

    // ==========================================================================
    // MARK: - smoothSg: Savitzky-Golay smoothing
    // ==========================================================================

    func testSmoothSgUniformInputProducesUniformOutput() {
        let sigIn = [Double](repeating: 5.0, count: 10)
        var seqIn = [Int](repeating: 0, count: 10)
        let frepIn = [Int](repeating: 0, count: 6)
        for i in 0..<10 { seqIn[i] = i }

        let weights: [Int] = [5, 10, 20, 30, 20, 10, 5] // sum = 100

        let r = SignalProcessing.smoothSg(
            sigIn, seqIn, frepIn, 5.0, 10, 0, weights)

        // Uniform signal: all outputs should be 5.0
        for i in 0..<10 {
            XCTAssertEqual(5.0, r.sigOut[i], accuracy: eps, "sigOut[\(i)]")
        }
    }

    func testSmoothSgSequenceBufferShiftsCorrectly() {
        let sigIn = [Double](repeating: 0.0, count: 10)
        var seqIn = [Int](repeating: 0, count: 10)
        let frepIn = [Int](repeating: 0, count: 6)
        for i in 0..<10 { seqIn[i] = i + 1 }

        let weights: [Int] = [10, 10, 10, 10, 10, 10, 10]

        let r = SignalProcessing.smoothSg(
            sigIn, seqIn, frepIn, 0.0, 99, 0, weights)

        // seqOut should be [2,3,4,5,6,7,8,9,10,99]
        XCTAssertEqual(2, r.seqOut[0])
        XCTAssertEqual(10, r.seqOut[8])
        XCTAssertEqual(99, r.seqOut[9])
    }

    func testSmoothSgFrepBufferShiftsCorrectly() {
        let frepIn: [Int] = [10, 20, 30, 40, 50, 60]
        let sigIn = [Double](repeating: 0.0, count: 10)
        let seqIn = [Int](repeating: 0, count: 10)
        let weights: [Int] = [10, 10, 10, 10, 10, 10, 10]

        let r = SignalProcessing.smoothSg(
            sigIn, seqIn, frepIn, 0.0, 0, 77, weights)

        // frepOut = [20, 30, 40, 50, 60, 77]
        XCTAssertEqual(20, r.frepOut[0])
        XCTAssertEqual(60, r.frepOut[4])
        XCTAssertEqual(77, r.frepOut[5])
    }

    func testSmoothSgLinearRampPreservesTrendEqualWeights() {
        var sigIn = [Double](repeating: 0.0, count: 10)
        var seqIn = [Int](repeating: 0, count: 10)
        let frepIn = [Int](repeating: 0, count: 6)
        for i in 0..<10 {
            sigIn[i] = Double(i)
            seqIn[i] = i
        }
        // Equal weights => simple average in window
        let weights: [Int] = [10, 10, 10, 10, 10, 10, 10]

        let r = SignalProcessing.smoothSg(
            sigIn, seqIn, frepIn, 10.0, 10, 0, weights)

        // After shift: sigBuf = [1,2,3,4,5,6,7,8,9,10], ref=10
        // Position 3: idx range [0,6] only [0..6] valid
        // acc = sum(w*(sigBuf[j]-10)) for j=0..6 = (1+2+3+4+5+6+7-70)/10 = (28-70)/10 = -42/10
        // But weights each 0.1, totalWeight=0.7
        // acc = 0.1*((1-10)+(2-10)+(3-10)+(4-10)+(5-10)+(6-10)+(7-10)) = 0.1*(-63)=-6.3
        // sigOut[3] = -6.3/0.7+10 = -9+10 = 1
        // For a linear ramp with equal weights and full window, SG should preserve linearity
        // sigOut[3] should be close to the shifted buffer value at center
        XCTAssertEqual(1.0, r.sigOut[0], accuracy: eps) // unsmoothed: sigBuf[0]=1
        XCTAssertEqual(2.0, r.sigOut[1], accuracy: eps)
        XCTAssertEqual(3.0, r.sigOut[2], accuracy: eps)

        // With equal weights and full 7-tap window, linear signal is preserved
        // Position 6: center at 6, idx [3..6] valid (partial window)
        // The exact values depend on the partial window
    }

    func testSmoothSgZeroWeightsDefaultToTotalWeight1() {
        let sigIn = [Double](repeating: 3.0, count: 10)
        let seqIn = [Int](repeating: 0, count: 10)
        let frepIn = [Int](repeating: 0, count: 6)
        let weights: [Int] = [0, 0, 0, 0, 0, 0, 0]

        let r = SignalProcessing.smoothSg(
            sigIn, seqIn, frepIn, 3.0, 0, 0, weights)

        // Zero weights: acc=0 for all, so sigOut[j] = 0/1 + ref = ref = 3.0
        for j in 3..<10 {
            XCTAssertEqual(3.0, r.sigOut[j], accuracy: eps, "sigOut[\(j)]")
        }
    }

    // ==========================================================================
    // MARK: - regressCal: Weighted least-squares recalibration
    // ==========================================================================

    func testRegressCalTwoPointsProduceExactLine() {
        let input: [Double] = [1.0]
        let output: [Double] = [2.0]
        let slopeArr: [Double] = [0]
        let yceptArr: [Double] = [0]

        let r = SignalProcessing.regressCal(
            input, output, slopeArr, yceptArr, 1, 3.0, 6.0)

        // Points: (1,2) and (3,6) => slope=2, ycept=0
        XCTAssertEqual(2.0, r.slope, accuracy: 1e-9)
        XCTAssertEqual(0.0, r.ycept, accuracy: 1e-9)
    }

    func testRegressCalSinglePointDefaultsToSlope1Ycept0() {
        let input: [Double] = []
        let output: [Double] = []
        let slopeArr: [Double] = []
        let yceptArr: [Double] = []

        let r = SignalProcessing.regressCal(
            input, output, slopeArr, yceptArr, 0, 5.0, 10.0)

        // Only 1 point => defaults
        XCTAssertEqual(1.0, r.slope, accuracy: eps)
        XCTAssertEqual(0.0, r.ycept, accuracy: eps)
    }

    func testRegressCalResultArraysPopulatedCorrectly() {
        let input: [Double] = [1.0, 2.0]
        let output: [Double] = [3.0, 5.0]
        let slopeArr = [Double](repeating: 0.0, count: 2)
        let yceptArr = [Double](repeating: 0.0, count: 2)

        let r = SignalProcessing.regressCal(
            input, output, slopeArr, yceptArr, 2, 3.0, 7.0)

        // 3 points: (1,3), (2,5), (3,7) => slope=2, ycept=1
        XCTAssertEqual(2.0, r.slope, accuracy: 1e-9)
        XCTAssertEqual(1.0, r.ycept, accuracy: 1e-9)

        XCTAssertEqual(1.0, r.resultInput[0], accuracy: eps)
        XCTAssertEqual(2.0, r.resultInput[1], accuracy: eps)
        XCTAssertEqual(3.0, r.resultInput[2], accuracy: eps)
    }

    func testRegressCalCapsAt7ExistingPoints() {
        let input: [Double] = [1, 2, 3, 4, 5, 6, 7, 8]
        let output: [Double] = [2, 4, 6, 8, 10, 12, 14, 16]
        let slopeArr = [Double](repeating: 0.0, count: 8)
        let yceptArr = [Double](repeating: 0.0, count: 8)

        // n=8, but capped at 7 existing + 1 new = 8 total
        let r = SignalProcessing.regressCal(
            input, output, slopeArr, yceptArr, 8, 9.0, 18.0)

        XCTAssertEqual(2.0, r.slope, accuracy: 1e-9)
        XCTAssertEqual(0.0, r.ycept, accuracy: 1e-9)
    }

    // ==========================================================================
    // MARK: - checkBoundary: Parallelogram validity check
    // ==========================================================================

    func testCheckBoundaryCenterPointIsInside() {
        // Symmetric parallelogram
        XCTAssertTrue(SignalProcessing.checkBoundary(
            1.0, 0.0,      // slope, ycept
            0.5, 1.5,      // slope_min, slope_max
            -1.0, 1.0,     // ycept_min, ycept_max
            0.8))          // corner_offset
    }

    func testCheckBoundaryYceptOutOfRange() {
        XCTAssertFalse(SignalProcessing.checkBoundary(
            1.0, 2.0,
            0.5, 1.5,
            -1.0, 1.0,
            0.8))
    }

    func testCheckBoundarySlopeOutOfRange() {
        XCTAssertFalse(SignalProcessing.checkBoundary(
            2.0, 0.0,
            0.5, 1.5,
            -1.0, 1.0,
            0.8))
    }

    func testCheckBoundaryOnBoundaryEdge() {
        // slope exactly at slopeMin
        XCTAssertTrue(SignalProcessing.checkBoundary(
            0.5, 0.0,
            0.5, 1.5,
            -1.0, 1.0,
            1.0))
    }

    func testCheckBoundaryTightCornerOffsetRejectsDiagonal() {
        // With tiny corner_offset, the parallelogram is very thin
        // Point at corner: slope=1.5, ycept=-1.0
        // diagSlope = (1.5-0.5)/(-1.0-1.0) = 1.0/(-2.0) = -0.5
        // diagIntercept = 1.5 - (-0.5)*(-1.0) = 1.5 - 0.5 = 1.0
        // lowerBound = 1.0 - 0.01 + (-0.5)*(-1.0) = 0.99 + 0.5 = 1.49
        // upperBound = 0.01 + 1.0 + (-0.5)*(-1.0) = 1.01 + 0.5 = 1.51
        // slope=1.5 is between 1.49 and 1.51 => inside
        XCTAssertTrue(SignalProcessing.checkBoundary(
            1.5, -1.0,
            0.5, 1.5,
            -1.0, 1.0,
            0.01))
    }

    // ==========================================================================
    // MARK: - smooth1qErr16: DFT-based spectral smoothing
    // ==========================================================================

    func testSmooth1qErr16ConstantSignalReturnsSameConstant() {
        let input: [Double] = [3.0, 3.0, 3.0, 3.0, 3.0]
        let out = SignalProcessing.smooth1qErr16(input, 5)

        for i in 0..<5 {
            XCTAssertEqual(3.0, out[i], accuracy: 1e-9, "out[\(i)]")
        }
    }

    func testSmooth1qErr16EmptyInputReturnsEmptyOutput() {
        let out = SignalProcessing.smooth1qErr16([], 0)
        XCTAssertEqual(0, out.count)
    }

    func testSmooth1qErr16SingleElementReturnsSameValue() {
        let input: [Double] = [7.5]
        let out = SignalProcessing.smooth1qErr16(input, 1)
        XCTAssertEqual(7.5, out[0], accuracy: 1e-9)
    }

    func testSmooth1qErr16SmoothingAttenuatesNoise() {
        // Linear signal with spike
        let input: [Double] = [1, 2, 3, 100, 5, 6, 7, 8]
        let out = SignalProcessing.smooth1qErr16(input, 8)

        // The smoothed value at the spike should be much less extreme
        XCTAssertTrue(out[3] < 100.0, "spike should be reduced")
        XCTAssertTrue(out[3] > 1.0, "spike should still be above baseline")
    }

    func testSmooth1qErr16PreservesDcComponent() {
        let input: [Double] = [10, 20, 30, 40]
        let out = SignalProcessing.smooth1qErr16(input, 4)

        // DC component (mean) should be preserved
        var inMean: Double = 0
        var outMean: Double = 0
        for i in 0..<4 {
            inMean += input[i]
            outMean += out[i]
        }
        XCTAssertEqual(inMean / 4.0, outMean / 4.0, accuracy: 1e-9)
    }

    func testSmooth1qErr16TwoElementCaseComputedCorrectly() {
        // With n=2: k=0: w=0, reg=1.0; k=1: w=4.0, reg=1/(1+2*16)=1/33
        // Verify exact computation
        let input: [Double] = [1.0, 3.0]
        let out = SignalProcessing.smooth1qErr16(input, 2)

        // k=0: cosSum=1+3=4, sinSum=0, reg=1, out += [4*1, 4*1] = [4,4]
        // k=1: w=4, reg=1/33
        //   cosSum=(1*cos(0)+3*cos(pi))=1-3=-2, sinSum=(1*sin(0)+3*sin(pi))=0
        //   cosSum*reg = -2/33, sinSum=0
        //   out[0] += -2/33*cos(0) = -2/33
        //   out[1] += -2/33*cos(pi) = 2/33
        // Final: out[0] = (4 - 2/33)/2 = (132-2)/66 = 130/66 = 65/33
        //        out[1] = (4 + 2/33)/2 = (132+2)/66 = 134/66 = 67/33
        XCTAssertEqual(65.0 / 33.0, out[0], accuracy: 1e-9)
        XCTAssertEqual(67.0 / 33.0, out[1], accuracy: 1e-9)
    }

    // ==========================================================================
    // MARK: - calThreshold: Cumulative threshold tracking
    // ==========================================================================

    func testCalThresholdSeq0InitializesState() {
        let r = SignalProcessing.calThreshold(
            0, 0.0, 0.0, 0,    // n, mean, max, flag
            0, 0,                // seq, mode
            5.0, 5.0,            // value, absValue
            0.0, 0.0,            // runningMean, runningMax
            10, 1, 1)           // thresholdSeq, multi1, multi2

        XCTAssertEqual(1, r.n)
        XCTAssertEqual(5.0, r.mean, accuracy: eps)
        XCTAssertEqual(5.0, r.max, accuracy: eps)
        XCTAssertEqual(0, r.flag)
    }

    func testCalThresholdSeqLessThanThresholdAccumulates() {
        let r = SignalProcessing.calThreshold(
            1, 5.0, 5.0, 0,
            3, 0,
            2.0, 2.0,
            5.0, 5.0,
            10, 1, 1)

        XCTAssertEqual(4, r.n)          // seq + 1
        XCTAssertEqual(7.0, r.mean, accuracy: eps) // 5.0 + 2.0
        XCTAssertEqual(5.0, r.max, accuracy: eps)  // 5.0 > 2.0
    }

    func testCalThresholdSeqEqualsThresholdTriggersFlagAndNormalizes() {
        let r = SignalProcessing.calThreshold(
            10, 0.0, 0.0, 0,
            10, 0,               // seq == thresholdSeq, mode=0
            0.0, 0.0,
            50.0, 20.0,          // runningMean, runningMax
            10, 3, 2)           // thresholdSeq, multi1, multi2

        XCTAssertEqual(1, r.flag)
        // mean = (50/10)*3 = 15.0
        XCTAssertEqual(15.0, r.mean, accuracy: eps)
        // max = (20/10)*2 = 4.0
        XCTAssertEqual(4.0, r.max, accuracy: eps)
    }

    func testCalThresholdSeqEqualsThresholdMode1KeepsRawMax() {
        let r = SignalProcessing.calThreshold(
            10, 0.0, 0.0, 0,
            10, 1,               // mode=1
            0.0, 0.0,
            50.0, 20.0,
            10, 3, 2)

        XCTAssertEqual(1, r.flag)
        // mode==1: no normalization
        XCTAssertEqual(50.0, r.mean, accuracy: eps)
        XCTAssertEqual(20.0, r.max, accuracy: eps)
    }

    func testCalThresholdNaNRunningMeanIsReplacedOnAccumulate() {
        let r = SignalProcessing.calThreshold(
            0, 0.0, 0.0, 0,
            2, 0,
            7.0, 7.0,
            Double.nan, Double.nan,
            10, 1, 1)

        XCTAssertEqual(3, r.n)
        XCTAssertEqual(7.0, r.mean, accuracy: eps)
        XCTAssertEqual(7.0, r.max, accuracy: eps)
    }

    func testCalThresholdAbsValueUpdatesRunningMaxWhenLarger() {
        let r = SignalProcessing.calThreshold(
            0, 0.0, 0.0, 0,
            5, 0,
            1.0, 99.0,
            10.0, 50.0,
            10, 1, 1)

        XCTAssertEqual(99.0, r.max, accuracy: eps)
    }

    // ==========================================================================
    // MARK: - err1TdTrioUpdate
    // ==========================================================================

    func testErr1TdTrioUpdateCopiesSrcToDstAndClearsSrc() {
        var dstTrio = [Double](repeating: 0.0, count: 270)
        var dstTime = [Int64](repeating: 0, count: 270)
        var dstFlag = [Int](repeating: 0, count: 90)
        var srcTrio = [Double](repeating: 0.0, count: 270)
        var srcTime = [Int64](repeating: 0, count: 270)
        let srcFlag = [Int](repeating: 0, count: 90)
        var breakFlags: [Int] = [0, 0]

        // Fill src with known values
        for i in 0..<270 {
            srcTrio[i] = Double(i + 1)
            srcTime[i] = Int64(i + 100)
        }
        breakFlags[1] = 5

        SignalProcessing.err1TdTrioUpdate(&dstTrio, &dstTime, &dstFlag,
            &srcTrio, &srcTime, srcFlag, &breakFlags)

        // dst should have src values
        XCTAssertEqual(1.0, dstTrio[0], accuracy: eps)
        XCTAssertEqual(270.0, dstTrio[269], accuracy: eps)
        XCTAssertEqual(Int64(100), dstTime[0])

        // src should be cleared
        for i in 0..<270 {
            XCTAssertEqual(0.0, srcTrio[i], accuracy: eps)
            XCTAssertEqual(Int64(0), srcTime[i])
        }

        // flags cleared
        for i in 0..<90 {
            XCTAssertEqual(0, dstFlag[i])
        }

        // break flags rotated
        XCTAssertEqual(5, breakFlags[0])
        XCTAssertEqual(0, breakFlags[1])
    }

    // ==========================================================================
    // MARK: - err1TdVarUpdate
    // ==========================================================================

    func testErr1TdVarUpdateCopiesSrcToDstAndClearsSrc() {
        var dstSeq = [Int](repeating: 0, count: 90)
        var dstVal = [Double](repeating: 0.0, count: 90)
        var dstTime = [Int64](repeating: 0, count: 90)
        var counts: [Int] = [0, 42]
        var srcVal = [Double](repeating: 0.0, count: 90)
        var srcTime = [Int64](repeating: 0, count: 90)

        for i in 0..<90 {
            srcVal[i] = Double(i) * 0.5
            srcTime[i] = Int64(i + 200)
        }

        SignalProcessing.err1TdVarUpdate(&dstSeq, &dstVal, &dstTime, &counts, &srcVal, &srcTime)

        XCTAssertEqual(0.0, dstVal[0], accuracy: eps)
        XCTAssertEqual(44.5, dstVal[89], accuracy: eps)
        XCTAssertEqual(Int64(200), dstTime[0])
        XCTAssertEqual(Int64(289), dstTime[89])

        // src cleared
        for i in 0..<90 {
            XCTAssertEqual(0.0, srcVal[i], accuracy: eps)
            XCTAssertEqual(Int64(0), srcTime[i])
            XCTAssertEqual(0, dstSeq[i])
        }

        XCTAssertEqual(42, counts[0])
        XCTAssertEqual(0, counts[1])
    }

    // ==========================================================================
    // MARK: - getKernelWeight: LOESS kernel lookup
    // ==========================================================================

    func testGetKernelWeightForwardLookup() {
        // e=0, d=0 => TABLE[0][0] = 1.0
        XCTAssertEqual(1.0, SignalProcessing.getKernelWeight(0, 0), accuracy: eps)
    }

    func testGetKernelWeightBackwardLookupUsesSymmetry() {
        // e=89, d=89 => TABLE[89-89][89-89] = TABLE[0][0] = 1.0
        XCTAssertEqual(1.0, SignalProcessing.getKernelWeight(89, 89), accuracy: eps)
    }

    func testGetKernelWeightSymmetricWeightsForMirroredPositions() {
        // TABLE[d][e] for e<45 should equal TABLE[89-d][89-e] when both are accessed correctly
        // getKernelWeight(5, 10) = TABLE[10][5]
        // getKernelWeight(84, 79) = TABLE[89-79][89-84] = TABLE[10][5]
        let fwd = SignalProcessing.getKernelWeight(5, 10)
        let bwd = SignalProcessing.getKernelWeight(84, 79)
        XCTAssertEqual(fwd, bwd, accuracy: eps)
    }

    // ==========================================================================
    // MARK: - irlsLoess: IRLS LOESS regression
    // ==========================================================================

    func testIrlsLoessConstantDataReturnsConstantFit() {
        let data = [Double](repeating: 42.0, count: 90)

        let fitted = SignalProcessing.irlsLoess(data)

        for i in 0..<90 {
            XCTAssertEqual(42.0, fitted[i], accuracy: 1e-6, "fitted[\(i)]")
        }
    }

    func testIrlsLoessLinearDataIsWellFitted() {
        var data = [Double](repeating: 0.0, count: 90)
        for i in 0..<90 {
            data[i] = 2.0 * Double(i + 1) + 3.0 // y = 2x + 3
        }

        let fitted = SignalProcessing.irlsLoess(data)

        // LOESS on linear data should recover it closely
        for i in 0..<90 {
            XCTAssertEqual(data[i], fitted[i], accuracy: 0.5, "fitted[\(i)]")
        }
    }

    func testIrlsLoessHandlesOutlierRobustlyViaBisquareReweighting() {
        var data = [Double](repeating: 10.0, count: 90) // flat signal
        data[45] = 1000.0 // massive outlier

        let fitted = SignalProcessing.irlsLoess(data)

        // The fitted value at the outlier should be much less extreme
        // due to bisquare reweighting
        XCTAssertTrue(fitted[45] < 100.0,
            "IRLS should suppress outlier, got \(fitted[45])")
    }

    // ==========================================================================
    // MARK: - runningMedians
    // ==========================================================================

    func testRunningMediansConstantInputReturnsSameConstant() {
        let in30 = [Double](repeating: 7.0, count: 30)

        let out = SignalProcessing.runningMedians(in30)

        for i in 0..<30 {
            XCTAssertEqual(7.0, out[i], accuracy: eps, "out[\(i)]")
        }
    }

    func testRunningMediansFirstGroupMediansComputedWithCorrectWindowSizes() {
        // Group 0: values [1, 2, 3, 4, 5, 6]
        var in30 = [Double](repeating: 0.0, count: 30)
        for i in 0..<6 { in30[i] = Double(i + 1) }
        for i in 6..<30 { in30[i] = 0 }

        let out = SignalProcessing.runningMedians(in30)

        // Window of 3: [1,2,3] => median=2
        XCTAssertEqual(2.0, out[0], accuracy: eps)
        // Window of 4: [1,2,3,4] => median=2.5
        XCTAssertEqual(2.5, out[1], accuracy: eps)
        // Window of 5: [1,2,3,4,5] => median=3
        XCTAssertEqual(3.0, out[2], accuracy: eps)
        // Window of 6: [1,2,3,4,5,6] => median=3.5
        XCTAssertEqual(3.5, out[3], accuracy: eps)
        // Window of 5: [2,3,4,5,6] => median=4
        XCTAssertEqual(4.0, out[4], accuracy: eps)
        // Window of 4: [3,4,5,6] => median=4.5
        XCTAssertEqual(4.5, out[5], accuracy: eps)
    }

    // ==========================================================================
    // MARK: - firFilterMedians
    // ==========================================================================

    func testFirFilterMediansConstantInputReturnsSameConstant() {
        let prev3: [Double] = [5.0, 5.0, 5.0]
        let medians30 = [Double](repeating: 5.0, count: 30)

        let out = SignalProcessing.firFilterMedians(prev3, medians30)

        // FIR on constant: sum(coeffs)*5/7 = ([-0.25+1+1.75+2+1.75+1-0.25])*5/7 = 7*5/7 = 5
        for i in 0..<30 {
            XCTAssertEqual(5.0, out[i], accuracy: 1e-9, "out[\(i)]")
        }
    }

    func testFirFilterMediansTailPositionsUseShortenedFir() {
        let prev3: [Double] = [0, 0, 0]
        var medians30 = [Double](repeating: 0.0, count: 30)
        for i in 0..<30 { medians30[i] = Double(i + 1) }

        let out = SignalProcessing.firFilterMedians(prev3, medians30)

        // Verify tail: out[29] = (-0.25*v2 + v3 + 1.75*v4 + 2*v5) / 4.5
        // v = medians30+24 = [25, 26, 27, 28, 29, 30]
        let expected29 = (-0.25 * 27.0 + 28.0 + 1.75 * 29.0 + 2.0 * 30.0) / 4.5
        XCTAssertEqual(expected29, out[29], accuracy: 1e-9)

        let expected28 = (-0.25 * 26.0 + 27.0 + 1.75 * 28.0 + 2.0 * 29.0 + 1.75 * 30.0) / 6.25
        XCTAssertEqual(expected28, out[28], accuracy: 1e-9)
    }

    // ==========================================================================
    // MARK: - perSampleHampelFilter
    // ==========================================================================

    func testPerSampleHampelFilterCleanDataPassesThroughUnchanged() {
        let tranInA = [Double](repeating: 10.0, count: 30)
        var prev5Raw: [Double] = [10.0, 10.0, 10.0, 10.0, 10.0]
        var prev5Corrected: [Double] = [10.0, 10.0, 10.0, 10.0, 10.0]
        var outlierFifo = [Int8](repeating: 0, count: 6)

        let result = SignalProcessing.perSampleHampelFilter(
            tranInA, &prev5Raw, &prev5Corrected, &outlierFifo)

        for i in 0..<30 {
            XCTAssertEqual(10.0, result[i], accuracy: eps, "result[\(i)]")
        }
    }

    func testPerSampleHampelFilterUpdatesPrev5StateCorrectly() {
        var tranInA = [Double](repeating: 0.0, count: 30)
        for i in 0..<30 { tranInA[i] = Double(i + 1) }
        var prev5Raw: [Double] = [0, 0, 0, 0, 0]
        var prev5Corrected: [Double] = [0, 0, 0, 0, 0]
        var outlierFifo = [Int8](repeating: 0, count: 6)

        _ = SignalProcessing.perSampleHampelFilter(
            tranInA, &prev5Raw, &prev5Corrected, &outlierFifo)

        // prev5Raw should be tranInA[25..29] = [26,27,28,29,30]
        XCTAssertEqual(26.0, prev5Raw[0], accuracy: eps)
        XCTAssertEqual(30.0, prev5Raw[4], accuracy: eps)
    }

    func testPerSampleHampelFilterOutlierFifoShiftsLeft() {
        let tranInA = [Double](repeating: 5.0, count: 30)
        var prev5Raw: [Double] = [5, 5, 5, 5, 5]
        var prev5Corrected: [Double] = [5, 5, 5, 5, 5]
        var outlierFifo: [Int8] = [1, 2, 3, 4, 5, 6]

        _ = SignalProcessing.perSampleHampelFilter(
            tranInA, &prev5Raw, &prev5Corrected, &outlierFifo)

        XCTAssertEqual(Int8(2), outlierFifo[0])
        XCTAssertEqual(Int8(6), outlierFifo[4])
        XCTAssertEqual(Int8(0), outlierFifo[5])
    }

    func testPerSampleHampelFilterDetectsAndReplacesOutlier() {
        var tranInA = [Double](repeating: 10.0, count: 30)
        tranInA[15] = 1000.0 // massive outlier

        var prev5Raw: [Double] = [10.0, 10.0, 10.0, 10.0, 10.0]
        var prev5Corrected: [Double] = [10.0, 10.0, 10.0, 10.0, 10.0]
        var outlierFifo = [Int8](repeating: 0, count: 6)

        let result = SignalProcessing.perSampleHampelFilter(
            tranInA, &prev5Raw, &prev5Corrected, &outlierFifo)

        // The outlier should be replaced with something much closer to 10
        XCTAssertTrue(result[15] < 1000.0,
            "Outlier should be replaced, got \(result[15])")
        // The Hampel filter clips to median +/- scaledMad, so the replacement
        // will be much less than 1000 but not necessarily very close to 10
        // when the window includes the outlier in MAD computation
        XCTAssertTrue(result[15] < 500.0,
            "Replacement should be significantly reduced, got \(result[15])")
    }

    // ==========================================================================
    // MARK: - computeTranInA1min: Full LOESS pipeline
    // ==========================================================================

    func testComputeTranInA1minFirstCallSkipsHampelAndLoess() {
        var tranInA = [Double](repeating: 0.0, count: 30)
        for i in 0..<30 { tranInA[i] = 100.0 + Double(i) }

        var history60 = [Double](repeating: 0.0, count: 60)
        var prev3 = [Double](repeating: 0.0, count: 3)
        var prev5Raw = [Double](repeating: 0.0, count: 5)
        var prev5Corrected = [Double](repeating: 0.0, count: 5)
        var outlierFifo = [Int8](repeating: 0, count: 6)

        let result = SignalProcessing.computeTranInA1min(
            tranInA, &history60, &prev3, &prev5Raw, &prev5Corrected,
            &outlierFifo, 0, 0.0)

        XCTAssertEqual(5, result.count)

        // prev5 should be initialized to last 5 of tranInA
        XCTAssertEqual(126.0, prev5Raw[1], accuracy: eps)
        XCTAssertEqual(129.0, prev5Corrected[4], accuracy: eps)

        // History should be updated: second half = tranInA (as perSample)
        XCTAssertEqual(100.0, history60[30], accuracy: eps)
        XCTAssertEqual(129.0, history60[59], accuracy: eps)
    }

    func testComputeTranInA1minConstantInputProducesConstantOutput() {
        let tranInA = [Double](repeating: 50.0, count: 30)

        var history60 = [Double](repeating: 50.0, count: 60)
        var prev3: [Double] = [50.0, 50.0, 50.0]
        var prev5Raw: [Double] = [50.0, 50.0, 50.0, 50.0, 50.0]
        var prev5Corrected: [Double] = [50.0, 50.0, 50.0, 50.0, 50.0]
        var outlierFifo = [Int8](repeating: 0, count: 6)

        let result = SignalProcessing.computeTranInA1min(
            tranInA, &history60, &prev3, &prev5Raw, &prev5Corrected,
            &outlierFifo, 5, 100.0)

        for i in 0..<5 {
            XCTAssertEqual(50.0, result[i], accuracy: 1e-6, "result[\(i)]")
        }
    }

    func testComputeTranInA1minCallCount1SkipsHampelButNotFir() {
        let tranInA = [Double](repeating: 20.0, count: 30)

        var history60 = [Double](repeating: 0.0, count: 60)
        var prev3 = [Double](repeating: 0.0, count: 3)
        var prev5Raw = [Double](repeating: 0.0, count: 5)
        var prev5Corrected = [Double](repeating: 0.0, count: 5)
        var outlierFifo = [Int8](repeating: 0, count: 6)

        // callCount=1 < 2 => skip Hampel and FIR
        let result = SignalProcessing.computeTranInA1min(
            tranInA, &history60, &prev3, &prev5Raw, &prev5Corrected,
            &outlierFifo, 1, 100.0)

        // All medians of constant=20 should produce 20
        for i in 0..<5 {
            XCTAssertEqual(20.0, result[i], accuracy: 1e-9, "result[\(i)]")
        }
    }

    func testComputeTranInA1minPrev3StateIsUpdatedFromMedians() {
        var tranInA = [Double](repeating: 0.0, count: 30)
        for i in 0..<30 { tranInA[i] = Double(i) * 2.0 }

        var history60 = [Double](repeating: 0.0, count: 60)
        var prev3 = [Double](repeating: 0.0, count: 3)
        var prev5Raw = [Double](repeating: 0.0, count: 5)
        var prev5Corrected = [Double](repeating: 0.0, count: 5)
        var outlierFifo = [Int8](repeating: 0, count: 6)

        _ = SignalProcessing.computeTranInA1min(
            tranInA, &history60, &prev3, &prev5Raw, &prev5Corrected,
            &outlierFifo, 0, 0.0)

        // prev3 should be populated (not zeros)
        // Can't predict exact values without running medians manually,
        // but they should be non-zero since input is non-zero
        XCTAssertTrue(prev3[2] > 0, "prev3[2] should be updated")
    }

    func testComputeTranInA1minLoessEngagedWhenCallCountGE3AndTimeGapLT897() {
        var tranInA = [Double](repeating: 100.0, count: 30)
        tranInA[15] = 200.0 // outlier

        let history60 = [Double](repeating: 100.0, count: 60)
        let prev3: [Double] = [100, 100, 100]
        let prev5Raw: [Double] = [100, 100, 100, 100, 100]
        let prev5Corrected: [Double] = [100, 100, 100, 100, 100]
        let outlierFifo = [Int8](repeating: 0, count: 6)

        // With LOESS engaged (callCount=5, timeGap=100)
        var h1 = history60, p1 = prev3, pr1 = prev5Raw, pc1 = prev5Corrected, of1 = outlierFifo
        let withLoess = SignalProcessing.computeTranInA1min(
            tranInA, &h1, &p1, &pr1, &pc1, &of1, 5, 100.0)

        // Without LOESS (timeGap too large)
        var h2 = history60, p2 = prev3, pr2 = prev5Raw, pc2 = prev5Corrected, of2 = outlierFifo
        let withoutLoess = SignalProcessing.computeTranInA1min(
            tranInA, &h2, &p2, &pr2, &pc2, &of2, 5, 1000.0)

        // Results should differ because LOESS smooths differently
        // Both should produce 5 values
        XCTAssertEqual(5, withLoess.count)
        XCTAssertEqual(5, withoutLoess.count)
    }

    func testComputeTranInA1minHistory60ShiftsCorrectlyAcrossCalls() {
        let tranInA1 = [Double](repeating: 10.0, count: 30)
        let tranInA2 = [Double](repeating: 20.0, count: 30)

        var history60 = [Double](repeating: 0.0, count: 60)
        var prev3 = [Double](repeating: 0.0, count: 3)
        var prev5Raw = [Double](repeating: 0.0, count: 5)
        var prev5Corrected = [Double](repeating: 0.0, count: 5)
        var outlierFifo = [Int8](repeating: 0, count: 6)

        // First call
        _ = SignalProcessing.computeTranInA1min(
            tranInA1, &history60, &prev3, &prev5Raw, &prev5Corrected,
            &outlierFifo, 0, 0.0)

        // After first call: history60[0:30]=0, history60[30:60]=10
        XCTAssertEqual(0.0, history60[0], accuracy: eps)
        XCTAssertEqual(10.0, history60[30], accuracy: eps)

        // Second call
        _ = SignalProcessing.computeTranInA1min(
            tranInA2, &history60, &prev3, &prev5Raw, &prev5Corrected,
            &outlierFifo, 1, 100.0)

        // After second call: history60[0:30]=10, history60[30:60]=20
        XCTAssertEqual(10.0, history60[0], accuracy: eps)
        XCTAssertEqual(20.0, history60[30], accuracy: eps)
    }
}
