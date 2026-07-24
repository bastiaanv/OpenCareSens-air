// MARK: - Model Types

/// Calibration log entry — one per BG calibration event (104 bytes in C).
/// Maps to air1_opcal4_cal_log_t.
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
        self.group = 0
        self.bgTime = 0
        self.bgSeq = 0
        self.cgSeq1m = 0
        self.cgIdx = 0
        self.bgUser = 0
        self.cslopePrev = 0
        self.cyceptPrev = 0
        self.bgValid = 0
        self.bgCal = 0
        self.cgCal = 0
        self.cslopeNew = 0
        self.cyceptNew = 0
        self.inlierFlg = 0
    }
}

/// Per-reading algorithm output (155 bytes packed in C).
/// Maps to air1_opcal4_output_t.
public struct AlgorithmOutput: Codable {
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
        self.seqNumberOriginal = 0
        self.seqNumberFinal = 0
        self.measurementTimeStandard = 0
        self.workout = Array(repeating: 0, count: 30)
        self.resultGlucose = 0
        self.trendrate = 0
        self.currentStage = 0
        self.smoothFixedFlag = Array(repeating: 0, count: 6)
        self.smoothSeq = Array(repeating: 0, count: 6)
        self.smoothResultGlucose = Array(repeating: 0, count: 6)
        self.errcode = 0
        self.calAvailableFlag = 0
        self.dataType = 0
    }
}

/// Per-reading CGM input — raw sensor data for one measurement (74 bytes packed in C).
/// Maps to air1_opcal4_cgm_input_t.
public struct CgmInput: Codable {
    public var seqNumber: Int
    public var measurementTimeStandard: Int64
    public var workout: [Int]
    public var temperature: Double
    
    public init() {
        self.seqNumber = 0
        self.measurementTimeStandard = 0
        self.workout = Array(repeating: 0, count: 30)
        self.temperature = 0
    }
}

/// Debug oracle output — all intermediate values for one reading (1579 bytes packed in C).
/// Maps to air1_opcal4_debug_t.
public struct DebugOutput: Codable {
    public var seqNumberOriginal: Int
    public var seqNumberFinal: Int
    public var measurementTimeStandard: Int64
    public var dataType: Int
    public var stage: Int
    public var temperature: Double
    public var workout: [Int]
    public var tranInA: [Double]
    public var tranInA1min: [Double]
    public var tranInA5min: Double
    public var ycept: Double
    public var correctedReCurrent: Double
    public var diabetesMeanX: Double
    public var diabetesM2: Double
    public var diabetesTAR: Double
    public var diabetesTBR: Double
    public var diabetesCV: Double
    public var levelDiabetes: Int
    public var outIir: Double
    public var outDrift: Double
    public var currBaseline: Double
    public var initstableDiffDc: Double
    public var initstableInitcnt: Int
    public var tempLocalMean: Double
    public var slopeRatioTemp: Double
    public var initCg: Double
    public var outRescale: Double
    public var opcalAd: Double
    public var stateInitKalman: Int
    public var smoothSeq: [Int]
    public var smoothSig: [Double]
    public var smoothFrep: [Int]
    public var calState: Int
    public var stateReturnOpcal: Int8
    public var validBgTime: Int64
    public var validBgValue: Double
    public var callogGroup: Int
    public var callogBgTime: Int64
    public var callogBgSeq: Double
    public var callogBgUser: Double
    public var callogBgValid: Int8
    public var callogBgCal: Double
    public var callogCgSeq1m: Double
    public var callogCgIdx: Int
    public var callogCgCal: Double
    public var callogCslopePrev: Double
    public var callogCyceptPrev: Double
    public var callogCslopeNew: Double
    public var callogCyceptNew: Double
    public var callogInlierFlg: Int
    public var calSlope: [Double]
    public var calYcept: [Double]
    public var calInput: [Double]
    public var calOutput: [Double]
    public var initstableWeightUsercal: Double
    public var initstableWeightNocal: Double
    public var initstableFixusercal: Double
    public var nOpcalState: Int8
    public var initstableInitEndPoint: Int
    public var outWeightSd: [Double]
    public var outWeightAd: Double
    public var shiftoutAd: Double
    public var errorCode1: Int
    public var errorCode2: Int
    public var errorCode4: Int
    public var errorCode8: Int
    public var errorCode16: Int
    public var errorCode32: Int
    public var trendrate: Double
    public var calAvailableFlag: Int
    public var err1ISseDMean: Double
    public var err1ThSseDMean1: Double
    public var err1ThSseDMean2: Double
    public var err1ThSseDMean: Double
    public var err1IsContactBad: Int
    public var err1CurrentAvgDiff: Double
    public var err1ThDiff1: Double
    public var err1ThDiff2: Double
    public var err1ThDiff: Double
    public var err1Isfirst0: Int
    public var err1Isfirst1: Int
    public var err1Isfirst2: Int
    public var err1N: Int
    public var err1RandomNoiseTempBreak: Int
    public var err1Result: Int
    public var err1LengthT2Max: Int
    public var err1LengthT3Max: Int
    public var err1LengthT1Trio: Int
    public var err1LengthT2Trio: Int
    public var err1LengthT3Trio: Int
    public var err1LengthT6Trio: Int
    public var err1LengthT7Trio: Int
    public var err1LengthT8Trio: Int
    public var err1LengthT9Trio: Int
    public var err1LengthT10Trio: Int
    public var err1ResultTD: Int
    public var err1ResultConditionTD: [Int]
    public var err1TDCount: Int
    public var err1TDTemporaryBreakFlag: Int
    public var err1TDTimeTrio: [Int64]
    public var err1TDValueTrio: [Double]
    public var err2DelayRevisedValue: Double
    public var err2DelayRoc: Double
    public var err2DelaySlopeSharp: Double
    public var err2DelayRocCummax: Double
    public var err2DelayRocTrimmedMean: Double
    public var err2DelaySlopeCummax: Double
    public var err2DelaySlopeTrimmedMean: Double
    public var err2DelayGluCummax: Double
    public var err2DelayGluTrimmedMean: Double
    public var err2DelayPreCondi: [Int]
    public var err2DelayCondi: [Int]
    public var err2DelayFlag: Int
    public var err2Cummax: Double
    public var err2CrtCurrent: [Int]
    public var err2CrtGlu: [Int]
    public var err2CrtCv: Double
    public var err2Condi: [Int]
    public var err4Min: Double
    public var err4Range: Double
    public var err4MinDiff: Double
    public var err4Condi: [Int]
    public var err4DelayCondi: [Int]
    public var err4DelayFlag: Int
    public var err8Condi: [Int]
    public var err16CalConsDUsercalAfter: Double
    public var err16CalDayDTemp: Double
    public var err16CalDayDRef: Double
    public var err16CalDayNRef: Double
    public var err16CgmPlasma: Double
    public var err16CgmIsfSmooth: Double
    public var err16CgmIsfRocValue: Double
    public var err16CgmIsfRocSteady: Double
    public var err16CgmIsfRocMinTemp: Double
    public var err16CgmIsfRocMin: Double
    public var err16CgmIsfRocDiff: Double
    public var err16CgmIsfRocRatio: Double
    public var err16CgmIsfTrendMinValue: Double
    public var err16CgmIsfTrendMinSlope1: Double
    public var err16CgmIsfTrendMinSlope2: Double
    public var err16CgmIsfTrendMinRsq1: Double
    public var err16CgmIsfTrendMinRsq2: Double
    public var err16CgmIsfTrendMinDiff: Double
    public var err16CgmIsfTrendMinMaxTemp: Double
    public var err16CgmIsfTrendMinMax: Double
    public var err16CgmIsfTrendMinRatio: Double
    public var err16CgmIsfTrendModeValue: Double
    public var err16CgmIsfTrendModeProportion: Double
    public var err16CgmIsfTrendModeDiff: Double
    public var err16CgmIsfTrendModeMaxTemp: Double
    public var err16CgmIsfTrendModeMax: Double
    public var err16CgmIsfTrendModeRatio: Double
    public var err16CgmIsfTrendMeanValue: Double
    public var err16CgmIsfTrendMeanSlope: Double
    public var err16CgmIsfTrendMeanRsq: Double
    public var err16CgmIsfTrendMeanDiff: Double
    public var err16CgmIsfTrendMeanMaxTemp: Double
    public var err16CgmIsfTrendMeanMax: Double
    public var err16CgmIsfTrendMeanRatio: Double
    public var err16CgmIsfTrendMeanDiffEarly: Double
    public var err16CgmIsfTrendMeanMaxTempEarly: Double
    public var err16CgmIsfTrendMeanMaxEarly: Double
    public var err16CgmIsfTrendMeanRatioEarly: Double
    public var err16Condi: [Int]
    public var err128Flag: Int
    public var err128RevisedValue: Double
    public var err128Normal: Double
    
