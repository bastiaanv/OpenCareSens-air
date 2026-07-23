// MathUtils.swift
// Stateless math utility functions ported from C (math_utils.c).

import Foundation

/// Stateless math utility functions matching the C implementation exactly.
public enum MathUtils {

    // MARK: - Basic math

    /// Round to nearest integer, half-away-from-zero.
    public static func mathRound(_ x: Double) -> Double {
        if x.isNaN { return .nan }
        let adj: Double = (x < 0.0) ? -0.5 : 0.5
        return Double(Int64(x + adj))
    }

    /// Ceiling function matching C truncation semantics.
    public static func mathCeil(_ x: Double) -> Double {
        if x.isNaN { return .nan }
        let trunc = Int64(x)
        var result = Double(trunc)
        if x > 0.0 && result != x {
            result += 1.0
        }
        return result
    }

    /// Round x to numDigits decimal places, return as Int64. Clamps on overflow.
    public static func mathRoundDigits(_ x: Double, _ numDigits: Int) -> Int64 {
        let scale = pow(10.0, Double(numDigits))
        let scaled = scale * x
        if scaled >= 0.0 {
            if scaled > 9.223372036854776e+18 { return Int64.max }
            return Int64(scaled + 0.5)
        } else {
            if scaled < -9.223372036854776e+18 { return Int64.min }
            return Int64(scaled - 0.5)
        }
    }

    // MARK: - Statistics basics

    /// NaN-aware arithmetic mean.
    public static func mathMean(_ buf: [Double]) -> Double {
        mathMean(buf, buf.count)
    }

    /// NaN-aware arithmetic mean of first n elements.
    public static func mathMean(_ buf: [Double], _ n: Int) -> Double {
        if n == 0 { return .nan }
        var sum = 0.0
        var valid = 0
        for i in 0..<n {
            if buf[i].isNaN { continue }
            sum += buf[i]
            valid += 1
        }
        if valid == 0 { return .nan }
        return sum / Double(valid)
    }

    /// Sample standard deviation (N-1 denominator).
    public static func mathStd(_ buf: [Double]) -> Double {
        mathStd(buf, buf.count)
    }

    /// Sample standard deviation of first n elements.
    public static func mathStd(_ buf: [Double], _ n: Int) -> Double {
        if n == 0 { return .nan }
        if n == 1 { return 0.0 }
        let mean = mathMean(buf, n)
        var sumSq = 0.0
        for i in 0..<n {
            let d = buf[i] - mean
            sumSq += d * d
        }
        return (sumSq / Double(n - 1)).squareRoot()
    }

    // MARK: - Extremes

    /// Maximum of first len elements, skipping NaN.
    public static func mathMax(_ arr: [Double]) -> Double {
        mathMax(arr, arr.count)
    }

    public static func mathMax(_ arr: [Double], _ len: Int) -> Double {
        var best = 0.0
        var found = false
        for i in 0..<len {
            if arr[i].isNaN { continue }
            if !found || arr[i] > best {
                best = arr[i]
                found = true
            }
        }
        return found ? best : .nan
    }

    /// Minimum of first len elements, skipping NaN.
    public static func mathMin(_ arr: [Double]) -> Double {
        mathMin(arr, arr.count)
    }

    public static func mathMin(_ arr: [Double], _ len: Int) -> Double {
        if len == 0 { return .nan }
        var best = 0.0
        var found = false
        for i in 0..<len {
            if arr[i].isNaN { continue }
            if !found || arr[i] < best {
                best = arr[i]
                found = true
            }
        }
        return found ? best : .nan
    }

    // MARK: - Order statistics

    /// Median via sort (for small arrays, up to 300 elements).
    public static func mathMedian(_ arr: [Double]) -> Double {
        mathMedian(arr, arr.count)
    }

    public static func mathMedian(_ arr: [Double], _ n: Int) -> Double {
        if n == 0 { return .nan }
        let use = min(n, 300)
        var tmp = Array(arr[0..<use])
        tmp.sort()
        if use % 2 == 1 { return tmp[use / 2] }
        return (tmp[use / 2 - 1] + tmp[use / 2]) * 0.5
    }

