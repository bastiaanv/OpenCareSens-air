// DebugOutput.swift
// Debug oracle output — all intermediate values for one reading (1579 bytes packed in C).
// Maps to air1_opcal4_debug_t.

import Foundation

/// Debug output containing all intermediate values for one reading.
public final class DebugOutput {

    // MARK: - Fields

    public var seqNumberOriginal: Int = 0
    public var seqNumberFinal: Int = 0
    public var measurementTimeStandard: Int64 = 0
    public var dataType: Int = 0
    public var stage: Int = 0
    public var temperature: Double = 0.0
    public var workout: [Int]
    public var tranInA: [Double]
    public var tranInA1min: [Double]
    public var tranInA5min: Double = 0.0
    public var ycept: Double = 0.0
    public var correctedReCurrent: Double = 0.0
    public var diabetesMeanX: Double = 0.0
    public var diabetesM2: Double = 0.0
    public var diabetesTAR: Double = 0.0
    public var diabetesTBR: Double = 0.0
    public var diabetesCV: Double = 0.0
    public var levelDiabetes: Int = 0
    public var outIir: Double = 0.0
    public var outDrift: Double = 0.0
    public var currBaseline: Double = 0.0
    public var initstableDiffDc: Double = 0.0
    public var initstableInitcnt: Int = 0
    public var tempLocalMean: Double = 0.0
    public var slopeRatioTemp: Double = 0.0
    public var initCg: Double = 0.0
    public var outRescale: Double = 0.0
    public var opcalAd: Double = 0.0
    public var stateInitKalman: Int = 0
    public var smoothSeq: [Int]
    public var smoothSig: [Double]
    public var smoothFrep: [Int]
    public var calState: Int = 0
    public var stateReturnOpcal: Int = 0
    public var validBgTime: Int64 = 0
    public var validBgValue: Double = 0.0
    public var callogGroup: Int = 0
    public var callogBgTime: Int64 = 0
    public var callogBgSeq: Double = 0.0
    public var callogBgUser: Double = 0.0
    public var callogBgValid: Int = 0
    public var callogBgCal: Double = 0.0
    public var callogCgSeq1m: Double = 0.0
    public var callogCgIdx: Int = 0
    public var callogCgCal: Double = 0.0
    public var callogCslopePrev: Double = 0.0
    public var callogCyceptPrev: Double = 0.0
    public var callogCslopeNew: Double = 0.0
    public var callogCyceptNew: Double = 0.0
    public var callogInlierFlg: Int = 0
    public var calSlope: [Double]
    public var calYcept: [Double]
    public var calInput: [Double]
    public var calOutput: [Double]
    public var initstableWeightUsercal: Double = 0.0
    public var initstableWeightNocal: Double = 0.0
    public var initstableFixusercal: Double = 0.0
    public var nOpcalState: Int = 0
    public var initstableInitEndPoint: Int = 0
    public var outWeightSd: [Double]
    public var outWeightAd: Double = 0.0
    public var shiftoutAd: Double = 0.0
    public var errorCode1: Int = 0
    public var errorCode2: Int = 0
    public var errorCode4: Int = 0
    public var errorCode8: Int = 0
    public var errorCode16: Int = 0
    public var errorCode32: Int = 0
    public var trendrate: Double = 0.0
    public var calAvailableFlag: Int = 0
    public var err1ISseDMean: Double = 0.0
    public var err1ThSseDMean1: Double = 0.0
    public var err1ThSseDMean2: Double = 0.0
    public var err1ThSseDMean: Double = 0.0
    public var err1IsContactBad: Int = 0
    public var err1CurrentAvgDiff: Double = 0.0
    public var err1ThDiff1: Double = 0.0
    public var err1ThDiff2: Double = 0.0
    public var err1ThDiff: Double = 0.0
    public var err1Isfirst0: Int = 0
    public var err1Isfirst1: Int = 0
    public var err1Isfirst2: Int = 0
    public var err1N: Int = 0
    public var err1RandomNoiseTempBreak: Int = 0
    public var err1Result: Int = 0
    public var err1LengthT2Max: Int = 0
    public var err1LengthT3Max: Int = 0
    public var err1LengthT1Trio: Int = 0
    public var err1LengthT2Trio: Int = 0
    public var err1LengthT3Trio: Int = 0
    public var err1LengthT6Trio: Int = 0
    public var err1LengthT7Trio: Int = 0
    public var err1LengthT8Trio: Int = 0
    public var err1LengthT9Trio: Int = 0
    public var err1LengthT10Trio: Int = 0
    public var err1ResultTD: Int = 0
    public var err1ResultConditionTD: [Int]
    public var err1TDCount: Int = 0
    public var err1TDTemporaryBreakFlag: Int = 0
    public var err1TDTimeTrio: [Int64]
    public var err1TDValueTrio: [Double]
    public var err2DelayRevisedValue: Double = 0.0
    public var err2DelayRoc: Double = 0.0
    public var err2DelaySlopeSharp: Double = 0.0
    public var err2DelayRocCummax: Double = 0.0
    public var err2DelayRocTrimmedMean: Double = 0.0
    public var err2DelaySlopeCummax: Double = 0.0
    public var err2DelaySlopeTrimmedMean: Double = 0.0
    public var err2DelayGluCummax: Double = 0.0
    public var err2DelayGluTrimmedMean: Double = 0.0
    public var err2DelayPreCondi: [Int]
    public var err2DelayCondi: [Int]
    public var err2DelayFlag: Int = 0
    public var err2Cummax: Double = 0.0
    public var err2CrtCurrent: [Int]
    public var err2CrtGlu: [Int]
    public var err2CrtCv: Double = 0.0
    public var err2Condi: [Int]
    public var err4Min: Double = 0.0
    public var err4Range: Double = 0.0
    public var err4MinDiff: Double = 0.0
    public var err4Condi: [Int]
    public var err4DelayCondi: [Int]
    public var err4DelayFlag: Int = 0
    public var err8Condi: [Int]
    public var err16CalConsDUsercalAfter: Double = 0.0
    public var err16CalDayDTemp: Double = 0.0
    public var err16CalDayDRef: Double = 0.0
    public var err16CalDayNRef: Double = 0.0
    public var err16CgmPlasma: Double = 0.0
    public var err16CgmIsfSmooth: Double = 0.0
    public var err16CgmIsfRocValue: Double = 0.0
    public var err16CgmIsfRocSteady: Double = 0.0
    public var err16CgmIsfRocMinTemp: Double = 0.0
    public var err16CgmIsfRocMin: Double = 0.0
    public var err16CgmIsfRocDiff: Double = 0.0
    public var err16CgmIsfRocRatio: Double = 0.0
    public var err16CgmIsfTrendMinValue: Double = 0.0
    public var err16CgmIsfTrendMinSlope1: Double = 0.0
    public var err16CgmIsfTrendMinSlope2: Double = 0.0
    public var err16CgmIsfTrendMinRsq1: Double = 0.0
    public var err16CgmIsfTrendMinRsq2: Double = 0.0
    public var err16CgmIsfTrendMinDiff: Double = 0.0
    public var err16CgmIsfTrendMinMaxTemp: Double = 0.0
    public var err16CgmIsfTrendMinMax: Double = 0.0
    public var err16CgmIsfTrendMinRatio: Double = 0.0
    public var err16CgmIsfTrendModeValue: Double = 0.0
    public var err16CgmIsfTrendModeProportion: Double = 0.0
    public var err16CgmIsfTrendModeDiff: Double = 0.0
    public var err16CgmIsfTrendModeMaxTemp: Double = 0.0
    public var err16CgmIsfTrendModeMax: Double = 0.0
    public var err16CgmIsfTrendModeRatio: Double = 0.0
    public var err16CgmIsfTrendMeanValue: Double = 0.0
    public var err16CgmIsfTrendMeanSlope: Double = 0.0
    public var err16CgmIsfTrendMeanRsq: Double = 0.0
    public var err16CgmIsfTrendMeanDiff: Double = 0.0
    public var err16CgmIsfTrendMeanMaxTemp: Double = 0.0
    public var err16CgmIsfTrendMeanMax: Double = 0.0
    public var err16CgmIsfTrendMeanRatio: Double = 0.0
    public var err16CgmIsfTrendMeanDiffEarly: Double = 0.0
    public var err16CgmIsfTrendMeanMaxTempEarly: Double = 0.0
    public var err16CgmIsfTrendMeanMaxEarly: Double = 0.0
    public var err16CgmIsfTrendMeanRatioEarly: Double = 0.0
    public var err16Condi: [Int]
    public var err128Flag: Int = 0
    public var err128RevisedValue: Double = 0.0
    public var err128Normal: Double = 0.0

