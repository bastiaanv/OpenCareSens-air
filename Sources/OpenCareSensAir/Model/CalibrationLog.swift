//
//  CalibrationLog.swift
//  OpenCareSensAir
//
//  Calibration log entry — one per BG calibration event (104 bytes in C).
//  Maps to air1_opcal4_cal_log_t.
//

import Foundation

public final class CalibrationLog: Codable {
    private static let serialVersionUID = 1

    public var group: Int
    public var bgTime: Int64
    public var bgSeq: Double
    public var cgSeq1m: Double
    public var cgIdx: Int
    public var bgUser: Double
    public var cslopePrev: Double
    public var cyceptPrev: Double
    public var bgValid: Int
    public var bgCal: Double
    public var cgCal: Double
    public var cslopeNew: Double
    public var cyceptNew: Double
    public var inlierFlg: Int

    public init() {
        group = 0
        bgTime = 0
        bgSeq = 0.0
        cgSeq1m = 0.0
        cgIdx = 0
        bgUser = 0.0
        cslopePrev = 0.0
        cyceptPrev = 0.0
        bgValid = 0
        bgCal = 0.0
        cgCal = 0.0
        cslopeNew = 0.0
        cyceptNew = 0.0
        inlierFlg = 0
    }
}
