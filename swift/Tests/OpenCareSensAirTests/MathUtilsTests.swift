import XCTest
@testable import OpenCareSensAir

/// Tests for MathUtils — converted from the Java JUnit 5 MathUtilsTest.
/// Each group covers one function group.
final class MathUtilsTests: XCTestCase {

    private static let eps = 1e-9

    // ---------------------------------------------------------------
    // Group 1: mathRound, mathCeil, mathRoundDigits
    // ---------------------------------------------------------------

    // MARK: - MathRoundTest

    func testMathRoundPositiveHalfUp() {
        XCTAssertEqual(3.0, MathUtils.mathRound(2.5))
        XCTAssertEqual(3.0, MathUtils.mathRound(2.7))
        XCTAssertEqual(2.0, MathUtils.mathRound(2.3))
    }

    func testMathRoundNegativeHalfDown() {
        XCTAssertEqual(-3.0, MathUtils.mathRound(-2.5))
        XCTAssertEqual(-3.0, MathUtils.mathRound(-2.7))
        XCTAssertEqual(-2.0, MathUtils.mathRound(-2.3))
    }

    func testMathRoundZero() {
        XCTAssertEqual(0.0, MathUtils.mathRound(0.0))
    }

    func testMathRoundReturnsNanForNan() {
        XCTAssertTrue(MathUtils.mathRound(.nan).isNaN)
    }

    // MARK: - MathRoundEdgeCaseTest

    func testMathRoundExtremelyLargeValueNearLongMaxValue() {
        let huge = Double(Int64.max)
        let result = MathUtils.mathRound(huge)
        XCTAssertTrue(result.isFinite, "mathRound of huge value must be finite")

        let veryHuge = 1e18
        let result2 = MathUtils.mathRound(veryHuge)
        XCTAssertEqual(1e18, result2, accuracy: 1.0)
    }

    func testMathRoundExtremelyLargeNegativeValue() {
        let result = MathUtils.mathRound(-1e18)
        XCTAssertEqual(-1e18, result, accuracy: 1.0)
    }

    // MARK: - MathCeilTest

    func testMathCeilPositive() {
        XCTAssertEqual(3.0, MathUtils.mathCeil(2.1))
        XCTAssertEqual(3.0, MathUtils.mathCeil(2.9))
    }

    func testMathCeilExactInteger() {
        XCTAssertEqual(3.0, MathUtils.mathCeil(3.0))
    }

    func testMathCeilNegative() {
        // C code: (int)(long long)(-2.1) = -2, since -2.1 > 0 is false, no increment
        XCTAssertEqual(-2.0, MathUtils.mathCeil(-2.1))
        XCTAssertEqual(-2.0, MathUtils.mathCeil(-2.9))
    }

    func testMathCeilReturnsNanForNan() {
        XCTAssertTrue(MathUtils.mathCeil(.nan).isNaN)
    }

    // MARK: - MathRoundDigitsTest

    func testMathRoundDigitsRoundsToTwoDecimalPlaces() {
        XCTAssertEqual(314, MathUtils.mathRoundDigits(3.14159, 2))
    }

    func testMathRoundDigitsRoundsToZeroDecimalPlaces() {
        XCTAssertEqual(3, MathUtils.mathRoundDigits(3.14, 0))
    }

    func testMathRoundDigitsRoundsNegativeValue() {
        XCTAssertEqual(-314, MathUtils.mathRoundDigits(-3.14159, 2))
    }

    func testMathRoundDigitsClampsLargePositive() {
        XCTAssertEqual(Int64.max, MathUtils.mathRoundDigits(1e19, 2))
    }

    func testMathRoundDigitsClampsLargeNegative() {
        XCTAssertEqual(Int64.min, MathUtils.mathRoundDigits(-1e19, 2))
    }

    // ---------------------------------------------------------------
    // Group 2: mathMean, mathStd
    // ---------------------------------------------------------------

    // MARK: - MathMeanTest

    func testMathMeanComputesMean() {
        XCTAssertEqual(2.0, MathUtils.mathMean([1, 2, 3]), accuracy: Self.eps)
    }