    public init() {
        self.seqNumberOriginal = 0
        self.seqNumberFinal = 0
        self.measurementTimeStandard = 0
        self.dataType = 0
        self.stage = 0
        self.temperature = 0
        self.workout = Array(repeating: 0, count: 30)
        self.tranInA = Array(repeating: 0, count: 30)
        self.tranInA1min = Array(repeating: 0, count: 5)
        self.tranInA5min = 0
        self.ycept = 0
        self.correctedReCurrent = 0
        self.diabetesMeanX = 0
        self.diabetesM2 = 0
        self.diabetesTAR = 0
        self.diabetesTBR = 0
        self.diabetesCV = 0
        self.levelDiabetes = 0
        self.outIir = 0
        self.outDrift = 0
        self.currBaseline = 0
        self.initstableDiffDc = 0
        self.initstableInitcnt = 0
        self.tempLocalMean = 0
        self.slopeRatioTemp = 0
        self.initCg = 0
        self.outRescale = 0
        self.opcalAd = 0
        self.stateInitKalman = 0
        self.smoothSeq = Array(repeating: 0, count: 6)
        self.smoothSig = Array(repeating: 0, count: 6)
        self.smoothFrep = Array(repeating: 0, count: 6)
        self.calState = 0
        self.stateReturnOpcal = 0
        self.validBgTime = 0
        self.validBgValue = 0
        self.callogGroup = 0
        self.callogBgTime = 0
        self.callogBgSeq = 0
        self.callogBgUser = 0
        self.callogBgValid = 0
        self.callogBgCal = 0
        self.callogCgSeq1m = 0
        self.callogCgIdx = 0
        self.callogCgCal = 0
        self.callogCslopePrev = 0
        self.callogCyceptPrev = 0
        self.callogCslopeNew = 0
        self.callogCyceptNew = 0
        self.callogInlierFlg = 0
        self.calSlope = Array(repeating: 0, count: 7)
        self.calYcept = Array(repeating: 0, count: 7)
        self.calInput = Array(repeating: 0, count: 7)
        self.calOutput = Array(repeating: 0, count: 7)
        self.initstableWeightUsercal = 0
        self.initstableWeightNocal = 0
        self.initstableFixusercal = 0
        self.nOpcalState = 0
        self.initstableInitEndPoint = 0
        self.outWeightSd = Array(repeating: 0, count: 6)
        self.outWeightAd = 0
        self.shiftoutAd = 0
        self.errorCode1 = 0
        self.errorCode2 = 0
        self.errorCode4 = 0
        self.errorCode8 = 0
        self.errorCode16 = 0
        self.errorCode32 = 0
        self.trendrate = 0
        self.calAvailableFlag = 0
        self.err1ISseDMean = 0
        self.err1ThSseDMean1 = 0
        self.err1ThSseDMean2 = 0
        self.err1ThSseDMean = 0
        self.err1IsContactBad = 0
        self.err1CurrentAvgDiff = 0
        self.err1ThDiff1 = 0
        self.err1ThDiff2 = 0
        self.err1ThDiff = 0
        self.err1Isfirst0 = 0
        self.err1Isfirst1 = 0
        self.err1Isfirst2 = 0
        self.err1N = 0
        self.err1RandomNoiseTempBreak = 0
        self.err1Result = 0
        self.err1LengthT2Max = 0
        self.err1LengthT3Max = 0
        self.err1LengthT1Trio = 0
        self.err1LengthT2Trio = 0
        self.err1LengthT3Trio = 0
        self.err1LengthT6Trio = 0
        self.err1LengthT7Trio = 0
        self.err1LengthT8Trio = 0
        self.err1LengthT9Trio = 0
        self.err1LengthT10Trio = 0
        self.err1ResultTD = 0
        self.err1ResultConditionTD = Array(repeating: 0, count: 2)
        self.err1TDCount = 0
        self.err1TDTemporaryBreakFlag = 0
        self.err1TDTimeTrio = Array(repeating: 0, count: 3)
        self.err1TDValueTrio = Array(repeating: 0, count: 3)
        self.err2DelayRevisedValue = 0
        self.err2DelayRoc = 0
        self.err2DelaySlopeSharp = 0
        self.err2DelayRocCummax = 0
        self.err2DelayRocTrimmedMean = 0
        self.err2DelaySlopeCummax = 0
        self.err2DelaySlopeTrimmedMean = 0
        self.err2DelayGluCummax = 0
        self.err2DelayGluTrimmedMean = 0
        self.err2DelayPreCondi = Array(repeating: 0, count: 3)
        self.err2DelayCondi = Array(repeating: 0, count: 3)
        self.err2DelayFlag = 0
        self.err2Cummax = 0
        self.err2CrtCurrent = Array(repeating: 0, count: 2)
        self.err2CrtGlu = Array(repeating: 0, count: 2)
        self.err2CrtCv = 0
        self.err2Condi = Array(repeating: 0, count: 2)
        self.err4Min = 0
        self.err4Range = 0
        self.err4MinDiff = 0
        self.err4Condi = Array(repeating: 0, count: 5)
        self.err4DelayCondi = Array(repeating: 0, count: 5)
        self.err4DelayFlag = 0
        self.err8Condi = Array(repeating: 0, count: 2)
        self.err16CalConsDUsercalAfter = 0
        self.err16CalDayDTemp = 0
        self.err16CalDayDRef = 0
        self.err16CalDayNRef = 0
        self.err16CgmPlasma = 0
        self.err16CgmIsfSmooth = 0
        self.err16CgmIsfRocValue = 0
        self.err16CgmIsfRocSteady = 0
        self.err16CgmIsfRocMinTemp = 0
        self.err16CgmIsfRocMin = 0
        self.err16CgmIsfRocDiff = 0
        self.err16CgmIsfRocRatio = 0
        self.err16CgmIsfTrendMinValue = 0
        self.err16CgmIsfTrendMinSlope1 = 0
        self.err16CgmIsfTrendMinSlope2 = 0
        self.err16CgmIsfTrendMinRsq1 = 0
        self.err16CgmIsfTrendMinRsq2 = 0
        self.err16CgmIsfTrendMinDiff = 0
        self.err16CgmIsfTrendMinMaxTemp = 0
        self.err16CgmIsfTrendMinMax = 0
        self.err16CgmIsfTrendMinRatio = 0
        self.err16CgmIsfTrendModeValue = 0
        self.err16CgmIsfTrendModeProportion = 0
        self.err16CgmIsfTrendModeDiff = 0
        self.err16CgmIsfTrendModeMaxTemp = 0
        self.err16CgmIsfTrendModeMax = 0
        self.err16CgmIsfTrendModeRatio = 0
        self.err16CgmIsfTrendMeanValue = 0
        self.err16CgmIsfTrendMeanSlope = 0
        self.err16CgmIsfTrendMeanRsq = 0
        self.err16CgmIsfTrendMeanDiff = 0
        self.err16CgmIsfTrendMeanMaxTemp = 0
        self.err16CgmIsfTrendMeanMax = 0
        self.err16CgmIsfTrendMeanRatio = 0
        self.err16CgmIsfTrendMeanDiffEarly = 0
        self.err16CgmIsfTrendMeanMaxTempEarly = 0
        self.err16CgmIsfTrendMeanMaxEarly = 0
        self.err16CgmIsfTrendMeanRatioEarly = 0
        self.err16Condi = Array(repeating: 0, count: 7)
        self.err128Flag = 0
        self.err128RevisedValue = 0
        self.err128Normal = 0
    }
}

