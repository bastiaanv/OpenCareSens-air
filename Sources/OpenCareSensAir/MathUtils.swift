import Foundation

/// Stateless math utility functions ported from C (math_utils.c).
/// All methods are static. Behavior matches the C implementation exactly.
public enum MathUtils {
    
    // MARK: - Basic math
    
    /// Round to nearest integer, half-away-from-zero.
    /// Do NOT use Swift's `.rounded()` or `Foundation.round()` — they use banker's rounding.
    public static func mathRound(_ x: Double) -> Double {
        if Double.isNaN(x) { return Double.nan }
        let adj: Double = (x < 0.0) ? -0.5 : 0.5
        return Double(truncating: Int64(x + adj))
    }
    
    /// Ceiling function matching C truncation semantics.
    /// Do NOT use Swift's `ceil()` from Foundation — different behavior for negatives.
    public static func mathCeil(_ x: Double) -> Double {
        if Double.isNaN(x) { return Double.nan }
        let trunc = Int64(x)
        if x > 0.0 && Double(trunc) != x {
            trunc += 1
        }
        return Double(trunc)
    }
    
    /// Round x to numDigits decimal places, return as Int64. Clamps on overflow.
    public static func mathRoundDigits(_ x: Double, numDigits: Int) -> Int64 {
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
        return mathMean(buf, n: buf.count)
    }
    
    /// NaN-aware arithmetic mean of first n elements.
    public static func mathMean(_ buf: [Double], n: Int) -> Double {
        if n == 0 { return Double.nan }
        var sum: Double = 0.0
        var valid = 0
        for i in 0..<n {
            if Double.isNaN(buf[i]) { continue }
            sum += buf[i]
            valid += 1
        }
        if valid == 0 { return Double.nan }
        return sum / Double(valid)
    }
    
    /// Sample standard deviation (N-1 denominator).
    public static func mathStd(_ buf: [Double]) -> Double {
        return mathStd(buf, n: buf.count)
    }
    
    /// Sample standard deviation of first n elements.
    public static func mathStd(_ buf: [Double], n: Int) -> Double {
        if n == 0 { return Double.nan }
        if n == 1 { return 0.0 }
        let mean = mathMean(buf, n: n)
        var sumSq: Double = 0.0
        for i in 0..<n {
            let d = buf[i] - mean
            sumSq += d * d
        }
        return sqrt(sumSq / Double(n - 1))
    }
    
    // MARK: - Extremes
    
    /// Maximum of first len elements, skipping NaN.
    public static func mathMax(_ arr: [Double]) -> Double {
        return mathMax(arr, len: arr.count)
    }
    
    public static func mathMax(_ arr: [Double], len: Int) -> Double {
        var best: Double = 0.0
        var found = false
        for i in 0..<len {
            if Double.isNaN(arr[i]) { continue }
            if !found || arr[i] > best {
                best = arr[i]
                found = true
            }
        }
        return found ? best : Double.nan
    }
    
    /// Minimum of first len elements, skipping NaN.
    public static func mathMin(_ arr: [Double]) -> Double {
        return mathMin(arr, len: arr.count)
    }
    
    public static func mathMin(_ arr: [Double], len: Int) -> Double {
        if len == 0 { return Double.nan }
        var best: Double = 0.0
        var found = false
        for i in 0..<len {
            if Double.isNaN(arr[i]) { continue }
            if !found || arr[i] < best {
                best = arr[i]
                found = true
            }
        }
        return found ? best : Double.nan
    }
    
    // MARK: - Order statistics
    
    /// Median via sort (for small arrays, up to 300 elements).
    public static func mathMedian(_ arr: [Double]) -> Double {
        return mathMedian(arr, n: arr.count)
    }
    
    public static func mathMedian(_ arr: [Double], n: Int) -> Double {
        if n == 0 { return Double.nan }
        let use = min(n, 300)
        var tmp = Array(arr.prefix(use))
        tmp.sort { $0 < $1 }
        if use % 2 == 1 { return tmp[use / 2] }
        return (tmp[use / 2 - 1] + tmp[use / 2]) * 0.5
    }
    
