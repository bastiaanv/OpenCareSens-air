// CalibrationLog.swift
// Calibration log entry — one per BG calibration event (104 bytes in C).
// Maps to air1_opcal4_cal_log_t.

import Foundation

/// Calibration log entry for one BG calibration event.
public final class CalibrationLog: Codable {
    public var group: Int = 0
    public var bgTime: Int64 = 0
    public var bgSeq: Double = 0.0
    public var cgSeq1m: Double = 0.0
    public var cgIdx: Int = 0
    public var bgUser: Double = 0.0
    public var cslopePrev: Double = 0.0
    public var cyceptPrev: Double = 0.0
    public var bgValid: Int = 0
    public var bgCal: Double = 0.0
    public var cgCal: Double = 0.0
    public var cslopeNew: Double = 0.0
    public var cyceptNew: Double = 0.0
    public var inlierFlg: Int = 0

    public init() {}
}
