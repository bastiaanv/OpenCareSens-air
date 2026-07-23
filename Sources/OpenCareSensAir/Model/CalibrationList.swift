//
//  CalibrationList.swift
//  OpenCareSensAir
//
//  User calibration list — BG reference values for factory-cal override (751 bytes packed in C).
//  Passed empty for factory-calibration-only mode.
//  Maps to air1_opcal4_cal_list_t.
//

import Foundation

public final class CalibrationList {
    public var idx: [Int]
    public var value: [Double]
    public var time: [Int64]
    public var calListLength: Int
    public var calFlag: [Int]

    public init() {
        idx = Array(repeating: 0, count: 50)
        value = Array(repeating: 0.0, count: 50)
        time = Array(repeating: 0, count: 50)
        calFlag = Array(repeating: 0, count: 50)
        calListLength = 0
    }
}