    func testMathMeanSkipsNan() {
        XCTAssertEqual(2.5, MathUtils.mathMean([1, .nan, 4]), accuracy: Self.eps)
    }

    func testMathMeanReturnsNanForEmpty() {
        XCTAssertTrue(MathUtils.mathMean([Double]()).isNaN)
    }

    func testMathMeanReturnsNanForAllNan() {
        XCTAssertTrue(MathUtils.mathMean([.nan, .nan]).isNaN)
    }

    // MARK: - MathStdTest

    func testMathStdComputesSampleStd() {
        // {2, 4, 4, 4, 5, 5, 7, 9} -> mean=5, var=32/7, std=sqrt(32/7)
        let data: [Double] = [2, 4, 4, 4, 5, 5, 7, 9]
        XCTAssertEqual((32.0 / 7.0).squareRoot(), MathUtils.mathStd(data), accuracy: Self.eps)
    }

    func testMathStdReturnsZeroForSingleElement() {
        XCTAssertEqual(0.0, MathUtils.mathStd([42.0]))
    }

    func testMathStdReturnsNanForEmpty() {
        XCTAssertTrue(MathUtils.mathStd([Double]()).isNaN)
    }

    func testMathStdNanInArrayPropagates() {
        // NaN in the array affects the mean, which propagates through
        let data: [Double] = [1.0, 2.0, .nan, 4.0]
        let result = MathUtils.mathStd(data)
        // mathMean skips NaN (returns mean of {1,2,4}=2.333...)
        // but mathStd does NOT skip NaN: buf[2]-mean = NaN-2.333 = NaN
        // sumSq += NaN => NaN, sqrt(NaN) = NaN
        XCTAssertTrue(result.isNaN, "mathStd with NaN in array should produce NaN")
    }

    // ---------------------------------------------------------------
    // Group 3: mathMin, mathMax
    // ---------------------------------------------------------------

    // MARK: - MathMinTest

    func testMathMinFindsMinimum() {
        XCTAssertEqual(1.0, MathUtils.mathMin([3, 1, 2]), accuracy: Self.eps)
    }

    func testMathMinSkipsNan() {
        XCTAssertEqual(1.0, MathUtils.mathMin([.nan, 1, 2]), accuracy: Self.eps)
    }

    func testMathMinReturnsNanForEmpty() {
        XCTAssertTrue(MathUtils.mathMin([Double]()).isNaN)
    }

    func testMathMinReturnsNanForAllNan() {
        XCTAssertTrue(MathUtils.mathMin([.nan]).isNaN)
    }

    // MARK: - MathMaxTest

    func testMathMaxFindsMaximum() {
        XCTAssertEqual(3.0, MathUtils.mathMax([3, 1, 2]), accuracy: Self.eps)
    }

    func testMathMaxSkipsNan() {
        XCTAssertEqual(2.0, MathUtils.mathMax([.nan, 1, 2]), accuracy: Self.eps)
    }

    func testMathMaxReturnsNanForAllNan() {
        XCTAssertTrue(MathUtils.mathMax([.nan]).isNaN)
    }

    // ---------------------------------------------------------------
    // Group 4: mathMedian, quickSelect, quickMedian
    // ---------------------------------------------------------------

    // MARK: - MathMedianTest

    func testMathMedianOfOddCount() {
        XCTAssertEqual(2.0, MathUtils.mathMedian([3, 1, 2]), accuracy: Self.eps)
    }

    func testMathMedianOfEvenCount() {
        XCTAssertEqual(2.5, MathUtils.mathMedian([3, 1, 2, 4]), accuracy: Self.eps)
    }

    func testMathMedianOfSingle() {
        XCTAssertEqual(42.0, MathUtils.mathMedian([42]), accuracy: Self.eps)
    }

    func testMathMedianReturnsNanForEmpty() {
        XCTAssertTrue(MathUtils.mathMedian([Double]()).isNaN)
    }

    // MARK: - QuickSelectTest