/// Persistent algorithm state — massive struct holding all inter-reading state (117312 bytes in C).
/// Maps to air1_opcal4_arguments_t.
public struct AlgorithmState: Codable {
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
    public var initstableDiffDc: Double
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
        self.argsSeq = 0
        self.lotType = 0
        self.sensorStartTime = 0
        self.idxOriginSeq = 0
        self.timePrev = 0
        self.seqPrev = 0
        self.adcPrev = Array(repeating: 0, count: 30)
        self.tempPrev = 0
        self.cumulSum = 0
        self.time10secArr = Array(repeating: 0, count: 90)
        self.contactErrStartSeq = 0
        self.prevContactErrAlgoSeq = 0
        self.timeStandardArr = Array(repeating: 0, count: 288)
        self.idx = 0
        self.accuSeq = Array(repeating: 0, count: 865)
        self.prevCurrent = Array(repeating: 0, count: 5)
        self.prevNewISig = Array(repeating: 0, count: 5)
        self.outlierMaxIndex = Array(repeating: 0, count: 6)
        self.prevOutlierRemovedCurr = Array(repeating: 0, count: 60)
        self.prevMovMedianCurr = Array(repeating: 0, count: 3)
        self.currAvgArr = Array(repeating: 0, count: 865)
        self.diabetesCntHiGlu = 0
        self.diabetesCntLowGlu = 0
        self.diabetesCntIdx = 0
        self.diabetesLevelDiabetes = 0
        self.diabetesTAR = 0
        self.diabetesTBR = 0
        self.diabetesCV = 0
        self.diabetesMeanX = 0
        self.diabetesM2 = 0
        self.shiftoutAdPrev = 0
        self.diabetesBefore7daysNValid = 0
        self.diabetesBefore7daysFlag = 0
        self.diabetesBefore7daysEAG = 0
        self.diabetesBefore7daysM2 = 0
        self.diabetesBefore7daysTAR = 0
        self.diabetesBefore7daysTIR = 0
        self.diabetesBefore7daysCV = 0
        self.sumCurrForInitValue = 0
        self.sumCurrCntForInitValue = 0
        self.sumCurrForMdc = 0
        self.sumCurrCntForMdc = 0
        self.iirX = Array(repeating: 0, count: 2)
        self.iirY = 0
        self.iirStartFlag = 0
        self.mdcStartIdx = 0
        self.mdcFirstFlag = 0
        self.iirUseFlag = 0
        self.baselinePrev = 0
        self.slopeRatioTempBuffer = Array(repeating: 0, count: 4)
        self.biastrend = Array(repeating: 0, count: 2)
        self.biasIIR = Array(repeating: 0, count: 2)
        self.biasavg = Array(repeating: 0, count: 2)
        self.nSumtrend = 0
        self.biasFlag = 0
        self.biasCnt = 0
        self.holtLevel = 0
        self.holtForecast = 0
        self.holtTrend = 0
        self.kalmanRoc = Array(repeating: 0, count: 4)
        self.kalmanStateFluctuation = 0
        self.initCgPrev = 0
        self.smoothSigIn = Array(repeating: 0, count: 10)
        self.smoothTimeIn = Array(repeating: 0, count: 10)
        self.smoothFRepIn = Array(repeating: 0, count: 6)
        self.calResultInput = Array(repeating: 0, count: 7)
        self.calResultOutput = Array(repeating: 0, count: 7)
        self.calResultSlope = Array(repeating: 0, count: 7)
        self.calResultYcept = Array(repeating: 0, count: 7)
        self.calResultInSmoothSlope = Array(repeating: 0, count: 10)
        self.calResultInSmoothYcept = Array(repeating: 0, count: 10)
        self.calLog = Array(repeating: CalibrationLog(), count: 50)
        self.calLogCalState = 0
        self.calLogCslopeDelta = 0
        self.calLogCyceptDelta = 0
        self.calState = 0
        self.stateReturnOpcal = 0
        self.initstableWeightUsercal = 0
        self.initstableWeightNocal = 0
        self.initstableFixusercal = 0
        self.initstableWeightTempuser = 0
        self.initstableWeightUsercalArr = Array(repeating: 0, count: 7)
        self.initstableWeightFaccalArr = Array(repeating: 0, count: 7)
        self.initstableMeanDc = Array(repeating: 0, count: 2)
        self.initstableDiffDc = 0
        self.initstableWeightcontrolOnoff = 0
        self.initstableBweightstart = 0
        self.initstableControlCnt = 0
        self.initstableInitcnt = 0
        self.initstableFinishInitFlag = 0
        self.initstableInitEndPoint = 0
        self.initstableBFirstInit = 0
        self.startSeq = 0
        self.cgmTimeStart = 0
        self.errDelayArr = Array(repeating: 0, count: 7)
        self.errGluArr = Array(repeating: 0, count: 288)
        self.err1ThSseDMean1 = 0
        self.err1ThSseDMean2 = 0
        self.err1ThSseDMean = 0
        self.err1ThDiff1 = 0
        self.err1ThDiff2 = 0
        self.err1ThDiff = 0
        self.err1N = 0
        self.err1Isfirst0 = 0
        self.err1Isfirst1 = 0
        self.err1Isfirst2 = 0
        self.err1PrevLast1minCurr = 0
        self.err1IsContactBad1h = Array(repeating: 0, count: 100)
        self.err1ISseDMean4h = Array(repeating: 0, count: 100)
        self.err1CurrentAvgDiffPrev = Array(repeating: 0, count: 100)
        self.err1SG1min = Array(repeating: 0, count: 180)
        self.err1Time1min = Array(repeating: 0, count: 180)
        self.err1InA1min = Array(repeating: 0, count: 180)
        self.err1ResultPrev = 0
        self.err1TDTemporaryBreakFlagPastRange = Array(repeating: 0, count: 36)
        self.err1SumResultConditionTD = 0
        self.err1AnyResultConditionTD = 0
        self.err2DelayCondiPrev = 0
        self.err2DelayFlagPrev = Array(repeating: 0, count: 575)
        self.err2DelayRocPrev = Array(repeating: 0, count: 575)
        self.err2DelaySlopeSharpPrev = Array(repeating: 0, count: 575)
        self.err2DelayGlucosevaluePrev = Array(repeating: 0, count: 575)
        self.err2DelayRocCummaxPrev = 0
        self.err2DelaySlopeCummaxPrev = 0
        self.err2DelayGluCummaxPrev = 0
        self.err2DelayPreCondiPrev = Array(repeating: 0, count: 3)
        self.err2DelayRevisedValuePrev = 0
        self.err2Cummax = 0
        self.err2CummaxForetime = Array(repeating: 0, count: 100)
        self.err2ResultPrev = 0
        self.err4InA = Array(repeating: 0, count: 390)
        self.err4MinPrev = Array(repeating: 0, count: 289)
        self.err4RangePrev = Array(repeating: 0, count: 51)
        self.err4MinDiffPrev = Array(repeating: 0, count: 289)
        self.err4DelayFlagArr = Array(repeating: 0, count: 576)
        self.err4ResultPrev = 0
        self.err8ResultPrev = 0
        self.err128FlagPrev = Array(repeating: 0, count: 40)
        self.err128NormalPrev = 0
        self.err128RevisedValuePrev = 0
        self.err128CgmCNoiseRevisedValue = Array(repeating: 0, count: 36)
        self.err16Time5First = 0
        self.err16DtArr = Array(repeating: 0, count: 36)
        self.err16CalConsIsFirst = 0
        self.err16CalConsSeq = Array(repeating: 0, count: 50)
        self.err16CalConsTime = Array(repeating: 0, count: 50)
        self.err16CalConsBgm = Array(repeating: 0, count: 50)
        self.err16CalConsDUsercalBefore = Array(repeating: 0, count: 50)
        self.err16CalConsDUsercalAfter = Array(repeating: 0, count: 50)
        self.err16CalDayI = 0
        self.err16CalDayIsFirst = 0
        self.err16CalDayIdxRef = Array(repeating: 0, count: 30)
        self.err16CalDayDRef = 0
        self.err16CalDayDTemp = 0
        self.err16CalDayDValue = Array(repeating: 0, count: 30)
        self.err16CalDayNRef = 0
        self.err16CalDayNValue = Array(repeating: 0, count: 30)
        self.err16CgmIsfSmooth = Array(repeating: 0, count: 865)
        self.err16CgmPlasma = Array(repeating: 0, count: 36)
        self.err16CgmIsfRocN = 0
        self.err16CgmIsfRocValue = Array(repeating: 0, count: 577)
        self.err16CgmIsfRocSteady = Array(repeating: 0, count: 36)
        self.err16CgmIsfRocMinTemp = Array(repeating: 0, count: 865)
        self.err16CgmIsfRocMin = 0
        self.err16CgmIsfRocDiff = Array(repeating: 0, count: 36)
        self.err16CgmIsfRocRatio = Array(repeating: 0, count: 36)
        self.err16CgmIsfTrendMinN = 0
        self.err16CgmIsfTrendMinValue = 0
        self.err16CgmIsfTrendMinValuePrev = 0
        self.err16CgmIsfTrendMinValueArr = Array(repeating: 0, count: 865)
        self.err16CgmIsfTrendMinSlope1 = Array(repeating: 0, count: 36)
        self.err16CgmIsfTrendMinSlope2 = Array(repeating: 0, count: 36)
        self.err16CgmIsfTrendMinRsq1 = Array(repeating: 0, count: 36)
        self.err16CgmIsfTrendMinRsq2 = Array(repeating: 0, count: 36)
        self.err16CgmIsfTrendMinDiff = Array(repeating: 0, count: 36)
        self.err16CgmIsfTrendMinRatio = Array(repeating: 0, count: 36)
        self.err16CgmIsfTrendMinMax = 0
        self.err16CgmIsfTrendMinMaxTemp = Array(repeating: 0, count: 865)
        self.err16CgmIsfTrendMinMaxPrev = 0
        self.err16CgmIsfTrendMinMaxEarly = 0
        self.err16CgmIsfTrendModeN = 0
        self.err16CgmIsfTrendModeValue = 0
        self.err16CgmIsfTrendModeValuePrev = 0
        self.err16CgmIsfTrendModeProportion = Array(repeating: 0, count: 36)
        self.err16CgmIsfTrendModeDiff = Array(repeating: 0, count: 36)
        self.err16CgmIsfTrendModeRatio = Array(repeating: 0, count: 36)
        self.err16CgmIsfTrendModeMax = 0
        self.err16CgmIsfTrendModeMaxTemp = Array(repeating: 0, count: 865)
        self.err16CgmIsfTrendModeMaxPrev = 0
        self.err16CgmIsfTrendModeMaxEarly = 0
        self.err16CgmIsfTrendMeanIsFirst = 0
        self.err16CgmIsfTrendMeanN = 0
        self.err16CgmIsfTrendMeanValue = 0
        self.err16CgmIsfTrendMeanValuePrev = 0
        self.err16CgmIsfTrendMeanValueArr = Array(repeating: 0, count: 865)
        self.err16CgmIsfTrendMeanSlope = Array(repeating: 0, count: 36)
        self.err16CgmIsfTrendMeanRsq = Array(repeating: 0, count: 36)
        self.err16CgmIsfTrendMeanDiff = Array(repeating: 0, count: 36)
        self.err16CgmIsfTrendMeanRatio = Array(repeating: 0, count: 36)
        self.err16CgmIsfTrendMeanMax = 0
        self.err16CgmIsfTrendMeanMaxTemp = Array(repeating: 0, count: 865)
        self.err16CgmIsfTrendMeanMaxPrev = 0
        self.err16CgmIsfTrendMeanMaxEarly = 0
        self.err16CgmIsfTrendMeanMaxEarlyPrev = 0
        self.err16CgmIsfTrendMeanDiffEarly = Array(repeating: 0, count: 36)
        self.err16CgmIsfTrendMeanMaxTempEarly = Array(repeating: 0, count: 865)
        self.err16CgmIsfTrendMeanRatioEarly = Array(repeating: 0, count: 36)
        self.err16ResultPrev = 0
        self.err32PrevTime = 0
        self.err32PrevSeq = 0
        self.err32Buff23 = Array(repeating: 0, count: 4)
        self.err32Buff60 = Array(repeating: 0, count: 2)
        self.err32Buff600 = 0
        self.err32N = Array(repeating: 0, count: 3)
        self.err32ResultPrev = 0
    }
}