    /// QuickSelect: find k-th smallest element (1-indexed).
    /// Uses median-of-5 pivot selection matching the C implementation.
    /// Note: may modify the input array.
    public static func quickSelect(_ arr: inout [Double], _ n: Int, _ k: Int) -> Double {
        if n == 1 { return arr[0] }

        // Median-of-5 pivot selection
        var pivots = [Double](repeating: 0.0, count: 5)
        pivots[0] = arr[0]
        pivots[1] = arr[n - 1]
        pivots[2] = arr[n >> 2]
        pivots[3] = arr[(n & 0x3ffffffe) >> 1]
        pivots[4] = arr[(n >> 2) * 3]
        let pivot = mathMedian(pivots, 5)

        var less = [Double](repeating: 0.0, count: n)
        var greater = [Double](repeating: 0.0, count: n)
        var nLess = 0, nGreater = 0, nEqual = 0

        for i in 0..<n {
            if arr[i] < pivot {
                less[nLess] = arr[i]; nLess += 1
            } else if arr[i] > pivot {
                greater[nGreater] = arr[i]; nGreater += 1
            } else {
                nEqual += 1
            }
        }

        if k <= nLess {
            return quickSelect(&less, nLess, k)
        } else if k <= nLess + nEqual {
            return pivot
        } else {
            for i in 0..<nGreater { arr[i] = greater[i] }
            return quickSelect(&arr, nGreater, k - nLess - nEqual)
        }
    }

    /// Median: quickSelect for large arrays, mathMedian for small (<30).
    public static func quickMedian(_ arr: [Double], _ n: Int) -> Double {
        if n == 0 { return .nan }
        if n < 30 { return mathMedian(arr, n) }
        let half = n / 2
        if n % 2 != 0 {
            var copy = arr
            return quickSelect(&copy, n, half + 1)
        }
        var copy1 = arr
        let a = quickSelect(&copy1, n, half)
        var copy2 = arr
        let b = quickSelect(&copy2, n, half + 1)
        return (a + b) * 0.5
    }

    // MARK: - Percentile-based

    /// Percentile: filters NaN/Inf, then uses quickSelect.
    public static func calcPercentile(_ arr: [Double], _ n: Int, _ percent: Int) -> Double {
        var filtered = [Double](repeating: 0.0, count: n)
        var cnt = 0
        for i in 0..<n {
            if !arr[i].isNaN && !arr[i].isInfinite {
                filtered[cnt] = arr[i]
                cnt += 1
            }
        }
        if cnt == 0 { return .nan }

        let rankF = Double(percent) * 0.01 * Double(cnt) + 0.5
        let rank = rankF > 0.0 ? Int(rankF) : 0

        if rank == 0 { return mathMin(filtered, cnt) }
        let rankClamped = rank > cnt ? cnt : rank

        return quickSelect(&filtered, cnt, rankClamped)
    }

    /// Trimmed mean: average values between percentile(th) and percentile(100-th).
    public static func fTrimmedMean(_ data: [Double], _ len: Int, _ th: Int) -> Double {
        let lo = calcPercentile(data, len, th)
        let hi = calcPercentile(data, len, 100 - th)

        if lo == hi { return mathMean(data, len) }

        var sum = 0.0
        var cnt = 0
        for i in 0..<len {
            if funCompDecimals(data[i], lo, 10, 3) &&   // data[i] >= lo
               funCompDecimals(data[i], hi, 10, 4) {    // data[i] <= hi
                sum += data[i]
                cnt += 1
            }
        }
        if cnt == 0 { return .nan }
        return sum / Double(cnt)
    }

    // MARK: - Array manipulation

    /// Replace outliers outside [mean-2*std, mean+2*std] with mean. Always 30 elements.
    public static func eliminatePeak(_ input: [Double]) -> [Double] {
        let mean = mathMean(input, 30)
        let std = mathStd(input, 30)
        let lo = mean - 2.0 * std
        let hi = mean + 2.0 * std
        var out = [Double](repeating: 0.0, count: 30)
        for i in 0..<30 {
            out[i] = (input[i] < lo || input[i] > hi) ? mean : input[i]
        }
        return out
    }

    /// Remove element at index, shift left, return new count.
    public static func deleteElement(_ arr: inout [Double], _ count: Int, _ index: Int) -> Int {
        if count == 0 || index >= count { return count }
        for i in index..<(count - 1) {
            arr[i] = arr[i + 1]
        }
        return count - 1
    }

    // MARK: - Regression

