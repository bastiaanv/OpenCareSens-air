//
//  AlgorithmOutput.swift
//  OpenCareSensAir
//
//  Per-reading algorithm output (155 bytes packed in C).
//  Maps to air1_opcal4_output_t.
//

import Foundation

public final class AlgorithmOutput {
    public var seqNumberOriginal: Int
    public var seqNumberFinal: Int
    public var measurementTimeStandard: Int64
    public var workout: [Int]
    public var resultGlucose: Double
    public var trendrate: Double
    public var currentStage: Int
    public var smoothFixedFlag: [Int]
    public var smoothSeq: [Int]
    public var smoothResultGlucose: [Double]
    public var errcode: Int
    public var calAvailableFlag: Int
    public var dataType: Int

    public init() {
        seqNumberOriginal = 0
        seqNumberFinal = 0
        measurementTimeStandard = 0
        workout = Array(repeating: 0, count: 30)
        resultGlucose = 0.0
        trendrate = 0.0
        currentStage = 0
        smoothFixedFlag = Array(repeating: 0, count: 6)
        smoothSeq = Array(repeating: 0, count: 6)
        smoothResultGlucose = Array(repeating: 0.0, count: 6)
        errcode = 0
        calAvailableFlag = 0
        dataType = 0
    }
}
