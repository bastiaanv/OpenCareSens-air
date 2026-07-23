// CgmInput.swift
// Per-reading CGM input — raw sensor data for one measurement (74 bytes packed in C).
// Maps to air1_opcal4_cgm_input_t.

/// Per-reading CGM input containing raw sensor data.
public final class CgmInput {
    public var seqNumber: Int = 0
    public var measurementTimeStandard: Int64 = 0
    public var workout: [Int]
    public var temperature: Double = 0.0

    public init() {
        workout = Array(repeating: 0, count: 30)
    }
}