    /// Simple linear regression: y = slope*x + intercept. NaN-aware.
    /// Returns (slope, intercept).
    public static func fitSimpleRegression(_ x: [Double], _ y: [Double], _ n: Int) -> (slope: Double, intercept: Double) {
        if n < 2 { return (.nan, .nan) }

        var sx = 0.0, sy = 0.0, sxy = 0.0, sxx = 0.0
        var valid = 0
        for i in 0..<n {
            if x[i].isNaN || y[i].isNaN { continue }
            sx += x[i]
            sy += y[i]
            sxy += x[i] * y[i]
            sxx += x[i] * x[i]
            valid += 1
        }

        if valid < 2 { return (.nan, .nan) }

        let denom = Double(valid) * sxx - sx * sx
        if abs(denom) < 1e-30 { return (.nan, .nan) }

        let slope = (Double(valid) * sxy - sx * sy) / denom
        let intercept = (sy - slope * sx) / Double(valid)
        return (slope, intercept)
    }

    /// R-squared (coefficient of determination) for a regression.
    public static func fRsq(_ x: [Double], _ y: [Double], _ n: Int, _ slope: Double, _ intercept: Double) -> Double {
        if n < 2 { return .nan }

        var ssTot = 0.0, ssRes = 0.0
        let yMean = mathMean(y, n)
        for i in 0..<n {
            if x[i].isNaN || y[i].isNaN { continue }
            let yPred = slope * x[i] + intercept
            let res = y[i] - yPred
            let tot = y[i] - yMean
            ssRes += res * res
            ssTot += tot * tot
        }
        if ssTot < 1e-30 { return .nan }
        return 1.0 - ssRes / ssTot
    }

    /// Solve 2x2 linear system using Cramer's rule.
    /// [a b; c d] * [x; y] = [e; f]
    /// Returns (x, y).
    public static func solveLinear(_ a: Double, _ b: Double, _ c: Double, _ d: Double,
                                   _ e: Double, _ f: Double) -> (x: Double, y: Double) {
        let det = a * d - b * c
        if abs(det) < 1e-30 { return (.nan, .nan) }
        return ((e * d - b * f) / det, (a * f - e * c) / det)
    }

    // MARK: - Comparison utility

    /// Compare two doubles rounded to numDigits decimal places.
    /// metSel: 0=eq, 1=gt, 2=lt, 3=ge, 4=le
    public static func funCompDecimals(_ in1: Double, _ in2: Double, _ numDigits: Int, _ metSel: Int) -> Bool {
        if in1.isNaN || in2.isNaN { return false }

        let a = mathRoundDigits(in1, numDigits)
        let b = mathRoundDigits(in2, numDigits)

        // If either overflowed, fall back to direct double comparison
        if a == Int64.max || a == Int64.min || b == Int64.max || b == Int64.min {
            switch metSel {
            case 0: return in1 == in2
            case 1: return in1 > in2
            case 2: return in1 < in2
            case 3: return in1 >= in2
            case 4: return in1 <= in2
            default: return in1 == in2
            }
        }

        switch metSel {
        case 0: return a == b
        case 1: return a > b
        case 2: return a < b
        case 3: return a >= b
        case 4: return a <= b
        default: return a == b
        }
    }

    // MARK: - Specialty average

    /// Average excluding the single min and max values from array.
    public static func calAverageWithoutMinMax(_ arr: [Double], _ n: Int) -> Double {
        if n <= 2 { return mathMean(arr, n) }

        var mn = arr[0], mx = arr[0]
        var sum = arr[0]
        for i in 1..<n {
            sum += arr[i]
            if arr[i] < mn { mn = arr[i] }
            if arr[i] > mx { mx = arr[i] }
        }
        return (sum - mn - mx) / Double(n - 2)
    }

    // MARK: - Exponential smoothing

    /// Simple smoothing: average adjacent pairs for interior elements.
    /// Modifies buffer in-place.
    public static func applySimpleSmooth(_ buffer: inout [Double], _ n: Int, _ alpha: Double) {
        if n <= 7 { return }

        let stdVal = mathStd(buffer, n)
        if stdVal < 1e-8 { return }

        let tmp = buffer
        for i in 1..<(n - 1) {
            buffer[i] = (tmp[i] + tmp[i + 1]) * 0.5
        }
    }
}
