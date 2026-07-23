// MARK: - Algorithm State Model

import Foundation

/**
 * Persistent algorithm state — massive struct holding all inter-reading state (117312 bytes in C).
 * Maps to air1_opcal4_arguments_t.
 */
public final class AlgorithmState: Codable {
    public var argsSeq: Int
    public var lotType: Int
    public var sensorStartTime: Int64
    public var idxOriginSeq: Int
    public var timePrev: Int64
    public var seqPrev: Int
    public var adcPrev: [Int]
    public var tempPrev: Double
    public var cumulSum: Int
    public var time10secArr: [Int64]
    public var contactErrStartSeq: Int
    public var prevContactErrAlgoSeq: Int
    public var timeStandardArr: [Int64]
    public var idx: Int
    public var accuSeq: [Int]
    public var prevCurrent: [Double]
    public var prevNewISig: [Double]
    public var outlierMaxIndex: [Int]
    public var prevOutlierRemovedCurr: [Double]
    public var prevMovMedianCurr: [Double]
    public var currAvgArr: [Double]
    public var diabetesCntHiGlu: Int
    public var diabetesCntLowGlu: Int
    public var diabetesCntIdx: Int
    public var diabetesLevelDiabetes: Int
    public var diabetesTAR: Double
    public var diabetesTBR: Double
    public var diabetesCV: Double
    public var diabetesMeanX: Double
    public var diabetesM2: Double
    public var shiftoutAdPrev: Double
    public var diabetesBefore7daysNValid: Int
    public var diabetesBefore7daysFlag: Int
    public var diabetesBefore7daysEAG: Double
    public var diabetesBefore7daysM2: Double
    public var diabetesBefore7daysTAR: Double
    public var diabetesBefore7daysTIR: Double
    public var diabetesBefore7daysCV: Double
    public var sumCurrForInitValue: Double
    public var sumCurrCntForInitValue: Int
    public var sumCurrForMdc: Double
    public var sumCurrCntForMdc: Int
    public var iirX: [Double]
    public var iirY: Double
    public var iirStartFlag: Int
    public var mdcStartIdx: Int
    public var mdcFirstFlag: Int
    public var iirUseFlag: Int
    public var baselinePrev: Double
    public var slopeRatioTempBuffer: [Double]
    public var biastrend: [Double]
    public var biasIIR: [Double]
    public var biasavg: [Double]
    public var nSumtrend: Double
    public var biasFlag: Int
    public var biasCnt: Int
    public var holtLevel: Double
    public var holtForecast: Double
    public var holtTrend: Double
    public var kalmanRoc: [Double]
    public var kalmanStateFluctuation: Double
    public var initCgPrev: Double
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
    public var calLogCalState: Int
    public var calLogCslopeDelta: Double
    public var calLogCyceptDelta: Double
    public var calState: Int
    public var stateReturnOpcal: Int
    public var initstableWeightUsercal: Double
    public var initstableWeightNocal: Double
    public var initstableFixusercal: Double
    public var initstableWeightTempuser: Double
    public var initstableWeightUsercalArr: [Double]
    public var initstableWeightFaccalArr: [Double]
    public var initstableMeanDc: [Double]
    public var initstableDiffDc: [Double]
    public var initstableWeightcontrolOnoff: Int
    public var initstableBweightstart: Int
    public var initstableControlCnt: Int
    public var initstableInitcnt: Int
    public var initstableFinishInitFlag: Int
    public var initstableInitEndPoint: Int
    public var initstableBFirstInit: Int
    public var startSeq: Int
    public var cgmTimeStart: Int64
    public var errDelayArr: [Int]
    public var errGluArr: [Double]
    public var err1ThSseDMean1: Double
    public var err1ThSseDMean2: Double
    public var err1ThSseDMean: Double
    public var err1ThDiff1: Double
    public var err1ThDiff2: Double
    public var err1ThDiff: Double
    public var err1N: Int
    public var err1Isfirst0: Int
    public var err1Isfirst1: Int
    public var err1Isfirst2: Int
    public var err1PrevLast1minCurr: Double
    public var err1IsContactBad1h: [Int]
    public var err1ISseDMean4h: [Double]
    public var err1CurrentAvgDiffPrev: [Double]
    public var err1SG1min: [Double]
    public var err1Time1min: [Int64]
    public var err1InA1min: [Double]
    public var err1ResultPrev: Int
    public var err1TDTemporaryBreakFlagPastRange: [Int]
    public var err1SumResultConditionTD: Int
    public var err1AnyResultConditionTD: Int
    public var err2DelayCondiPrev: Int
    public var err2DelayFlagPrev: [Int]
    public var err2DelayRocPrev: [Double]
    public var err2DelaySlopeSharpPrev: [Double]
    public var err2DelayGlucosevaluePrev: [Double]
    public var err2DelayRocCummaxPrev: Double
    public var err2DelaySlopeCummaxPrev: Double
    public var err2DelayGluCummaxPrev: Double
    public var err2DelayPreCondiPrev: [Int]
    public var err2DelayRevisedValuePrev: Double
    public var err2Cummax: Double
    public var err2CummaxForetime: [Double]
    public var err2ResultPrev: Int
    public var err4InA: [Double]
    public var err4MinPrev: [Double]
    public var err4RangePrev: [Double]
    public var err4MinDiffPrev: [Double]
    public var err4DelayFlagArr: [Int]
    public var err4ResultPrev: Int
    public var err8ResultPrev: Int
    public var err128FlagPrev: [Int]
    public var err128NormalPrev: Double
    public var err128RevisedValuePrev: Double
    public var err128CgmCNoiseRevisedValue: [Double]
    public var err16Time5First: Int64
    public var err16DtArr: [Double]
    public var err16CalConsIsFirst: Int
    public var err16CalConsSeq: [Double]
    public var err16CalConsTime: [Int64]
    public var err16CalConsBgm: [Double]
    public var err16CalConsDUsercalBefore: [Double]
    public var err16CalConsDUsercalAfter: [Double]
    public var err16CalDayI: Int
    public var err16CalDayIsFirst: Int
    public var err16CalDayIdxRef: [Int]
    public var err16CalDayDRef: Double
    public var err16CalDayDTemp: Double
    public var err16CalDayDValue: [Double]
    public var err16CalDayNRef: Double
    public var err16CalDayNValue: [Int]
    public var err16CgmIsfSmooth: [Double]
    public var err16CgmPlasma: [Double]
    public var err16CgmIsfRocN: Double
    public var err16CgmIsfRocValue: [Double]
    public var err16CgmIsfRocSteady: [Double]
    public var err16CgmIsfRocMin: Double
    public var err16CgmIsfRocMinTemp: [Double]
    public var err16CgmIsfRocMinPrev: Double
    public var err16CgmIsfRocDiff: [Double]
    public var err16CgmIsfRocRatio: [Double]
    public var err16CgmIsfTrendMinN: Double
    public var err16CgmIsfTrendMinValue: Double
    public var err16CgmIsfTrendMinValuePrev: Double
    public var err16CgmIsfTrendMinValueArr: [Double]
    public var err16CgmIsfTrendMinSlope1: [Double]
    public var err16CgmIsfTrendMinSlope2: [Double]
    public var err16CgmIsfTrendMinRsq1: [Double]
    public var err16CgmIsfTrendMinRsq2: [Double]
    public var err16CgmIsfTrendMinDiff: [Double]
    public var err16CgmIsfTrendMinRatio: [Double]
    public var err16CgmIsfTrendMinMax: Double
    public var err16CgmIsfTrendMinMaxTemp: [Double]
    public var err16CgmIsfTrendMinMaxPrev: Double
    public var err16CgmIsfTrendMinMaxEarly: Double
    public var err16CgmIsfTrendModeN: Double
    public var err16CgmIsfTrendModeValue: Double
    public var err16CgmIsfTrendModeValuePrev: Double
    public var err16CgmIsfTrendModeProportion: [Double]
    public var err16CgmIsfTrendModeDiff: [Double]
    public var err16CgmIsfTrendModeRatio: [Double]
    public var err16CgmIsfTrendModeMax: Double
    public var err16CgmIsfTrendModeMaxTemp: [Double]
    public var err16CgmIsfTrendModeMaxPrev: Double
    public var err16CgmIsfTrendModeMaxEarly: Double
    public var err16CgmIsfTrendMeanIsFirst: Int
    public var err16CgmIsfTrendMeanN: Double
    public var err16CgmIsfTrendMeanValue: Double
    public var err16CgmIsfTrendMeanValuePrev: Double
    public var err16CgmIsfTrendMeanValueArr: [Double]
    public var err16CgmIsfTrendMeanSlope: [Double]
    public var err16CgmIsfTrendMeanRsq: [Double]
    public var err16CgmIsfTrendMeanDiff: [Double]
    public var err16CgmIsfTrendMeanRatio: [Double]
    public var err16CgmIsfTrendMeanMax: Double
    public var err16CgmIsfTrendMeanMaxTemp: [Double]
    public var err16CgmIsfTrendMeanMaxPrev: Double
    public var err16CgmIsfTrendMeanMaxEarly: Double
    public var err16CgmIsfTrendMeanMaxEarlyPrev: Double
    public var err16CgmIsfTrendMeanDiffEarly: [Double]
    public var err16CgmIsfTrendMeanMaxTempEarly: [Double]
    public var err16CgmIsfTrendMeanRatioEarly: [Double]
    public var err16ResultPrev: Int
    public var err32PrevTime: Int64
    public var err32PrevSeq: Int
    public var err32Buff23: [Int]
    public var err32Buff60: [Int]
    public var err32Buff600: Int
    public var err32N: [Int]
    public var err32ResultPrev: Int

