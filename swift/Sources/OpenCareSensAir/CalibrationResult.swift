// CalibrationResult.swift
// Immutable result of calibrating one CGM reading.

/// Immutable result of calibrating one CGM reading.
public struct CalibrationResult {
    public let glucoseMgdl: Double
    public let trendRate: Double
    public let errorCode: Int
    public let stage: Int
    public let calAvailableFlag: Int
    public let smoothedGlucose: [Double]
    public let smoothedSeq: [Int]
    public let smoothedFixedFlag: [Int]

    public init(glucoseMgdl: Double, trendRate: Double, errorCode: Int,
                stage: Int, calAvailableFlag: Int,
                smoothedGlucose: [Double], smoothedSeq: [Int],
                smoothedFixedFlag: [Int]) {
        self.glucoseMgdl = glucoseMgdl
        self.trendRate = trendRate
        self.errorCode = errorCode
        self.stage = stage
        self.calAvailableFlag = calAvailableFlag
        self.smoothedGlucose = smoothedGlucose
        self.smoothedSeq = smoothedSeq
        self.smoothedFixedFlag = smoothedFixedFlag
    }

    /// Calibrated glucose value in mmol/L (mg/dL / 18.0182).
    public var glucoseMmol: Double { glucoseMgdl / 18.0182 }

    /// Whether this reading has any error flags set.
    public var hasError: Bool { errorCode != 0 }

    /// Whether this reading produced a valid, usable glucose value (40-500 mg/dL, no errors).
    public var isValid: Bool { errorCode == 0 && glucoseMgdl >= 40.0 && glucoseMgdl <= 500.0 }

    /// Whether the trend rate has been computed and is available.
    public var isTrendAvailable: Bool {
        !trendRate.isNaN && !trendRate.isInfinite && trendRate != 100.0
    }

    /// Whether calibration data is available for this reading.
    public var isCalibrationAvailable: Bool { calAvailableFlag != 0 }

    public var description: String {
        let validStr = isValid ? "true" : "false"
        return String(format: "CalibrationResult{glucose=%.1f mg/dL, trend=%.2f mg/dL/min, error=0x%02X, stage=%d, valid=\(validStr)}",
                      glucoseMgdl, trendRate, errorCode, stage)
    }
}
