// AlgorithmState.swift
// Persistent algorithm state — massive struct holding all inter-reading state (117312 bytes in C).
// Maps to air1_opcal4_arguments_t.

/// Persistent algorithm state holding all inter-reading state.
public final class AlgorithmState: Codable {
    public var argsSeq: Int = 0
    public var lotType: Int = 0
    public var sensorStartTime: Int64 = 0
    public var idxOriginSeq: Int = 0
    public var timePrev: Int64 = 0
    public var seqPrev: Int = 0
    public var adcPrev: [Int]
    public var tempPrev: Double = 0.0
    public var cumulSum: Int = 0
    public var time10secArr: [Int64]
    public var contactErrStartSeq: Int = 0
    public var prevContactErrAlgoSeq: Int = 0
    public var timeStandardArr: [Int64]
    public var idx: Int = 0
    public var accuSeq: [Int]
    public var prevCurrent: [Double]
    public var prevNewISig: [Double]
    public var outlierMaxIndex: [Int]
    public var prevOutlierRemovedCurr: [Double]
    public var prevMovMedianCurr: [Double]
    public var currAvgArr: [Double]
    public var diabetesCntHiGlu: Int = 0
    public var diabetesCntLowGlu: Int = 0
    public var diabetesCntIdx: Int = 0
    public var diabetesLevelDiabetes: Int = 0
    public var diabetesTAR: Double = 0.0
    public var diabetesTBR: Double = 0.0
    public var diabetesCV: Double = 0.0
    public var diabetesMeanX: Double = 0.0
    public var diabetesM2: Double = 0.0
    public var shiftoutAdPrev: Double = 0.0
    public var diabetesBefore7daysNValid: Int = 0
    public var diabetesBefore7daysFlag: Int = 0
    public var diabetesBefore7daysEAG: Double = 0.0
    public var diabetesBefore7daysM2: Double = 0.0
    public var diabetesBefore7daysTAR: Double = 0.0
    public var diabetesBefore7daysTIR: Double = 0.0
    public var diabetesBefore7daysCV: Double = 0.0
    public var sumCurrForInitValue: Double = 0.0
    public var sumCurrCntForInitValue: Int = 0
    public var sumCurrForMdc: Double = 0.0
    public var sumCurrCntForMdc: Int = 0
    public var iirX: [Double]
    public var iirY: Double = 0.0
    public var iirStartFlag: Int = 0
    public var mdcStartIdx: Int = 0
    public var mdcFirstFlag: Int = 0
    public var iirUseFlag: Int = 0
    public var baselinePrev: Double = 0.0
    public var slopeRatioTempBuffer: [Double]
    public var biastrend: [Double]
    public var biasIIR: [Double]
    public var biasavg: [Double]
    public var nSumtrend: Double = 0.0
    public var biasFlag: Int = 0
    public var biasCnt: Int = 0
    public var holtLevel: Double = 0.0
    public var holtForecast: Double = 0.0
    public var holtTrend: Double = 0.0
    public var kalmanRoc: [Double]
    public var kalmanStateFluctuation: Double = 0.0
    public var initCgPrev: Double = 0.0
    public var smoothSigIn: [Double]
    public var smoothTimeIn: [Int64]
    public var smoothFRepIn: [Int]
    public var calResultInput: [Double]
    public var calResultOutput: [Double]
    public var calResultSlope: [Double]
    public var calResultYcept: [Double]
    public var calResultInSmoothSlope: [Double]
    public var calResultInSmoothYcept: [Double]
    public var calLog: [CalibrationLog]
    public var calLogCalState: Int = 0
    public var calLogCslopeDelta: Double = 0.0
    public var calLogCyceptDelta: Double = 0.0
    public var calState: Int = 0
    public var stateReturnOpcal: Int = 0
    public var initstableWeightUsercal: Double = 0.0
    public var initstableWeightNocal: Double = 0.0
    public var initstableFixusercal: Double = 0.0
    public var initstableWeightTempuser: Double = 0.0
    public var initstableWeightUsercalArr: [Double]
    public var initstableWeightFaccalArr: [Double]
    public var initstableMeanDc: [Double]
    public var initstableDiffDc: Double = 0.0
    public var initstableWeightcontrolOnoff: Int = 0
    public var initstableBweightstart: Int = 0
    public var initstableControlCnt: Int = 0
    public var initstableInitcnt: Int = 0
    public var initstableFinishInitFlag: Int = 0
    public var initstableInitEndPoint: Int = 0
    public var initstableBFirstInit: Int = 0
    public var startSeq: Int = 0
    public var cgmTimeStart: Int64 = 0
    public var errDelayArr: [Int]
    public var errGluArr: [Double]
    public var err1ThSseDMean1: Double = 0.0
    public var err1ThSseDMean2: Double = 0.0
    public var err1ThSseDMean: Double = 0.0
    public var err1ThDiff1: Double = 0.0
    public var err1ThDiff2: Double = 0.0
    public var err1ThDiff: Double = 0.0
    public var err1N: Int = 0
    public var err1Isfirst0: Int = 0
    public var err1Isfirst1: Int = 0
    public var err1Isfirst2: Int = 0
    public var err1PrevLast1minCurr: Double = 0.0
    public var err1IsContactBad1h: [Int]
    public var err1ISseDMean4h: [Double]
    public var err1CurrentAvgDiffPrev: [Double]
    public var err1SG1min: [Double]
    public var err1Time1min: [Int64]
    public var err1InA1min: [Double]
    public var err1ResultPrev: Int = 0
    public var err1TDTemporaryBreakFlagPastRange: [Int]
    public var err1SumResultConditionTD: Int = 0
    public var err1AnyResultConditionTD: Int = 0
    public var err2DelayCondiPrev: Int = 0
    public var err2DelayFlagPrev: [Int]
    public var err2DelayRocPrev: [Double]
    public var err2DelaySlopeSharpPrev: [Double]
    public var err2DelayGlucosevaluePrev: [Double]
    public var err2DelayRocCummaxPrev: Double = 0.0
    public var err2DelaySlopeCummaxPrev: Double = 0.0
    public var err2DelayGluCummaxPrev: Double = 0.0
    public var err2DelayPreCondiPrev: [Int]
    public var err2DelayRevisedValuePrev: Double = 0.0
    public var err2Cummax: Double = 0.0
    public var err2CummaxForetime: [Double]
    public var err2ResultPrev: Int = 0
    public var err4InA: [Double]
    public var err4MinPrev: [Double]
    public var err4RangePrev: [Double]
    public var err4MinDiffPrev: [Double]
    public var err4DelayFlagArr: [Int]
    public var err4ResultPrev: Int = 0
    public var err8ResultPrev: Int = 0
    public var err128FlagPrev: [Int]
    public var err128NormalPrev: Double = 0.0
    public var err128RevisedValuePrev: Double = 0.0
    public var err128CgmCNoiseRevisedValue: [Double]
    public var err16Time5First: Int64 = 0
    public var err16DtArr: [Double]
    public var err16CalConsIsFirst: Int = 0
    public var err16CalConsSeq: [Double]
    public var err16CalConsTime: [Int64]
    public var err16CalConsBgm: [Double]
    public var err16CalConsDUsercalBefore: [Double]
    public var err16CalConsDUsercalAfter: [Double]
    public var err16CalDayI: Int = 0
    public var err16CalDayIsFirst: Int = 0
    public var err16CalDayIdxRef: [Int]
    public var err16CalDayDRef: Double = 0.0
    public var err16CalDayDTemp: Double = 0.0
    public var err16CalDayDValue: [Double]
    public var err16CalDayNRef: Double = 0.0
    public var err16CalDayNValue: [Int]
    public var err16CgmIsfSmooth: [Double]
    public var err16CgmPlasma: [Double]
    public var err16CgmIsfRocN: Double = 0.0
    public var err16CgmIsfRocValue: [Double]
    public var err16CgmIsfRocSteady: [Double]
    public var err16CgmIsfRocMin: Double = 0.0
    public var err16CgmIsfRocMinTemp: [Double]
    public var err16CgmIsfRocMinPrev: Double = 0.0
    public var err16CgmIsfRocDiff: [Double]
    public var err16CgmIsfRocRatio: [Double]
    public var err16CgmIsfTrendMinN: Double = 0.0
    public var err16CgmIsfTrendMinValue: Double = 0.0
    public var err16CgmIsfTrendMinValuePrev: Double = 0.0
    public var err16CgmIsfTrendMinValueArr: [Double]
    public var err16CgmIsfTrendMinSlope1: [Double]
    public var err16CgmIsfTrendMinSlope2: [Double]
    public var err16CgmIsfTrendMinRsq1: [Double]
    public var err16CgmIsfTrendMinRsq2: [Double]
    public var err16CgmIsfTrendMinDiff: [Double]
    public var err16CgmIsfTrendMinRatio: [Double]
    public var err16CgmIsfTrendMinMax: Double = 0.0
    public var err16CgmIsfTrendMinMaxTemp: [Double]
    public var err16CgmIsfTrendMinMaxPrev: Double = 0.0
    public var err16CgmIsfTrendMinMaxEarly: Double = 0.0
    public var err16CgmIsfTrendModeN: Double = 0.0
    public var err16CgmIsfTrendModeValue: Double = 0.0
    public var err16CgmIsfTrendModeValuePrev: Double = 0.0
    public var err16CgmIsfTrendModeProportion: [Double]
    public var err16CgmIsfTrendModeDiff: [Double]
    public var err16CgmIsfTrendModeRatio: [Double]
    public var err16CgmIsfTrendModeMax: Double = 0.0
    public var err16CgmIsfTrendModeMaxTemp: [Double]
    public var err16CgmIsfTrendModeMaxPrev: Double = 0.0
    public var err16CgmIsfTrendModeMaxEarly: Double = 0.0
    public var err16CgmIsfTrendMeanIsFirst: Int = 0
    public var err16CgmIsfTrendMeanN: Double = 0.0
    public var err16CgmIsfTrendMeanValue: Double = 0.0
    public var err16CgmIsfTrendMeanValuePrev: Double = 0.0
    public var err16CgmIsfTrendMeanValueArr: [Double]
    public var err16CgmIsfTrendMeanSlope: [Double]
    public var err16CgmIsfTrendMeanRsq: [Double]
    public var err16CgmIsfTrendMeanDiff: [Double]
    public var err16CgmIsfTrendMeanRatio: [Double]
    public var err16CgmIsfTrendMeanMax: Double = 0.0
    public var err16CgmIsfTrendMeanMaxTemp: [Double]
    public var err16CgmIsfTrendMeanMaxPrev: Double = 0.0
    public var err16CgmIsfTrendMeanMaxEarly: Double = 0.0
    public var err16CgmIsfTrendMeanMaxEarlyPrev: Double = 0.0
    public var err16CgmIsfTrendMeanDiffEarly: [Double]
    public var err16CgmIsfTrendMeanMaxTempEarly: [Double]
    public var err16CgmIsfTrendMeanRatioEarly: [Double]
    public var err16ResultPrev: Int = 0
    public var err32PrevTime: Int64 = 0
    public var err32PrevSeq: Int = 0
    public var err32Buff23: [Int]
    public var err32Buff60: [Int]
    public var err32Buff600: Int = 0
    public var err32N: [Int]
    public var err32ResultPrev: Int = 0