    public init() {
        argsSeq = 0
        lotType = 0
        sensorStartTime = 0
        idxOriginSeq = 0
        timePrev = 0
        seqPrev = 0
        adcPrev = Array(repeating: 0, count: 30)
        tempPrev = 0.0
        cumulSum = 0
        time10secArr = Array(repeating: 0, count: 90)
        contactErrStartSeq = 0
        prevContactErrAlgoSeq = 0
        timeStandardArr = Array(repeating: 0, count: 288)
        idx = 0
        accuSeq = Array(repeating: 0, count: 865)
        prevCurrent = Array(repeating: 0.0, count: 5)
        prevNewISig = Array(repeating: 0.0, count: 5)
        outlierMaxIndex = Array(repeating: 0, count: 6)
        prevOutlierRemovedCurr = Array(repeating: 0.0, count: 60)
        prevMovMedianCurr = Array(repeating: 0.0, count: 3)
        currAvgArr = Array(repeating: 0.0, count: 865)
        diabetesCntHiGlu = 0
        diabetesCntLowGlu = 0
        diabetesCntIdx = 0
        diabetesLevelDiabetes = 0
        diabetesTAR = 0.0
        diabetesTBR = 0.0
        diabetesCV = 0.0
        diabetesMeanX = 0.0
        diabetesM2 = 0.0
        shiftoutAdPrev = 0.0
        diabetesBefore7daysNValid = 0
        diabetesBefore7daysFlag = 0
        diabetesBefore7daysEAG = 0.0
        diabetesBefore7daysM2 = 0.0
        diabetesBefore7daysTAR = 0.0
        diabetesBefore7daysTIR = 0.0
        diabetesBefore7daysCV = 0.0
        sumCurrForInitValue = 0.0
        sumCurrCntForInitValue = 0
        sumCurrForMdc = 0.0
        sumCurrCntForMdc = 0
        iirX = Array(repeating: 0.0, count: 2)
        iirY = 0.0
        iirStartFlag = 0
        mdcStartIdx = 0
        mdcFirstFlag = 0
        iirUseFlag = 0
        baselinePrev = 0.0
        slopeRatioTempBuffer = Array(repeating: 0.0, count: 4)
        biastrend = Array(repeating: 0.0, count: 2)
        biasIIR = Array(repeating: 0.0, count: 2)
        biasavg = Array(repeating: 0.0, count: 2)
        nSumtrend = 0.0
        biasFlag = 0
        biasCnt = 0
        holtLevel = 0.0
        holtForecast = 0.0
        holtTrend = 0.0
        kalmanRoc = Array(repeating: 0.0, count: 4)
        kalmanStateFluctuation = 0.0
        initCgPrev = 0.0
        smoothSigIn = Array(repeating: 0.0, count: 10)
        smoothTimeIn = Array(repeating: 0, count: 10)
        smoothFRepIn = Array(repeating: 0, count: 6)
        calResultInput = Array(repeating: 0.0, count: 7)
        calResultOutput = Array(repeating: 0.0, count: 7)
        calResultSlope = Array(repeating: 0.0, count: 7)
        calResultYcept = Array(repeating: 0.0, count: 7)
        calResultInSmoothSlope = Array(repeating: 0.0, count: 10)
        calResultInSmoothYcept = Array(repeating: 0.0, count: 10)
        calLog = Array(repeating: CalibrationLog(), count: 50)
        initstableWeightUsercalArr = Array(repeating: 0.0, count: 7)
        initstableWeightFaccalArr = Array(repeating: 0.0, count: 7)
        initstableMeanDc = Array(repeating: 0.0, count: 2)
        initstableDiffDc = Array(repeating: 0.0, count: 2)
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
        err32ResultPrev = 0
    }
}

// MARK: - Calibration Log

/**
 * Calibration log entry — one per BG calibration event (104 bytes in C).
 * Maps to air1_opcal4_cal_log_t.
 */
public struct CalibrationLog: Codable {
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