    // MARK: - Initialization

    public init() {
        workout = Array(repeating: 0, count: 30)
        tranInA = Array(repeating: 0.0, count: 30)
        tranInA1min = Array(repeating: 0.0, count: 5)
        smoothSeq = Array(repeating: 0, count: 6)
        smoothSig = Array(repeating: 0.0, count: 6)
        smoothFrep = Array(repeating: 0, count: 6)
        calSlope = Array(repeating: 0.0, count: 7)
        calYcept = Array(repeating: 0.0, count: 7)
        calInput = Array(repeating: 0.0, count: 7)
        calOutput = Array(repeating: 0.0, count: 7)
        outWeightSd = Array(repeating: 0.0, count: 6)
        err1ResultConditionTD = Array(repeating: 0, count: 2)
        err1TDTimeTrio = Array(repeating: 0, count: 3)
        err1TDValueTrio = Array(repeating: 0.0, count: 3)
        err2DelayPreCondi = Array(repeating: 0, count: 3)
        err2DelayCondi = Array(repeating: 0, count: 3)
        err2CrtCurrent = Array(repeating: 0, count: 2)
        err2CrtGlu = Array(repeating: 0, count: 2)
        err2Condi = Array(repeating: 0, count: 2)
        err4Condi = Array(repeating: 0, count: 5)
        err4DelayCondi = Array(repeating: 0, count: 5)
        err8Condi = Array(repeating: 0, count: 2)
        err16Condi = Array(repeating: 0, count: 7)
    }
}