    public init() {
        adcPrev = Array(repeating: 0, count: 30)
        time10secArr = Array(repeating: 0, count: 90)
        timeStandardArr = Array(repeating: 0, count: 288)
        accuSeq = Array(repeating: 0, count: 865)
        prevCurrent = Array(repeating: 0.0, count: 5)
        prevNewISig = Array(repeating: 0.0, count: 5)
        outlierMaxIndex = Array(repeating: 0, count: 6)
        prevOutlierRemovedCurr = Array(repeating: 0.0, count: 60)
        prevMovMedianCurr = Array(repeating: 0.0, count: 3)
        currAvgArr = Array(repeating: 0.0, count: 865)
        iirX = Array(repeating: 0.0, count: 2)
        slopeRatioTempBuffer = Array(repeating: 0.0, count: 4)
        biastrend = Array(repeating: 0.0, count: 2)
        biasIIR = Array(repeating: 0.0, count: 2)
        biasavg = Array(repeating: 0.0, count: 2)
        kalmanRoc = Array(repeating: 0.0, count: 4)
        smoothSigIn = Array(repeating: 0.0, count: 10)
        smoothTimeIn = Array(repeating: 0, count: 10)
        smoothFRepIn = Array(repeating: 0, count: 6)
        calResultInput = Array(repeating: 0.0, count: 7)
        calResultOutput = Array(repeating: 0.0, count: 7)
        calResultSlope = Array(repeating: 0.0, count: 7)
        calResultYcept = Array(repeating: 0.0, count: 7)
        calResultInSmoothSlope = Array(repeating: 0.0, count: 10)
        calResultInSmoothYcept = Array(repeating: 0.0, count: 10)
        calLog = (0..<50).map { _ in CalibrationLog() }
        initstableWeightUsercalArr = Array(repeating: 0.0, count: 7)
        initstableWeightFaccalArr = Array(repeating: 0.0, count: 7)
        initstableMeanDc = Array(repeating: 0.0, count: 2)
        errDelayArr = Array(repeating: 0, count: 7)
        errGluArr = Array(repeating: 0.0, count: 288)
        err1IsContactBad1h = Array(repeating: 0, count: 100)
        err1ISseDMean4h = Array(repeating: 0.0, count: 100)
        err1CurrentAvgDiffPrev = Array(repeating: 0.0, count: 100)
        err1SG1min = Array(repeating: 0.0, count: 180)
        err1Time1min = Array(repeating: 0, count: 180)
        err1InA1min = Array(repeating: 0.0, count: 180)
        err1TDTemporaryBreakFlagPastRange = Array(repeating: 0, count: 36)
        err2DelayFlagPrev = Array(repeating: 0, count: 575)
        err2DelayRocPrev = Array(repeating: 0.0, count: 575)
        err2DelaySlopeSharpPrev = Array(repeating: 0.0, count: 575)
        err2DelayGlucosevaluePrev = Array(repeating: 0.0, count: 575)
        err2DelayPreCondiPrev = Array(repeating: 0, count: 3)
        err2CummaxForetime = Array(repeating: 0.0, count: 100)
        err4InA = Array(repeating: 0.0, count: 390)
        err4MinPrev = Array(repeating: 0.0, count: 289)
        err4RangePrev = Array(repeating: 0.0, count: 51)
        err4MinDiffPrev = Array(repeating: 0.0, count: 289)
        err4DelayFlagArr = Array(repeating: 0, count: 576)
        err128FlagPrev = Array(repeating: 0, count: 40)
        err128CgmCNoiseRevisedValue = Array(repeating: 0.0, count: 36)
        err16DtArr = Array(repeating: 0.0, count: 36)
        err16CalConsSeq = Array(repeating: 0.0, count: 50)
        err16CalConsTime = Array(repeating: 0, count: 50)
        err16CalConsBgm = Array(repeating: 0.0, count: 50)
        err16CalConsDUsercalBefore = Array(repeating: 0.0, count: 50)
        err16CalConsDUsercalAfter = Array(repeating: 0.0, count: 50)
        err16CalDayIdxRef = Array(repeating: 0, count: 30)
        err16CalDayDValue = Array(repeating: 0.0, count: 30)
        err16CalDayNValue = Array(repeating: 0, count: 30)
        err16CgmIsfSmooth = Array(repeating: 0.0, count: 865)
        err16CgmPlasma = Array(repeating: 0.0, count: 36)
        err16CgmIsfRocValue = Array(repeating: 0.0, count: 577)
        err16CgmIsfRocSteady = Array(repeating: 0.0, count: 36)
        err16CgmIsfRocMinTemp = Array(repeating: 0.0, count: 865)
        err16CgmIsfRocDiff = Array(repeating: 0.0, count: 36)
        err16CgmIsfRocRatio = Array(repeating: 0.0, count: 36)
        err16CgmIsfTrendMinValueArr = Array(repeating: 0.0, count: 865)
        err16CgmIsfTrendMinSlope1 = Array(repeating: 0.0, count: 36)
        err16CgmIsfTrendMinSlope2 = Array(repeating: 0.0, count: 36)
        err16CgmIsfTrendMinRsq1 = Array(repeating: 0.0, count: 36)
        err16CgmIsfTrendMinRsq2 = Array(repeating: 0.0, count: 36)
        err16CgmIsfTrendMinDiff = Array(repeating: 0.0, count: 36)
        err16CgmIsfTrendMinRatio = Array(repeating: 0.0, count: 36)
        err16CgmIsfTrendMinMaxTemp = Array(repeating: 0.0, count: 865)
        err16CgmIsfTrendModeProportion = Array(repeating: 0.0, count: 36)
        err16CgmIsfTrendModeDiff = Array(repeating: 0.0, count: 36)
        err16CgmIsfTrendModeRatio = Array(repeating: 0.0, count: 36)
        err16CgmIsfTrendModeMaxTemp = Array(repeating: 0.0, count: 865)
        err16CgmIsfTrendMeanValueArr = Array(repeating: 0.0, count: 865)
        err16CgmIsfTrendMeanSlope = Array(repeating: 0.0, count: 36)
        err16CgmIsfTrendMeanRsq = Array(repeating: 0.0, count: 36)
        err16CgmIsfTrendMeanDiff = Array(repeating: 0.0, count: 36)
        err16CgmIsfTrendMeanRatio = Array(repeating: 0.0, count: 36)
        err16CgmIsfTrendMeanMaxTemp = Array(repeating: 0.0, count: 865)
        err16CgmIsfTrendMeanDiffEarly = Array(repeating: 0.0, count: 36)
        err16CgmIsfTrendMeanMaxTempEarly = Array(repeating: 0.0, count: 865)
        err16CgmIsfTrendMeanRatioEarly = Array(repeating: 0.0, count: 36)
        err32Buff23 = Array(repeating: 0, count: 4)
        err32Buff60 = Array(repeating: 0, count: 2)
        err32N = Array(repeating: 0, count: 3)
    }
}