    func testQuickSelectFindsKthSmallest() {
        var arr: [Double] = [5, 3, 1, 4, 2]
        XCTAssertEqual(1.0, MathUtils.quickSelect(&arr, 5, 1), accuracy: Self.eps)
    }

    func testQuickSelectFindsMedianElement() {
        var arr: [Double] = [5, 3, 1, 4, 2]
        XCTAssertEqual(3.0, MathUtils.quickSelect(&arr, 5, 3), accuracy: Self.eps)
    }

    func testQuickSelectFindsLargest() {
        var arr: [Double] = [5, 3, 1, 4, 2]
        XCTAssertEqual(5.0, MathUtils.quickSelect(&arr, 5, 5), accuracy: Self.eps)
    }

    func testQuickSelectSingleElement() {
        var arr: [Double] = [7.0]
        XCTAssertEqual(7.0, MathUtils.quickSelect(&arr, 1, 1), accuracy: Self.eps)
    }

    // MARK: - QuickMedianTest

    func testQuickMedianSmallArrayUsesMedian() {
        // n < 30 -> delegates to mathMedian
        let arr: [Double] = [5, 3, 1, 4, 2]
        XCTAssertEqual(3.0, MathUtils.quickMedian(arr, 5), accuracy: Self.eps)
    }

    func testQuickMedianLargeOddArray() {
        // 31 elements: 1..31, median should be 16
        var arr = [Double](repeating: 0.0, count: 31)
        for i in 0..<31 { arr[i] = Double(i + 1) }
        XCTAssertEqual(16.0, MathUtils.quickMedian(arr, 31), accuracy: Self.eps)
    }

    func testQuickMedianLargeEvenArray() {
        // 30 elements: 1..30, median should be 15.5
        var arr = [Double](repeating: 0.0, count: 30)
        for i in 0..<30 { arr[i] = Double(i + 1) }
        XCTAssertEqual(15.5, MathUtils.quickMedian(arr, 30), accuracy: Self.eps)
    }

    func testQuickMedianReturnsNanForEmpty() {
        XCTAssertTrue(MathUtils.quickMedian([Double](), 0).isNaN)
    }

    // ---------------------------------------------------------------
    // Group 5: calcPercentile, fTrimmedMean
    // ---------------------------------------------------------------

    // MARK: - CalcPercentileTest

    func testCalcPercentile50IsMedian() {
        let arr: [Double] = [1, 2, 3, 4, 5]
        XCTAssertEqual(3.0, MathUtils.calcPercentile(arr, 5, 50), accuracy: Self.eps)
    }

    func testCalcPercentile0ReturnsMin() {
        let arr: [Double] = [5, 1, 3]
        XCTAssertEqual(1.0, MathUtils.calcPercentile(arr, 3, 0), accuracy: Self.eps)
    }

    func testCalcPercentile100ReturnsMax() {
        let arr: [Double] = [5, 1, 3]
        XCTAssertEqual(5.0, MathUtils.calcPercentile(arr, 3, 100), accuracy: Self.eps)
    }

    func testCalcPercentileFiltersNanAndInf() {
        let arr: [Double] = [.nan, 1, .infinity, 3, 5]
        // After filter: {1, 3, 5}, percentile 50 -> rank = 50*0.01*3+0.5=2.0 -> (int)2.0=2 -> quick_select(2)=3
        XCTAssertEqual(3.0, MathUtils.calcPercentile(arr, 5, 50), accuracy: Self.eps)
    }

    func testCalcPercentileReturnsNanForAllNan() {
        XCTAssertTrue(MathUtils.calcPercentile([.nan], 1, 50).isNaN)
    }

    // MARK: - FTrimmedMeanTest

    func testFTrimmedMeanWithThreshold() {
        // 10 elements, th=10 -> percentile(10) and percentile(90)
        let arr: [Double] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        let result = MathUtils.fTrimmedMean(arr, 10, 10)
        // percentile(10): rank = 10*0.01*10+0.5 = 1.5 -> (int)1.5=1 -> qs(1)=1
        // percentile(90): rank = 90*0.01*10+0.5 = 9.5 -> (int)9.5=9 -> qs(9)=9
        // Values >= 1 and <= 9: 1..9, mean = 5.0
        XCTAssertEqual(5.0, result, accuracy: Self.eps)
    }