/// Device info from BLE advertisement (446 bytes packed in C).
/// Maps to air1_opcal4_device_info_t.
public struct DeviceInfo: Codable {
    public var sensorVersion: Int
    public var ycept: Float
    public var slope100: Float
    public var slope: Float
    public var r2: Float
    public var t90: Float
    public var slopeRatio: Float
    public var lot: String
    public var sensorId: String
    public var expiryDate: String
    public var stabilizationInterval: Int
    public var cgmDataInterval: Int
    public var bleAdvInterval: Int
    public var bleAdvDuration: Int
    public var age: Int
    public var allowedList: Int
    public var maximumValue: Float
    public var minimumValue: Float
    public var cLibraryVersion: Int
    public var parameterVersion: Int
    public var basicWarmup: Int
    public var basicYcept: Float
    public var contactWinLen: Int
    public var contactCond1X10: Int
    public var contactCond2X10: Int
    public var contactCond3X10: Int
    public var fillFlag: Int
    public var driftCorrectionOn: Int
    public var driftCoefficient: [[Float]]
    public var iRefX100: Int
    public var coefLength: Int
    public var divPoint: Int
    public var iirFlag: Int
    public var iirStDX10: Int
    public var correct1Flag: Int
    public var correct1Coeff: [Float]
    public var kalmanT90: Int
    public var kalmanDeltaT: Int
    public var kalmanQX100: [[Int]]
    public var kalmanRX100: Int
    public var bgCalRatio: Float
    public var bgCalTimeFactor: Int
    public var slopeFactorX10: Int
    public var slopeInterUpX10: Int
    public var slopeInterDownX10: Int
    public var slopeMultiVX10: Int
    public var slopeIirThr: Int
    public var slopeNegInterThr1X10: Int
    public var slopeNegInterThr2X10: Int
    public var slopeBgCalThrDown: Int
    public var slopeBgCalThrUp: Int
    public var slopeMaxSlopeX100: Int
    public var slopeMinSlopeX100: Int
    public var slopeDcalRate: Float
    public var slopeDcalTargetLength: Int
    public var slopeDcalWindow: Int
    public var slopeDcalFactoryCalUse: Int
    public var shiftMSel: Int
    public var shiftCoeff: [Float]
    public var shiftM2X100: [Int]
    public var wSgX100: [Int]
    public var calTrendRate: Int
    public var calNoise: Float
    public var errcodeVersion: Int
    public var err1Seq: [Int]
    public var err1ContactBad: Float
    public var err1ThDiff: Float
    public var err1ThSseDmean: [Float]
    public var err1ThN1: [Int]
    public var err1ThN2: [[Int]]
    public var err1NConsecutive: Int
    public var err1ISseDmeanNow: [Float]
    public var err1CountSseDmean: Int
    public var err1NLast: Int
    public var err1Multi: [Int]
    public var err1CurrentAvgDiff: Float
    public var err2StartSeq: Int
    public var err2Seq: [Int]
    public var err2Glu: Float
    public var err2Cv: [Float]
    public var err2Cummax: Int
    public var err2Multi: Int
    public var err2Ycept: Float
    public var err2Alpha: Float
    public var err345Seq1: [Int]
    public var err345Seq2: Int
    public var err345Seq3: [Int]
    public var err345Seq4: [Int]
    public var err345Seq5: [Int]
    public var err345Raw: [Float]
    public var err345Filtered: [Float]
    public var err345Min: [Float]
    public var err345Range: Float
    public var err345NRange: Int
    public var err345Md: Float
    public var err345NMd: Int
    public var err6CalNPts: Int
    public var err6CalBasicPrct: Float
    public var err6CalBasicSeq: Int
    public var err6CalOriginSlope: Float
    public var err6CalInVitro: [Float]
    public var err6CgmRpd: Float
    public var err6CgmSlp: Float
    public var err6CgmLow3dSeq: Int
    public var err6CgmLow3dP: Float
    public var err6CgmLow1dSeq: Int
    public var err6CgmLow1dP: Float
    public var err6CgmPrct: [Int]
    public var err6CgmDay: [Int]
    public var err6CgmBleBad: [Int]
    public var err6CgmPoly2: Float
    public var err32Dt: [Int]
    public var err32N: [Int]
    public var vref: Float
    public var eapp: Float
    public var sensorStartTime: Int64
    