    /// QuickSelect: find k-th smallest element (1-indexed).
    /// Uses median-of-5 pivot selection matching the C implementation.
    /// Note: modifies the input array.
    public static func quickSelect(_ arr: [Double], n: Int, k: Int) -> Double {
        if n == 1 { return arr[0] }
        
        // Median-of-5 pivot selection
        var pivots = [Double](repeating: 0.0, count: 5)
        pivots[0] = arr[0]
        pivots[1] = arr[n - 1]
        pivots[2] = arr[n >> 2]
        pivots[3] = arr[(n & 0x3ffffffe) >> 1] // n/2 rounded down to even
        pivots[4] = arr[((n >> 2)) * 3]
        let pivot = mathMedian(pivots, n: 5)
        
        var less = [Double](repeating: 0.0, count: n)
        var greater = [Double](repeating: 0.0, count: n)
        var nLess = 0, nGreater = 0, nEqual = 0
        
        for i in 0..<n {
            if arr[i] < pivot { less[nLess] = arr[i]; nLess += 1 }
            else if arr[i] > pivot { greater[nGreater] = arr[i]; nGreater += 1 }
            else { nEqual += 1 }
        }
        
        if k <= nLess {
            return quickSelect(less, n: nLess, k: k)
        } else if k <= nLess + nEqual {
            return pivot
        } else {
            for i in 0..<nGreater { arr[i] = greater[i] }
            return quickSelect(arr, n: nGreater, k: k - nLess - nEqual)
        }
    }
    
    /// Median: quickSelect for large arrays, mathMedian for small (<30).
    public static func quickMedian(_ arr: [Double], n: Int) -> Double {
        if n == 0 { return Double.nan }
        if n < 30 { return mathMedian(arr, n: n) }
        let half = n / 2
        if n % 2 != 0 {
            return quickSelect(arr, n: n, k: half + 1)
        }
        let a = quickSelect(arr, n: n, k: half)
        let b = quickSelect(arr, n: n, k: half + 1)
        return (a + b) * 0.5
    }
    
    // MARK: - Percentile-based
    
    /// Percentile: filters NaN/Inf, then uses quickSelect.
    public static func calcPercentile(_ arr: [Double], n: Int, percent: Int) -> Double {
        var filtered = [Double](repeating: 0.0, count: n)
        var cnt = 0
        for i in 0..<n {
            if !Double.isNaN(arr[i]) && !Double.isInfinite(arr[i]) {
                filtered[cnt] = arr[i]
                cnt += 1
            }
        }
        if cnt == 0 { return Double.nan }
        
        let rankF = Double(percent) * 0.01 * Double(cnt) + 0.5
        let rank = (rankF > 0.0) ? Int(truncating: rankF) : 0
        
        if rank == 0 { return mathMin(filtered, n: cnt) }
        if rank > cnt { rank = cnt }
        
        return quickSelect(filtered, n: cnt, k: rank)
    }
    