    func testFTrimmedMeanFallsBackToMeanWhenLoEqualsHi() {
        let arr: [Double] = [5, 5, 5]
        XCTAssertEqual(5.0, MathUtils.fTrimmedMean(arr, 3, 10), accuracy: Self.eps)
    }

    // ---------------------------------------------------------------
    // Group 6: eliminatePeak, deleteElement
    // ---------------------------------------------------------------

    // MARK: - EliminatePeakTest

    func testEliminatePeakReplacesOutliersWithMean() {
        var inArr = [Double](repeating: 10.0, count: 30)
        inArr[0] = 1000.0 // outlier

        let out = MathUtils.eliminatePeak(inArr)
        let mean = MathUtils.mathMean(inArr, 30)
        XCTAssertEqual(mean, out[0], accuracy: Self.eps) // outlier replaced
        XCTAssertEqual(10.0, out[1], accuracy: Self.eps) // normal value kept
    }

    func testEliminatePeakKeepsValuesWithinRange() {
        var inArr = [Double](repeating: 0.0, count: 30)
        for i in 0..<30 { inArr[i] = Double(i) }
        let out = MathUtils.eliminatePeak(inArr)
        // Mean ~14.5, std ~8.8, range ~[-3.1, 32.1] -> all values within
        for i in 0..<30 {
            XCTAssertEqual(Double(i), out[i], accuracy: Self.eps)
        }
    }

    // MARK: - DeleteElementTest

    func testDeleteElementDeletesMiddleElement() {
        var arr: [Double] = [1, 2, 3, 4, 5, 0, 0, 0]
        let newCount = MathUtils.deleteElement(&arr, 5, 2)
        XCTAssertEqual(4, newCount)
        XCTAssertEqual(1.0, arr[0], accuracy: Self.eps)
        XCTAssertEqual(2.0, arr[1], accuracy: Self.eps)
        XCTAssertEqual(4.0, arr[2], accuracy: Self.eps)
        XCTAssertEqual(5.0, arr[3], accuracy: Self.eps)
    }

    func testDeleteElementDeletesFirstElement() {
        var arr: [Double] = [1, 2, 3, 0, 0]
        let newCount = MathUtils.deleteElement(&arr, 3, 0)
        XCTAssertEqual(2, newCount)
        XCTAssertEqual(2.0, arr[0], accuracy: Self.eps)
        XCTAssertEqual(3.0, arr[1], accuracy: Self.eps)
    }

    func testDeleteElementNoOpForOutOfRange() {
        var arr: [Double] = [1, 2, 3]
        let newCount = MathUtils.deleteElement(&arr, 3, 5)
        XCTAssertEqual(3, newCount)
    }

    func testDeleteElementNoOpForZeroCount() {
        var arr: [Double] = [1]
        let newCount = MathUtils.deleteElement(&arr, 0, 0)
        XCTAssertEqual(0, newCount)
    }

    // ---------------------------------------------------------------
    // Group 7: fitSimpleRegression, fRsq, solveLinear
    // ---------------------------------------------------------------

    // MARK: - FitSimpleRegressionTest

    func testFitSimpleRegressionPerfectLinearFit() {
        let x: [Double] = [1, 2, 3, 4, 5]
        let y: [Double] = [2, 4, 6, 8, 10] // y = 2x
        let result = MathUtils.fitSimpleRegression(x, y, 5)
        XCTAssertEqual(2.0, result.slope, accuracy: Self.eps)
        XCTAssertEqual(0.0, result.intercept, accuracy: Self.eps)
    }

    func testFitSimpleRegressionWithIntercept() {
        let x: [Double] = [1, 2, 3]
        let y: [Double] = [3, 5, 7] // y = 2x + 1
        let result = MathUtils.fitSimpleRegression(x, y, 3)
        XCTAssertEqual(2.0, result.slope, accuracy: Self.eps)
        XCTAssertEqual(1.0, result.intercept, accuracy: Self.eps)
    }