    public init() {
        self.sensorVersion = 0
        self.ycept = 0
        self.slope100 = 0
        self.slope = 0
        self.r2 = 0
        self.t90 = 0
        self.slopeRatio = 0
        self.lot = ""
        self.sensorId = ""
        self.expiryDate = ""
        self.stabilizationInterval = 0
        self.cgmDataInterval = 0
        self.bleAdvInterval = 0
        self.bleAdvDuration = 0
        self.age = 0
        self.allowedList = 0
        self.maximumValue = 0
        self.minimumValue = 0
        self.cLibraryVersion = 0
        self.parameterVersion = 0
        self.basicWarmup = 0
        self.basicYcept = 0
        self.contactWinLen = 0
        self.contactCond1X10 = 0
        self.contactCond2X10 = 0
        self.contactCond3X10 = 0
        self.fillFlag = 0
        self.driftCorrectionOn = 0
        self.driftCoefficient = [[Float]](repeating: [Float](repeating: 0, count: 3), count: 3)
        self.iRefX100 = 0
        self.coefLength = 0
        self.divPoint = 0
        self.iirFlag = 0
        self.iirStDX10 = 0
        self.correct1Flag = 0
        self.correct1Coeff = [Float](repeating: 0, count: 4)
        self.kalmanT90 = 0
        self.kalmanDeltaT = 0
        self.kalmanQX100 = [[Int]](repeating: [Int](repeating: 0, count: 3), count: 3)
        self.kalmanRX100 = 0
        self.bgCalRatio = 0
        self.bgCalTimeFactor = 0
        self.slopeFactorX10 = 0
        self.slopeInterUpX10 = 0
        self.slopeInterDownX10 = 0
        self.slopeMultiVX10 = 0
        self.slopeIirThr = 0
        self.slopeNegInterThr1X10 = 0
        self.slopeNegInterThr2X10 = 0
        self.slopeBgCalThrDown = 0
        self.slopeBgCalThrUp = 0
        self.slopeMaxSlopeX100 = 0
        self.slopeMinSlopeX100 = 0
        self.slopeDcalRate = 0
        self.slopeDcalTargetLength = 0
        self.slopeDcalWindow = 0
        self.slopeDcalFactoryCalUse = 0
        self.shiftMSel = 0
        self.shiftCoeff = [Float](repeating: 0, count: 4)
        self.shiftM2X100 = [Int](repeating: 0, count: 3)
        self.wSgX100 = [Int](repeating: 0, count: 7)
        self.calTrendRate = 0
        self.calNoise = 0
        self.errcodeVersion = 0
        self.err1Seq = [Int](repeating: 0, count: 3)
        self.err1ContactBad = 0
        self.err1ThDiff = 0
        self.err1ThSseDmean = [Float](repeating: 0, count: 3)
        self.err1ThN1 = [Int](repeating: 0, count: 4)
        self.err1ThN2 = [[Int]](repeating: [Int](repeating: 0, count: 2), count: 2)
        self.err1NConsecutive = 0
        self.err1ISseDmeanNow = [Float](repeating: 0, count: 2)
        self.err1CountSseDmean = 0
        self.err1NLast = 0
        self.err1Multi = [Int](repeating: 0, count: 2)
        self.err1CurrentAvgDiff = 0
        self.err2StartSeq = 0
        self.err2Seq = [Int](repeating: 0, count: 3)
        self.err2Glu = 0
        self.err2Cv = [Float](repeating: 0, count: 3)
        self.err2Cummax = 0
        self.err2Multi = 0
        self.err2Ycept = 0
        self.err2Alpha = 0
        self.err345Seq1 = [Int](repeating: 0, count: 2)
        self.err345Seq2 = 0
        self.err345Seq3 = [Int](repeating: 0, count: 3)
        self.err345Seq4 = [Int](repeating: 0, count: 5)
        self.err345Seq5 = [Int](repeating: 0, count: 3)
        self.err345Raw = [Float](repeating: 0, count: 4)
        self.err345Filtered = [Float](repeating: 0, count: 2)
        self.err345Min = [Float](repeating: 0, count: 2)
        self.err345Range = 0
        self.err345NRange = 0
        self.err345Md = 0
        self.err345NMd = 0
        self.err6CalNPts = 0
        self.err6CalBasicPrct = 0
        self.err6CalBasicSeq = 0
        self.err6CalOriginSlope = 0
        self.err6CalInVitro = [Float](repeating: 0, count: 2)
        self.err6CgmRpd = 0
        self.err6CgmSlp = 0
        self.err6CgmLow3dSeq = 0
        self.err6CgmLow3dP = 0
        self.err6CgmLow1dSeq = 0
        self.err6CgmLow1dP = 0
        self.err6CgmPrct = [Int](repeating: 0, count: 3)
        self.err6CgmDay = [Int](repeating: 0, count: 2)
        self.err6CgmBleBad = [Int](repeating: 0, count: 2)
        self.err6CgmPoly2 = 0
        self.err32Dt = [Int](repeating: 0, count: 2)
        self.err32N = [Int](repeating: 0, count: 2)
        self.vref = 0
        self.eapp = 0
        self.sensorStartTime = 0
    }
}

