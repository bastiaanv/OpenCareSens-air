//
//  CgmInput.swift
//  OpenCareSensAir
//
//  Per-reading CGM input — raw sensor data for one measurement (74 bytes packed in C).
//  Maps to air1_opcal4_cgm_input_t.
//

import Foundation

public final class CgmInput {
    public var seqNumber: Int
    public var measurementTimeStandard: Int64
    public var workout: [Int]
    public var temperature: Double

    public init() {
        seqNumber = 0
        measurementTimeStandard = 0
        workout = Array(repeating: 0, count: 30)
        temperature = 0.0
    }
}