    func testFitSimpleRegressionSkipsNanPairs() {
        let x: [Double] = [1, .nan, 3]
        let y: [Double] = [2, 4, 6] // only (1,2) and (3,6) used -> y = 2x
        let result = MathUtils.fitSimpleRegression(x, y, 3)
        XCTAssertEqual(2.0, result.slope, accuracy: Self.eps)
        XCTAssertEqual(0.0, result.intercept, accuracy: Self.eps)
    }

    func testFitSimpleRegressionReturnsNanForTooFewPoints() {
        let x: [Double] = [1]
        let y: [Double] = [2]
        let result = MathUtils.fitSimpleRegression(x, y, 1)
        XCTAssertTrue(result.slope.isNaN)
        XCTAssertTrue(result.intercept.isNaN)
    }

    func testFitSimpleRegressionReturnsNanForConstantX() {
        let x: [Double] = [5, 5, 5]
        let y: [Double] = [1, 2, 3]
        let result = MathUtils.fitSimpleRegression(x, y, 3)
        XCTAssertTrue(result.slope.isNaN)
    }

    // MARK: - FRsqTest

    func testFRsqPerfectFitReturnsOne() {
        let x: [Double] = [1, 2, 3, 4, 5]
        let y: [Double] = [2, 4, 6, 8, 10]
        XCTAssertEqual(1.0, MathUtils.fRsq(x, y, 5, 2.0, 0.0), accuracy: Self.eps)
    }

    func testFRsqReturnsNanForTooFewPoints() {
        XCTAssertTrue(MathUtils.fRsq([1], [2], 1, 1.0, 0.0).isNaN)
    }

    func testFRsqReturnsNanForConstantY() {
        let x: [Double] = [1, 2, 3]
        let y: [Double] = [5, 5, 5]
        XCTAssertTrue(MathUtils.fRsq(x, y, 3, 0.0, 5.0).isNaN)
    }

    // MARK: - SolveLinearTest

    func testSolveLinearSolvesSimpleSystem() {
        // x + y = 3, x - y = 1 -> x=2, y=1
        // [1 1; 1 -1] * [x;y] = [3;1]
        let result = MathUtils.solveLinear(1, 1, 1, -1, 3, 1)
        XCTAssertEqual(2.0, result.x, accuracy: Self.eps)
        XCTAssertEqual(1.0, result.y, accuracy: Self.eps)
    }

    func testSolveLinearReturnsNanForSingularMatrix() {
        // [1 2; 2 4] is singular (det=0)
        let result = MathUtils.solveLinear(1, 2, 2, 4, 1, 1)
        XCTAssertTrue(result.x.isNaN)
        XCTAssertTrue(result.y.isNaN)
    }

    // ---------------------------------------------------------------
    // Group 8: funCompDecimals
    // ---------------------------------------------------------------

    // MARK: - FunCompDecimalsTest

    func testFunCompDecimalsEqualWhenRoundedSame() {
        // 1.005 in double is actually 1.00499999... so mathRoundDigits(1.005, 2) = 100
        XCTAssertTrue(MathUtils.funCompDecimals(1.004, 1.005, 2, 0))  // round to 2dp: 100 vs 100 -> equal
        XCTAssertTrue(MathUtils.funCompDecimals(1.004, 1.004, 2, 0))  // 100 vs 100 -> equal
    }

    func testFunCompDecimalsGreaterThan() {
        XCTAssertTrue(MathUtils.funCompDecimals(2.0, 1.0, 2, 1))
        XCTAssertFalse(MathUtils.funCompDecimals(1.0, 2.0, 2, 1))
    }

    func testFunCompDecimalsLessThan() {
        XCTAssertTrue(MathUtils.funCompDecimals(1.0, 2.0, 2, 2))
        XCTAssertFalse(MathUtils.funCompDecimals(2.0, 1.0, 2, 2))
    }