/// User calibration list — BG reference values for factory-cal override (751 bytes packed in C).
/// Maps to air1_opcal4_cal_list_t.
public struct CalibrationList: Codable {
    public var idx: [Int]
    public var value: [Double]
    public var time: [Int64]
    public var calListLength: Int
    public var calFlag: [Int]
    
    public init() {
        self.idx = [Int](repeating: 0, count: 50)
        self.value = [Double](repeating: 0, count: 50)
        self.time = [Int64](repeating: 0, count: 50)
        self.calListLength = 0
        self.calFlag = [Int](repeating: 0, count: 50)
    }
}

// MARK: - CareSensCalibrator

/// Main facade for CareSens Air CGM calibration.
///
/// This is the primary entry point for CGM apps to integrate the CareSens Air calibration algorithm.
/// It wraps the internal 14-step calibration pipeline behind a simple API.
public final class CareSensCalibrator {
    
    private let deviceInfo: DeviceInfo
    private var state: AlgorithmState
    private let calList: CalibrationList
    private var readingsProcessed: Int
    
    /// Serialization format version. Increment when AlgorithmState layout changes.
    private static let STATE_VERSION: Int32 = 1
    
    /// Create a new calibrator for a CareSens Air sensor.
    /// - Parameter config: sensor factory calibration parameters (from BLE advertisement)
    /// - Throws: NullPointerException if config is null
    public init(_ config: SensorConfig) throws {
        guard config != nil else {
            throw NSError(domain: "CareSensCalibrator", code: 1, userInfo: [NSLocalizedDescriptionKey: "SensorConfig must not be null"])
        }
        self.deviceInfo = config.toDeviceInfo()
        self.state = AlgorithmState()
        self.calList = CalibrationList()
        self.readingsProcessed = 0
    }
    
