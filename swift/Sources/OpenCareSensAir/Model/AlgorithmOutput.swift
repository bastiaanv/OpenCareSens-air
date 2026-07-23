// AlgorithmOutput.swift
// Per-reading algorithm output (155 bytes packed in C).
// Maps to air1_opcal4_output_t.

/// Per-reading algorithm output from the calibration pipeline.
public final class AlgorithmOutput {
    public var seqNumberOriginal: Int = 0
    public var seqNumberFinal: Int = 0
    public var measurementTimeStandard: Int64 = 0
    public var workout: [Int]
    public var resultGlucose: Double = 0.0
    public var trendrate: Double = 0.0
    public var currentStage: Int = 0
    public var smoothFixedFlag: [Int]
    public var smoothSeq: [Int]
    public var smoothResultGlucose: [Double]
    public var errcode: Int = 0
    public var calAvailableFlag: Int = 0
    public var dataType: Int = 0

    public init() {
        workout = Array(repeating: 0, count: 30)
        smoothFixedFlag = Array(repeating: 0, count: 6)
        smoothSeq = Array(repeating: 0, count: 6)
        smoothResultGlucose = Array(repeating: 0.0, count: 6)
    }
}