    func testFunCompDecimalsGreaterOrEqual() {
        XCTAssertTrue(MathUtils.funCompDecimals(2.0, 1.0, 2, 3))
        XCTAssertTrue(MathUtils.funCompDecimals(1.0, 1.0, 2, 3))
    }

    func testFunCompDecimalsLessOrEqual() {
        XCTAssertTrue(MathUtils.funCompDecimals(1.0, 2.0, 2, 4))
        XCTAssertTrue(MathUtils.funCompDecimals(1.0, 1.0, 2, 4))
    }

    func testFunCompDecimalsReturnsFalseForNan() {
        XCTAssertFalse(MathUtils.funCompDecimals(.nan, 1.0, 2, 0))
        XCTAssertFalse(MathUtils.funCompDecimals(1.0, .nan, 2, 0))
    }

    // ---------------------------------------------------------------
    // Group 9: calAverageWithoutMinMax
    // ---------------------------------------------------------------

    // MARK: - CalAverageWithoutMinMaxTest

    func testCalAverageWithoutMinMaxExcludesMinAndMax() {
        let arr: [Double] = [1, 2, 3, 4, 5]
        // Excludes 1 and 5, mean of {2,3,4} = 3.0
        XCTAssertEqual(3.0, MathUtils.calAverageWithoutMinMax(arr, 5), accuracy: Self.eps)
    }

    func testCalAverageWithoutMinMaxTwoElementsReturnsMean() {
        XCTAssertEqual(2.5, MathUtils.calAverageWithoutMinMax([2, 3], 2), accuracy: Self.eps)
    }

    func testCalAverageWithoutMinMaxSingleElementReturnsSelf() {
        XCTAssertEqual(7.0, MathUtils.calAverageWithoutMinMax([7], 1), accuracy: Self.eps)
    }

    func testCalAverageWithoutMinMaxNanValuesInArray() {
        // NaN is neither < min nor > max, so it stays in the sum.
        // This tests that NaN propagation is understood.
        let arr: [Double] = [1.0, .nan, 3.0, 4.0, 5.0]
        let result = MathUtils.calAverageWithoutMinMax(arr, 5)
        // min=1.0 (NaN not < 1.0), max=5.0 => sum-1-5 / 3
        // But NaN + anything = NaN, so result is NaN
        XCTAssertTrue(result.isNaN,
            "calAverageWithoutMinMax with NaN in array propagates NaN")
    }

    // ---------------------------------------------------------------
    // Group 10: applySimpleSmooth
    // ---------------------------------------------------------------

    // MARK: - ApplySimpleSmoothTest

    func testApplySimpleSmoothSmoothsAdjacentPairs() {
        var buf: [Double] = [1, 2, 3, 4, 5, 6, 7, 8]
        MathUtils.applySimpleSmooth(&buf, 8, 0.5)
        // buf[0] unchanged (i=0 skipped)
        XCTAssertEqual(1.0, buf[0], accuracy: Self.eps)
        // buf[1] = (2+3)*0.5 = 2.5
        XCTAssertEqual(2.5, buf[1], accuracy: Self.eps)
        // buf[6] = (7+8)*0.5 = 7.5
        XCTAssertEqual(7.5, buf[6], accuracy: Self.eps)
        // buf[7] unchanged (i=n-1 skipped)
        XCTAssertEqual(8.0, buf[7], accuracy: Self.eps)
    }

    func testApplySimpleSmoothNoOpForSmallArray() {
        var buf: [Double] = [1, 2, 3]
        MathUtils.applySimpleSmooth(&buf, 3, 0.5)
        XCTAssertEqual(1.0, buf[0], accuracy: Self.eps)
        XCTAssertEqual(2.0, buf[1], accuracy: Self.eps)
        XCTAssertEqual(3.0, buf[2], accuracy: Self.eps)
    }

    func testApplySimpleSmoothNoOpForLowStd() {
        var buf: [Double] = [5, 5, 5, 5, 5, 5, 5, 5]
        MathUtils.applySimpleSmooth(&buf, 8, 0.5)
        for v in buf {
            XCTAssertEqual(5.0, v, accuracy: Self.eps)
        }
    }
}