    /// Process one raw CGM reading through the full calibration pipeline.
    ///
    /// Call this once per sensor reading (typically every 5 minutes).
    /// The calibrator maintains internal state between calls, so readings
    /// must be processed in order.
    /// - Parameters:
    ///   - seqNumber: sensor sequence number (starts at 1, increments each reading)
    ///   - timestamp: measurement time in Unix seconds
    ///   - adcSamples: 30 raw ADC sample values from the sensor
    ///   - temperature: skin temperature in degrees Celsius
    /// - Returns: immutable calibration result
    /// - Throws: IllegalArgumentException if adcSamples is null or not length 30
    public func processReading(seqNumber: Int, timestamp: Int64, adcSamples: [Int], temperature: Double) throws -> CalibrationResult {
        guard adcSamples != nil else {
            throw NSError(domain: "CareSensCalibrator", code: 2, userInfo: [NSLocalizedDescriptionKey: "adcSamples must not be null"])
        }
        guard adcSamples.count == 30 else {
            throw NSError(domain: "CareSensCalibrator", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "adcSamples must have exactly 30 elements",
                NSLocalizedRecoverySuggestionErrorKey: "got \(adcSamples.count)"
            ])
        }
        
        // Build internal input
        let input = CgmInput()
        input.seqNumber = seqNumber
        input.measurementTimeStandard = timestamp
        input.temperature = temperature
        for i in 0..<30 {
            input.workout[i] = adcSamples[i]
        }
        
