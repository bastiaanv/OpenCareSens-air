// MARK: - CalibrationResult

import Foundation

/// Immutable result of calibrating one CGM reading.
///
/// Contains the calibrated glucose value, trend rate, error information,
/// and smoothed historical glucose values. All fields are set at construction
/// time and cannot be modified.
///
/// Typical usage:
/// ```
/// let result = calibrator.processReading(seq, timestamp, adc, temp)
/// if result.isValid {
///     let glucose = result.glucoseMgdl
///     let trend = result.trendRateMgdlPerMin
/// }
/// ```
public struct CalibrationResult {
    
    /// Calibrated glucose value in mg/dL.
    ///
    /// Check `isValid` before using this value. When the reading
    /// has errors, this may be zero or unreliable.
    public let glucoseMgdl: Double
    
    /// Calibrated glucose value in mmol/L.
    ///
    /// Convenience conversion: `mg/dL / 18.0182`.
    public let glucoseMmol: Double
    
    /// Rate of glucose change in mg/dL per minute.
    ///
    /// A value of `100.0` means the trend rate is not yet available
    /// (insufficient readings). Positive values indicate rising glucose,
    /// negative values indicate falling glucose.
    public let trendRateMgdlPerMin: Double
    
    /// Error code bitmask. Zero means no error.
    ///
    /// Individual error bits:
    /// - Bit 0 (1): Contact/noise error
    /// - Bit 1 (2): Delay/slope error
    /// - Bit 2 (4): Range error
    /// - Bit 3 (8): High-frequency noise
    /// - Bit 4 (16): Calibration drift
    /// - Bit 5 (32): Communication error
    /// - Bit 6 (64): Parameter validation error
    public let errorCode: Int
    
    /// Sensor stage: 0 = warmup, 1 = steady state.
    ///
    /// During warmup (stage 0), glucose values may be less accurate.
    /// The transition to stage 1 happens after the warmup period defined
    /// in the sensor's factory calibration parameters.
    public let stage: Int
    
    /// Whether calibration data is available for this reading.
    public let calAvailableFlag: Int
    
    /// Six smoothed historical glucose values (mg/dL) from the
    /// Savitzky-Golay filter. Returns a defensive copy.
    public let smoothedGlucose: [Double]
    
    /// Sequence numbers corresponding to each smoothed glucose value.
    /// Returns a defensive copy.
    public let smoothedSeq: [Int]
    
    /// Fixed-point flags for each smoothed glucose value.
    /// Returns a defensive copy.
    public let smoothedFixedFlag: [Int]
    
    /// Whether this reading has any error flags set.
    public var hasError: Bool {
        return errorCode != 0
    }
    
    /// Whether this reading produced a valid, usable glucose value.
    ///
    /// A reading is valid when there are no errors and the glucose value
    /// falls within the sensor's operating range (40-500 mg/dL).
    public var isValid: Bool {
        return errorCode == 0
            && glucoseMgdl >= 40.0
            && glucoseMgdl <= 500.0
    }
    
    /// Whether the trend rate has been computed and is available.
    ///
    /// The trend rate requires at least 12 readings with proper spacing.
    /// Before that, `getTrendRateMgdlPerMin` returns `100.0`
    /// as a sentinel value.
    public var isTrendAvailable: Bool {
        return !Double.isNaN(trendRateMgdlPerMin)
            && !Double.isInfinite(trendRateMgdlPerMin)
            && trendRateMgdlPerMin != 100.0
    }
    
    /// Initializer for `CalibrationResult`.
    ///
    /// - Parameters:
    ///   - glucoseMgdl: Calibrated glucose value in mg/dL.
    ///   - trendRate: Rate of glucose change in mg/dL per minute.
    ///   - errorCode: Error code bitmask. Zero means no error.
    ///   - stage: Sensor stage (0 = warmup, 1 = steady state).
    ///   - calAvailableFlag: Calibration availability flag.
    ///   - smoothedGlucose: Six smoothed historical glucose values.
    ///   - smoothedSeq: Sequence numbers for each smoothed value.
    ///   - smoothedFixedFlag: Fixed-point flags for each smoothed value.
    public init(
        glucoseMgdl: Double,
        trendRate: Double,
        errorCode: Int,
        stage: Int,
        calAvailableFlag: Int,
        smoothedGlucose: [Double],
        smoothedSeq: [Int],
        smoothedFixedFlag: [Int]
    ) {
        self.glucoseMgdl = glucoseMgdl
        self.glucoseMmol = glucoseMgdl / 18.0182
        self.trendRateMgdlPerMin = trendRate
        self.errorCode = errorCode
        self.stage = stage
        self.calAvailableFlag = calAvailableFlag
        // Defensive copies for immutability
        self.smoothedGlucose = Array(smoothedGlucose)
        self.smoothedSeq = Array(smoothedSeq)
        self.smoothedFixedFlag = Array(smoothedFixedFlag)
    }
    
    /// String representation of `CalibrationResult`.
    ///
    /// Uses `Locale.US` for consistent decimal formatting.
    public var description: String {
        return String(format: "CalibrationResult{glucose=%.1f mg/dL, trend=%.2f mg/dL/min, error=0x%02X, stage=%d, valid=%@}",
                      glucoseMgdl, trendRateMgdlPerMin, errorCode, stage, isValid)
    }
}