    /// Trimmed mean: average values between percentile(th) and percentile(100-th).
    public static func fTrimmedMean(_ data: [Double], len: Int, th: Int) -> Double {
        let lo = calcPercentile(data, n: len, percent: th)
        let hi = calcPercentile(data, n: len, percent: 100 - th)
        
        if lo == hi { return mathMean(data, n: len) }
        
        var sum: Double = 0.0
        var cnt = 0
        for i in 0..<len {
        if funCompDecimals(lo, data[i], 10, 3) &&   // data[i] >= lo
            funCompDecimals(hi, data[i], 10, 4)) {   // data[i] <= hi
                sum += data[i]
                cnt += 1
            }
        }
        if cnt == 0 { return Double.nan }
        return sum / Double(cnt)
    }
    
    // MARK: - Array manipulation
    
    /// Replace outliers outside [mean-2*std, mean+2*std] with mean. Always 30 elements.
    public static func eliminatePeak(_ inArr: [Double]) -> [Double] {
        let mean = mathMean(inArr, n: 30)
        let std = mathStd(inArr, n: 30)
        let lo = mean - 2.0 * std
        let hi = mean + 2.0 * std
        var out = [Double](repeating: 0.0, count: 30)
        for i in 0..<30 {
            out[i] = (inArr[i] < lo || inArr[i] > hi) ? mean : inArr[i]
        }
        return out
    }
    
    /// Remove element at index, shift left, return new count.
    /// Matches C void delete_element(double*, uint8_t*, uint32_t).
    public static func deleteElement(_ arr: inout [Double], count: Int, index: Int) -> Int {
        if count == 0 || index >= count { return count }
        for i in (index+1)..<count { arr[i-1] = arr[i] }
        return count - 1
    }
    
    // MARK: - Regression
    
    /// Simple linear regression: y = slope*x + intercept. NaN-aware.
    /// Returns [slope, intercept].
    public static func fitSimpleRegression(_ x: [Double], _ y: [Double], n: Int) -> [Double] {
        if n < 2 { return [Double.nan, Double.nan] }
        
        var sx: Double = 0, sy: Double = 0, sxy: Double = 0, sxx: Double = 0
        var valid = 0
        for i in 0..<n {
            if Double.isNaN(x[i]) || Double.isNaN(y[i]) { continue }
            sx += x[i]
            sy += y[i]
            sxy += x[i] * y[i]
            sxx += x[i] * x[i]
            valid += 1
        }
        
        if valid < 2 { return [Double.nan, Double.nan] }
        
        let denom = Double(valid) * sxx - sx * sx
        if abs(denom) < 1e-30 { return [Double.nan, Double.nan] }
        
        let slope = (Double(valid) * sxy - sx * sy) / denom
        let intercept = (sy - slope * sx) / Double(valid)
        return [slope, intercept]
    }
    
    /// R-squared (coefficient of determination) for a regression.
    public static func fRsq(_ x: [Double], _ y: [Double], n: Int, slope: Double, intercept: Double) -> Double {
        if n < 2 { return Double.nan }
        
        var ssTot: Double = 0, ssRes: Double = 0
        let yMean = mathMean(y, n: n)
        for i in 0..<n {
            if Double.isNaN(x[i]) || Double.isNaN(y[i]) { continue }
            let yPred = slope * x[i] + intercept
            let res = y[i] - yPred
            let tot = y[i] - yMean
            ssRes += res * res
            ssTot += tot * tot
        }
        if ssTot < 1e-30 { return Double.nan }
        return 1.0 - ssRes / ssTot
    }
    
    /// Solve 2x2 linear system using Cramer's rule.
    /// [a b; c d] * [x; y] = [e; f]
    /// Returns [x, y].
    public static func solveLinear(_ a: Double, _ b: Double, _ c: Double, _ d: Double,
                                   _ e: Double, _ f: Double) -> [Double] {
        let det = a * d - b * c
        if abs(det) < 1e-30 { return [Double.nan, Double.nan] }
        return [(e * d - b * f) / det, (a * f - e * c) / det]
    }
    
    // MARK: - Comparison utility
    
    /// Compare two doubles rounded to numDigits decimal places.
    /// metSel: 0=eq, 1=gt, 2=lt, 3=ge, 4=le
    public static func funCompDecimals(_ in1: Double, _ in2: Double, numDigits: Int, metSel: Int) -> Bool {
        if Double.isNaN(in1) || Double.isNaN(in2) { return false }
        
        let a = mathRoundDigits(in1, numDigits: numDigits)
        let b = mathRoundDigits(in2, numDigits: numDigits)
        
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
    public static func calAverageWithoutMinMax(_ arr: [Double], n: Int) -> Double {
        if n <= 2 { return mathMean(arr, n: n) }
        
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
    /// From signal_processing.c apply_simple_smooth.
    /// Modifies buffer in-place.
    public static func applySimpleSmooth(_ buffer: inout [Double], n: Int, alpha: Double) {
        if n <= 7 { return }
        
        let stdVal = mathStd(buffer, n: n)
        if stdVal < 1e-8 { return }
        
        var tmp = buffer
        for i in 1..<n-1 {
            buffer[i] = (tmp[i] + tmp[i + 1]) * 0.5
        }
    }
}