        // Run the pipeline
        let output = AlgorithmOutput()
        let debug = DebugOutput()
        CalibrationAlgorithm.process(deviceInfo, input, calList, &state, &output, &debug)
        
        readingsProcessed += 1
        
        // Build immutable result
        return CalibrationResult(
            glucose: output.resultGlucose,
            trend: output.trendrate,
            errcode: output.errcode,
            stage: output.currentStage,
            calAvailable: output.calAvailableFlag,
            smoothGlucose: output.smoothResultGlucose,
            smoothSeq: output.smoothSeq,
            smoothFixed: output.smoothFixedFlag
        )
    }
    
    /// Whether the sensor has completed its warmup period.
    ///
    /// During warmup, glucose values may be less accurate. The warmup
    /// period is defined by the sensor's factory calibration parameters
    /// (typically 5-10 readings).
    public func isWarmedUp() -> Bool {
        return readingsProcessed > 0 && state.idxOriginSeq > deviceInfo.err345Seq2
    }
    
    /// Number of readings processed since creation or last restore.
    public func getReadingsProcessed() -> Int {
        return readingsProcessed
    }
    
    /// Serialize the current calibrator state for persistence.
    ///
    /// The returned byte array can be stored in UserDefaults, a database,
    /// or any other storage mechanism. Use `restoreState(_:config:)` to reconstruct the calibrator later.
    /// - Returns: serialized state bytes
    /// - Throws: RuntimeException if serialization fails
    public func saveState() throws -> Data {
        let version: Int32 = STATE_VERSION
        let readings: Int32 = Int32(readingsProcessed)
        
        var buffer = Data()
        buffer.append(contentsOf: "OCSA".data(using: .utf8)!)
        buffer.append(Data(bytes: &version, count: MemoryLayout<Int32>.size))
        buffer.append(Data(bytes: &readings, count: MemoryLayout<Int32>.size))
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        let stateData = try encoder.encode(state)
        buffer.append(stateData)
        
        return buffer
    }
    
    /// Restore a calibrator from previously saved state.
    ///
    /// The `config` must match the sensor that produced the saved state.
    /// Using a different sensor's config with saved state from another sensor
    /// will produce incorrect glucose values.
    /// - Parameters:
    ///   - stateBytes: serialized state from `saveState()`
    ///   - config: sensor factory calibration parameters
    /// - Returns: restored calibrator
    /// - Throws: StateError if stateBytes is null or empty or corrupted
    public static func restoreState(_ stateBytes: Data, _ config: SensorConfig) throws -> CareSensCalibrator {
        guard stateBytes != nil && !stateBytes.isEmpty else {
            throw StateError.emptyData
        }
        
        var offset = 0
        
        // Read magic
        let magic = String(data: stateBytes.subdata(in: offset..<offset+4), encoding: .utf8)
        guard magic == "OCSA" else {
            throw StateError.corruptedData
        }
        offset += 4
        
        // Read version
        let version = Int32(stateBytes[Int64(offset)] | Int64(offset+1) << 8 | Int64(offset+2) << 16 | Int64(offset+3) << 24)
        offset += 4
        
        if version != STATE_VERSION {
            throw StateError.incompatibleVersion
        }
        
        // Read readingsProcessed
        let readings = Int32(stateBytes[Int64(offset)] | Int64(offset+1) << 8 | Int64(offset+2) << 16 | Int64(offset+3) << 24)
        offset += 4
        
        // Read AlgorithmState
        let decoder = JSONDecoder()
        decoder.keyEncodingStrategy = .useDefaultKeys
        let state = try decoder.decode(AlgorithmState.self, from: stateBytes.subdata(in: offset..<stateBytes.count))
        
        let calibrator = try CareSensCalibrator(config)
        calibrator.state = state
        calibrator.readingsProcessed = Int(readings)
        return calibrator
    }
}

/// Calibration result from a single reading.
public struct CalibrationResult {
    public let glucose: Double
    public let trend: Double
    public let errcode: Int
    public let stage: Int
    public let calAvailable: Int
    public let smoothGlucose: [Double]
    public let smoothSeq: [Int]
    public let smoothFixed: [Int]
    
    public init(glucose: Double, trend: Double, errcode: Int, stage: Int, calAvailable: Int, smoothGlucose: [Double], smoothSeq: [Int], smoothFixed: [Int]) {
        self.glucose = glucose
        self.trend = trend
        self.errcode = errcode
        self.stage = stage
        self.calAvailable = calAvailable
        self.smoothGlucose = smoothGlucose
        self.smoothSeq = smoothSeq
        self.smoothFixed = smoothFixed
    }
    
    /// Whether the result is valid (calibration available and no error).
    public var isValid: Bool {
        return calAvailable != 0 && errcode == 0
    }
}

/// Custom state errors for restoreState.
public enum StateError: Error, CustomStringConvertible {
    case emptyData
    case corruptedData
    case incompatibleVersion
    
    public var description: String {
        switch self {
        case .emptyData:
            return "State data is empty"
        case .corruptedData:
            return "State data is corrupted (invalid magic or format)"
        case .incompatibleVersion:
            return "State version is incompatible"
        }
    }
}
