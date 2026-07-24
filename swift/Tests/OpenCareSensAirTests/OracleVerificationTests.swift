// MARK: - Imports and Constants

import Foundation
import XCTest
@testable import OpenCareSensAir

// MARK: - Tolerance Constants

// Tolerance: doubles match if abs_err < 1e-12 OR rel_err < 1e-10
private let absTol: Double = 1e-12
private let relTol: Double = 1e-10

private let readingsPerLot: Int = 400

// MARK: - Oracle Data Path

// Oracle data root (relative to project root)
private let oracleRoot: String = "../oracle/output"

// Lot configurations: eapp value per lot (matches run_oracle.sh LOT_DEFS)
private let lotEapp: [Float] = [
    0.10067,  // lot0: standard eapp, normal glucose
    0.15,     // lot1: high eapp, normal glucose
    0.05,     // lot2: low eapp, normal glucose
    0.10067,  // lot3: standard eapp, hypo profile
    0.10067,  // lot4: standard eapp, hyper profile
]

// MARK: - Oracle Base Path

private var oracleBase: String?

// MARK: - Before All Setup

func findOracleData() {
    // Try relative path from swift/ directory, then absolute
    let rel = URL(fileURLWithPath: oracleRoot)
    let abs = URL(fileURLWithPath: "/Users/erik/github.com/erikdebruijn/OpenCareSens-air/oracle/output")
    if FileManager.default.fileExists(atPath: rel.path) {
        oracleBase = rel.path
    } else if FileManager.default.fileExists(atPath: abs.path) {
        oracleBase = abs.path
    } else {
        oracleBase = nil
    }
}

// MARK: - DeviceInfo Setup

/// Factory calibration parameters from sensor BLE advertisement.
/// Must match oracle_harness.c init_default_device_info() exactly.
private func createDefaultDeviceInfo(eapp: Float) -> DeviceInfo {
    let di = DeviceInfo()
    di.sensorVersion = 1
    di.ycept = 1.0
    di.slope100 = 3.5226
    di.slope = 1.0
    di.r2 = 0.0
    di.t90 = 0.0
    di.slopeRatio = 1.0
    di.lot = ""
    di.sensorId = ""
    di.expiryDate = ""
    di.stabilizationInterval = 7200
    di.cgmDataInterval = 300
    di.bleAdvInterval = 300
    di.bleAdvDuration = 10
    di.age = 18
    di.allowedList = 1
    di.maximumValue = 500.0
    di.minimumValue = 40.0
    di.cLibraryVersion = 3
    di.parameterVersion = 3
    di.basicWarmup = 24
    di.basicYcept = 0.0
    di.contactWinLen = 30
    di.contactCond1X10 = 5
    di.contactCond2X10 = 1
    di.contactCond3X10 = 2
    di.fillFlag = 1
    di.driftCorrectionOn = 0
    di.driftCoefficient[0][2] = 1.0
    di.driftCoefficient[1][2] = 1.0
    di.driftCoefficient[2][2] = 1.0
    di.iRefX100 = 100
    di.coefLength = 1
    di.divPoint = 1
    di.iirFlag = 1
    di.iirStDX10 = 90
    di.correct1Flag = 1
    di.correct1Coeff[2] = 1.0
    di.kalmanT90 = 10
    di.kalmanDeltaT = 5
    di.kalmanQX100[0][0] = -115
    di.kalmanQX100[1][1] = 1440
    di.kalmanQX100[2][2] = 10
    di.kalmanRX100 = 200
    di.bgCalRatio = 1.0
    di.bgCalTimeFactor = 0
    di.slopeFactorX10 = 20
    di.slopeInterUpX10 = 10
    di.slopeInterDownX10 = -20
    di.slopeMultiVX10 = 20
    di.slopeIirThr = 20
    di.slopeNegInterThr1X10 = 5
    di.slopeNegInterThr2X10 = 8
    di.slopeBgCalThrDown = 70
    di.slopeBgCalThrUp = 100
    di.slopeMaxSlopeX100 = 76
    di.slopeMinSlopeX100 = 40
    di.slopeDcalRate = 0.6
    di.slopeDcalTargetLength = 108
    di.slopeDcalWindow = 888
    di.slopeDcalFactoryCalUse = 0
    di.shiftMSel = 1
    di.shiftCoeff[2] = 1.0
    di.shiftM2X100[0] = 17
    di.shiftM2X100[1] = 2000
    di.shiftM2X100[2] = 111
    di.wSgX100[0] = 80
    di.wSgX100[1] = 130
    di.wSgX100[2] = 90
    di.wSgX100[3] = 80
    di.wSgX100[4] = 110
    di.wSgX100[5] = 90
    di.wSgX100[6] = 80
    di.calTrendRate = 3
    di.calNoise = 3.0
    di.errcodeVersion = 2
    di.err1Seq[0] = 23
    di.err1Seq[1] = 47
    di.err1Seq[2] = 11
    di.err1ContactBad = 0.5
    di.err1ThDiff = 2.0
    di.err1ThSseDmean[0] = 0.05
    di.err1ThSseDmean[1] = 0.1
    di.err1ThSseDmean[2] = 0.5
    di.err1ThN1[0] = 43
    di.err1ThN1[1] = 40
    di.err1ThN1[2] = 37
    di.err1ThN1[3] = 34
    di.err1ThN2[0][0] = 2
    di.err1ThN2[0][1] = 6
    di.err1ThN2[1][0] = 4
    di.err1ThN2[1][1] = 8
    di.err1NConsecutive = 6
    di.err1ISseDmeanNow[0] = 3.0
    di.err1ISseDmeanNow[1] = 0.001
    di.err1CountSseDmean = 12
    di.err1NLast = 288
    di.err1Multi[0] = 10
    di.err1Multi[1] = 10
    di.err1CurrentAvgDiff = 1.0e-15
    di.err2StartSeq = 289
    di.err2Seq[0] = 20
    di.err2Seq[1] = 11
    di.err2Seq[2] = 6
    di.err2Glu = 800.0
    di.err2Cv[0] = 10.0
    di.err2Cv[1] = 0.05
    di.err2Cv[2] = 10.0
    di.err2Cummax = 2
    di.err2Multi = 10
    di.err2Ycept = 2.0
    di.err2Alpha = 2.0
    di.err345Seq1[0] = 3
    di.err345Seq1[1] = 576
    di.err345Seq2 = 5
    di.err345Seq3[0] = 5
    di.err345Seq3[1] = 864
    di.err345Seq3[2] = 24
    di.err345Seq4[0] = 11
    di.err345Seq4[1] = 23
    di.err345Seq4[2] = 12
    di.err345Seq4[3] = 288
    di.err345Seq4[4] = 24
    di.err345Seq5[0] = 11
    di.err345Seq5[1] = 36
    di.err345Seq5[2] = 288
    di.err345Raw[0] = 0.1
    di.err345Raw[1] = 0.5
    di.err345Raw[2] = 0.2
    di.err345Raw[3] = 0.7
    di.err345Filtered[0] = 0.2
    di.err345Filtered[1] = 1.0
    di.err345Min[0] = 0.5
    di.err345Min[1] = 0.3
    di.err345Range = -1.0
    di.err345NRange = 2
    di.err345Md = 0.0
    di.err345NMd = 6
    di.err6CalNPts = 3
    di.err6CalBasicPrct = 0.3
    di.err6CalBasicSeq = 1440
    di.err6CalOriginSlope = 30.0
    di.err6CalInVitro[0] = 0.0
    di.err6CalInVitro[1] = 2.0
    di.err6CgmRpd = 0.55
    di.err6CgmSlp = -0.2
    di.err6CgmLow3dSeq = 24
    di.err6CgmLow3dP = 0.32
    di.err6CgmLow1dSeq = 24
    di.err6CgmLow1dP = 0.3
    di.err6CgmPrct[0] = 30
    di.err6CgmPrct[1] = 50
    di.err6CgmPrct[2] = 70
    di.err6CgmDay[0] = 1
    di.err6CgmDay[1] = 3
    di.err6CgmBleBad[0] = 12
    di.err6CgmBleBad[1] = 96
    di.err6CgmPoly2 = 0.7
    di.err32Dt[0] = 23
    di.err32Dt[1] = 60
    di.err32N[0] = 3
    di.err32N[1] = 2
    di.vref = 1.49594
    di.eapp = eapp
    di.sensorStartTime = 1709726400  // 2024-03-06 12:00:00 UTC
    return di
}

// MARK: - Field Comparison Infrastructure

/** Tracks match/mismatch stats for a single named field across all readings. */
struct FieldStats {
    let name: String
    var total: Int = 0
    var match: Int = 0
    var mismatch: Int = 0
    var maxAbsErr: Double = 0.0
    var maxRelErr: Double = 0.0
    var firstMismatchSeq: Int = 0
    var firstMismatchDetail: String?

    func recordMatch() {
        total += 1
        match += 1
    }

    func recordMismatch(_ seq: Int, _ detail: String) {
        total += 1
        mismatch += 1
        if firstMismatchSeq == 0 {
            firstMismatchSeq = seq
            firstMismatchDetail = detail
        }
    }

    func recordDoubleMismatch(_ seq: Int, _ ours: Double, _ oracle: Double, _ absErr: Double, _ relErr: Double) {
        total += 1
        mismatch += 1
        if absErr > maxAbsErr { maxAbsErr = absErr }
        if relErr > maxRelErr { maxRelErr = relErr }
        if firstMismatchSeq == 0 {
            firstMismatchSeq = seq
            firstMismatchDetail = String(
                "ours=%.10g oracle=%.10g (abs=%.2e rel=%.2e)",
                ours, oracle, absErr, relErr
            )
        }
    }

    func recordDoubleMatch(_ absErr: Double, _ relErr: Double) {
        total += 1
        match += 1
        if absErr > maxAbsErr { maxAbsErr = absErr }
        if relErr > maxRelErr { maxRelErr = relErr }
    }
}

/** Compare a double value with oracle tolerance. */
func compareDouble(_ fs: inout FieldStats, _ seq: Int, _ ours: Double, _ oracle: Double) -> Bool {
    if Double.isNaN(ours) && Double.isNaN(oracle) {
        fs.recordMatch()
        return true
    }
    if Double.isNaN(ours) || Double.isNaN(oracle) {
        fs.recordMismatch(seq, String("ours=%g oracle=%g", ours, oracle))
        return false
    }
    if ours == oracle {
        fs.recordMatch()
        return true
    }
    let absErr = abs(ours - oracle)
    let relErr = (abs(oracle) > 1e-10) ? absErr / abs(oracle) : absErr
    if absErr < absTol || relErr < relTol {
        fs.recordDoubleMatch(absErr, relErr)
        return true
    }
    fs.recordDoubleMismatch(seq, ours, oracle, absErr, relErr)
    return false
}

/** Compare an integer value with oracle (bit-exact). */
func compareInt(_ fs: inout FieldStats, _ seq: Int, _ ours: Int64, _ oracle: Int64) -> Bool {
    if ours == oracle {
        fs.recordMatch()
        return true
    }
    fs.recordMismatch(seq, String("ours=%d oracle=%d", ours, oracle))
    return false
}

// MARK: - Per-Lot Verification

struct LotResult {
    let lotNum: Int
    let readingsCompared: Int
    let glucoseMismatches: Int
    let errcodeMismatches: Int
    let calAvailableMismatches: Int
    let currentStageMismatches: Int
    let trendrateMismatches: Int
    let outputStats: [FieldStats]
    let debugStats: [FieldStats]
    let totalOutputMatch: Int
    let totalOutputMismatch: Int
    let totalDebugMatch: Int
    let totalDebugMismatch: Int

    init(lotNum: Int, readingsCompared: Int,
         glucoseMismatches: Int, errcodeMismatches: Int,
         calAvailableMismatches: Int, currentStageMismatches: Int,
         trendrateMismatches: Int,
         outputStats: [FieldStats], debugStats: [FieldStats]) {
        self.lotNum = lotNum
        self.readingsCompared = readingsCompared
        self.glucoseMismatches = glucoseMismatches
        self.errcodeMismatches = errcodeMismatches
        self.calAvailableMismatches = calAvailableMismatches
        self.currentStageMismatches = currentStageMismatches
        self.trendrateMismatches = trendrateMismatches
        self.outputStats = outputStats
        self.debugStats = debugStats
        var om = 0, omm = 0, dm = 0, dmm = 0
        for f in outputStats { om += f.match; omm += f.mismatch }
        for f in debugStats { dm += f.match; dmm += f.mismatch }
        self.totalOutputMatch = om
        self.totalOutputMismatch = omm
        self.totalDebugMatch = dm
        self.totalDebugMismatch = dmm
    }
}

func runLotVerification(_ lotNum: Int) throws -> LotResult {
    let lotDir = oracleBase! + "/lot" + String(lotNum)
    try XCTSkipIf(!FileManager.default.fileExists(atPath: lotDir),
                  "Oracle data not found for lot\(lotNum) at \(lotDir)")

    let devInfo = createDefaultDeviceInfo(eapp: lotEapp[lotNum])
    let algoArgs = AlgorithmState()
    let calInput = CalibrationList()

    // --- Output field stats ---
    var oSeqOriginal = FieldStats(name: "output.seq_number_original")
    var oSeqFinal = FieldStats(name: "output.seq_number_final")
    var oMeasTime = FieldStats(name: "output.measurement_time_standard")
    var oResultGlucose = FieldStats(name: "output.result_glucose")
    var oTrendrate = FieldStats(name: "output.trendrate")
    var oCurrentStage = FieldStats(name: "output.current_stage")
    var oErrcode = FieldStats(name: "output.errcode")
    var oCalAvailable = FieldStats(name: "output.cal_available_flag")
    var oDataType = FieldStats(name: "output.data_type")
    var oSmoothGlu: [FieldStats] = []
    for i in 0..<6 {
        oSmoothGlu.append(FieldStats(name: "output.smooth_result_glucose[\(i)]"))
    }

    // --- Debug field stats ---
    var dSeqOriginal = FieldStats(name: "debug.seq_number_original")
    var dSeqFinal = FieldStats(name: "debug.seq_number_final")
    var dMeasTime = FieldStats(name: "debug.measurement_time_standard")
    var dDataType = FieldStats(name: "debug.data_type")
    var dStage = FieldStats(name: "debug.stage")
    var dTemperature = FieldStats(name: "debug.temperature")
    var dTranInA1min: [FieldStats] = []
    for i in 0..<5 {
        dTranInA1min.append(FieldStats(name: "debug.tran_inA_1min[\(i)]"))
    }
    var dTranInA5min = FieldStats(name: "debug.tran_inA_5min")
    var dYcept = FieldStats(name: "debug.ycept")
    var dCorrectedReCurrent = FieldStats(name: "debug.corrected_re_current")
    var dDiabetesMeanX = FieldStats(name: "debug.diabetes_mean_x")
    var dDiabetesM2 = FieldStats(name: "debug.diabetes_M2")
    var dDiabetesTAR = FieldStats(name: "debug.diabetes_TAR")
    var dDiabetesTBR = FieldStats(name: "debug.diabetes_TBR")
    var dDiabetesCV = FieldStats(name: "debug.diabetes_CV")
    var dLevelDiabetes = FieldStats(name: "debug.level_diabetes")
    var dOutIir = FieldStats(name: "debug.out_iir")
    var dOutDrift = FieldStats(name: "debug.out_drift")
    var dCurrBaseline = FieldStats(name: "debug.curr_baseline")
    var dInitstableDiffDc = FieldStats(name: "debug.initstable_diff_dc")
    var dInitstableInitcnt = FieldStats(name: "debug.initstable_initcnt")
    var dTempLocalMean = FieldStats(name: "debug.temp_local_mean")
    var dSlopeRatioTemp = FieldStats(name: "debug.slope_ratio_temp")
    var dInitCg = FieldStats(name: "debug.init_cg")
    var dOutRescale = FieldStats(name: "debug.out_rescale")
    var dOpcalAd = FieldStats(name: "debug.opcal_ad")
    var dStateInitKalman = FieldStats(name: "debug.state_init_kalman")
    var dCalState = FieldStats(name: "debug.cal_state")
    var dStateReturnOpcal = FieldStats(name: "debug.state_return_opcal")
    var dValidBgTime = FieldStats(name: "debug.valid_bg_time")
    var dValidBgValue = FieldStats(name: "debug.valid_bg_value")
    var dCallogGroup = FieldStats(name: "debug.callog_group")
    var dCallogBgTime = FieldStats(name: "debug.callog_bgTime")
    var dCallogBgSeq = FieldStats(name: "debug.callog_bgSeq")
    var dCallogBgUser = FieldStats(name: "debug.callog_bgUser")
    var dCallogBgValid = FieldStats(name: "debug.callog_bgValid")
    var dCallogBgCal = FieldStats(name: "debug.callog_bgCal")
    var dCallogCgSeq1m = FieldStats(name: "debug.callog_cgSeq1m")
    var dCallogCgIdx = FieldStats(name: "debug.callog_cgIdx")
    var dCallogCgCal = FieldStats(name: "debug.callog_cgCal")
    var dCallogCslopePrev = FieldStats(name: "debug.callog_CslopePrev")
    var dCallogCyceptPrev = FieldStats(name: "debug.callog_CyceptPrev")
    var dCallogCslopeNew = FieldStats(name: "debug.callog_CslopeNew")
    var dCallogCyceptNew = FieldStats(name: "debug.callog_CyceptNew")
    var dCallogInlierFlg = FieldStats(name: "debug.callog_inlierFlg")
    var dInitstableWeightUsercal = FieldStats(name: "debug.initstable_weight_usercal")
    var dInitstableWeightNocal = FieldStats(name: "debug.initstable_weight_nocal")
    var dInitstableFixusercal = FieldStats(name: "debug.initstable_fixusercal")
    var dNOpcalState = FieldStats(name: "debug.nOpcalState")
    var dInitstableInitEndPoint = FieldStats(name: "debug.initstable_init_end_point")
    var dOutWeightAd = FieldStats(name: "debug.out_weight_ad")
    var dShiftoutAd = FieldStats(name: "debug.shiftout_ad")
    var dErrorCode1 = FieldStats(name: "debug.error_code1")
    var dErrorCode2 = FieldStats(name: "debug.error_code2")
    var dErrorCode4 = FieldStats(name: "debug.error_code4")
    var dErrorCode8 = FieldStats(name: "debug.error_code8")
    var dErrorCode16 = FieldStats(name: "debug.error_code16")
    var dErrorCode32 = FieldStats(name: "debug.error_code32")
    var dTrendrate = FieldStats(name: "debug.trendrate")
    var dCalAvailableFlag = FieldStats(name: "debug.cal_available_flag")
    // err1 fields
    var dErr1ISseDMean = FieldStats(name: "debug.err1_i_sse_d_mean")
    var dErr1ThSseDMean1 = FieldStats(name: "debug.err1_th_sse_d_mean1")
    var dErr1ThSseDMean2 = FieldStats(name: "debug.err1_th_sse_d_mean2")
    var dErr1ThSseDMean = FieldStats(name: "debug.err1_th_sse_d_mean")
    var dErr1IsContactBad = FieldStats(name: "debug.err1_is_contact_bad")
    var dErr1CurrentAvgDiff = FieldStats(name: "debug.err1_current_avg_diff")
    var dErr1ThDiff1 = FieldStats(name: "debug.err1_th_diff1")
    var dErr1ThDiff2 = FieldStats(name: "debug.err1_th_diff2")
    var dErr1ThDiff = FieldStats(name: "debug.err1_th_diff")
    var dErr1Isfirst0 = FieldStats(name: "debug.err1_isfirst0")
    var dErr1Isfirst1 = FieldStats(name: "debug.err1_isfirst1")
    var dErr1Isfirst2 = FieldStats(name: "debug.err1_isfirst2")
    var dErr1N = FieldStats(name: "debug.err1_n")
    var dErr1RandomNoiseTempBreak = FieldStats(name: "debug.err1_random_noise_temp_break")
    var dErr1Result = FieldStats(name: "debug.err1_result")
    var dErr1ResultTD = FieldStats(name: "debug.err1_result_TD")
    // err2 fields
    var dErr2DelayRevisedValue = FieldStats(name: "debug.err2_delay_revised_value")
    var dErr2DelayRoc = FieldStats(name: "debug.err2_delay_roc")
    var dErr2DelaySlopeSharp = FieldStats(name: "debug.err2_delay_slope_sharp")
    var dErr2DelayRocCummax = FieldStats(name: "debug.err2_delay_roc_cummax")
    var dErr2DelaySlopeCummax = FieldStats(name: "debug.err2_delay_slope_cummax")
    var dErr2DelayGluCummax = FieldStats(name: "debug.err2_delay_glu_cummax")
    var dErr2DelayFlag = FieldStats(name: "debug.err2_delay_flag")
    var dErr2Cummax = FieldStats(name: "debug.err2_cummax")
    var dErr2CrtCurrent: [FieldStats] = []
    for i in 0..<2 { dErr2CrtCurrent.append(FieldStats(name: "debug.err2_crt_current[\(i)]")) }
    var dErr2CrtGlu: [FieldStats] = []
    for i in 0..<2 { dErr2CrtGlu.append(FieldStats(name: "debug.err2_crt_glu[\(i)]")) }
    var dErr2Condi: [FieldStats] = []
    for i in 0..<2 { dErr2Condi.append(FieldStats(name: "debug.err2_condi[\(i)]")) }
    // err4 fields
    var dErr4Min = FieldStats(name: "debug.err4_min")
    var dErr4Range = FieldStats(name: "debug.err4_range")
    var dErr4MinDiff = FieldStats(name: "debug.err4_min_diff")
    // err16 fields
    var dErr16CgmPlasma = FieldStats(name: "debug.err16_CGM_plasma")
    var dErr16CgmIsfSmooth = FieldStats(name: "debug.err16_CGM_ISF_smooth")
    // err128 fields
    var dErr128Flag = FieldStats(name: "debug.err128_flag")
    var dErr128RevisedValue = FieldStats(name: "debug.err128_revised_value")
    var dErr128Normal = FieldStats(name: "debug.err128_normal")
    // tran_inA array
    var dTranInA = FieldStats(name: "debug.tran_inA[30]")

    // Collect all stats for reporting
    let allOutputStats: [FieldStats] = [
        oSeqOriginal, oSeqFinal, oMeasTime, oResultGlucose, oTrendrate,
        oCurrentStage, oErrcode, oCalAvailable, oDataType
    ] + oSmoothGlu

    let allDebugStats: [FieldStats] = [
        dSeqOriginal, dSeqFinal, dMeasTime, dDataType, dStage, dTemperature
    ] + dTranInA1min + [dTranInA5min, dYcept, dCorrectedReCurrent,
        dDiabetesMeanX, dDiabetesM2, dDiabetesTAR, dDiabetesTBR, dDiabetesCV,
        dLevelDiabetes, dOutIir, dOutDrift, dCurrBaseline, dInitstableDiffDc,
        dInitstableInitcnt, dTempLocalMean, dSlopeRatioTemp, dInitCg, dOutRescale,
        dOpcalAd, dStateInitKalman, dCalState, dStateReturnOpcal, dValidBgTime,
        dValidBgValue, dCallogGroup, dCallogBgTime, dCallogBgSeq, dCallogBgUser,
        dCallogBgValid, dCallogBgCal, dCallogCgSeq1m, dCallogCgIdx, dCallogCgCal,
        dCallogCslopePrev, dCallogCyceptPrev, dCallogCslopeNew, dCallogCyceptNew,
        dCallogInlierFlg, dInitstableWeightUsercal, dInitstableWeightNocal,
        dInitstableFixusercal, dNOpcalState, dInitstableInitEndPoint, dOutWeightAd,
        dShiftoutAd, dErrorCode1, dErrorCode2, dErrorCode4, dErrorCode8,
        dErrorCode16, dErrorCode32, dTrendrate, dCalAvailableFlag,
        dErr1ISseDMean, dErr1ThSseDMean1, dErr1ThSseDMean2, dErr1ThSseDMean,
        dErr1IsContactBad, dErr1CurrentAvgDiff, dErr1ThDiff1, dErr1ThDiff2,
        dErr1ThDiff, dErr1Isfirst0, dErr1Isfirst1, dErr1Isfirst2, dErr1N,
        dErr1RandomNoiseTempBreak, dErr1Result, dErr1ResultTD,
        dErr2DelayRevisedValue, dErr2DelayRoc, dErr2DelaySlopeSharp,
        dErr2DelayRocCummax, dErr2DelaySlopeCummax, dErr2DelayGluCummax,
        dErr2DelayFlag, dErr2Cummax
    ] + dErr2CrtCurrent + dErr2CrtGlu + dErr2Condi + [
        dErr4Min, dErr4Range, dErr4MinDiff,
        dErr16CgmPlasma, dErr16CgmIsfSmooth,
        dErr128Flag, dErr128RevisedValue, dErr128Normal,
        dTranInA
    ]

    var readingsCompared = 0
    var glucoseMismatches = 0
    var errcodeMismatches = 0
    var calAvailableMismatches = 0
    var currentStageMismatches = 0
    var trendrateMismatches = 0

    for seq in 1...readingsPerLot {
        // --- Load oracle input ---
        var cgmInput: CgmInput!
        do {
            cgmInput = try OracleBinaryReader.readInput(lotDir, seq)
        } catch {
            if seq == 1 { throw error }
            break  // no more readings
        }

        // --- Load oracle output and debug for comparison ---
        var oracleOutput: AlgorithmOutput!
        var oracleDebug: DebugOutput!
        do {
            oracleOutput = try OracleBinaryReader.readOutput(lotDir, seq)
            oracleDebug = try OracleBinaryReader.readDebug(lotDir, seq)
        } catch {
            break
        }

        // --- Run OUR algorithm ---
        let ourOutput = AlgorithmOutput()
        let ourDebug = DebugOutput()

        CalibrationAlgorithm.process(devInfo, cgmInput, calInput,
                                      algoArgs, ourOutput, ourDebug)

        // === Compare OUTPUT fields (safety-critical fields tracked separately) ===
        compareInt(&oSeqOriginal, seq, ourOutput.seqNumberOriginal, oracleOutput.seqNumberOriginal)
        compareInt(&oSeqFinal, seq, ourOutput.seqNumberFinal, oracleOutput.seqNumberFinal)
        compareInt(&oMeasTime, seq, ourOutput.measurementTimeStandard, oracleOutput.measurementTimeStandard)
        if !compareDouble(&oResultGlucose, seq, ourOutput.resultGlucose, oracleOutput.resultGlucose) {
            glucoseMismatches += 1
        }
        if !compareDouble(&oTrendrate, seq, ourOutput.trendrate, oracleOutput.trendrate) {
            trendrateMismatches += 1
        }
        if !compareInt(&oCurrentStage, seq, ourOutput.currentStage, oracleOutput.currentStage) {
            currentStageMismatches += 1
        }
        if !compareInt(&oErrcode, seq, ourOutput.errcode, oracleOutput.errcode) {
            errcodeMismatches += 1
        }
        if !compareInt(&oCalAvailable, seq, ourOutput.calAvailableFlag, oracleOutput.calAvailableFlag) {
            calAvailableMismatches += 1
        }
        compareInt(&oDataType, seq, ourOutput.dataType, oracleOutput.dataType)
        for i in 0..<6 {
            compareDouble(&oSmoothGlu[i], seq,
                ourOutput.smoothResultGlucose[i], oracleOutput.smoothResultGlucose[i])
        }

        // === Compare DEBUG fields ===
        compareInt(&dSeqOriginal, seq, ourDebug.seqNumberOriginal, oracleDebug.seqNumberOriginal)
        compareInt(&dSeqFinal, seq, ourDebug.seqNumberFinal, oracleDebug.seqNumberFinal)
        compareInt(&dMeasTime, seq, ourDebug.measurementTimeStandard, oracleDebug.measurementTimeStandard)
        compareInt(&dDataType, seq, ourDebug.dataType, oracleDebug.dataType)
        compareInt(&dStage, seq, ourDebug.stage, oracleDebug.stage)
        compareDouble(&dTemperature, seq, ourDebug.temperature, oracleDebug.temperature)
        for i in 0..<5 {
            compareDouble(&dTranInA1min[i], seq, ourDebug.tranInA1min[i], oracleDebug.tranInA1min[i])
        }
        compareDouble(&dTranInA5min, seq, ourDebug.tranInA5min, oracleDebug.tranInA5min)
        compareDouble(&dYcept, seq, ourDebug.ycept, oracleDebug.ycept)
        compareDouble(&dCorrectedReCurrent, seq, ourDebug.correctedReCurrent, oracleDebug.correctedReCurrent)
        compareDouble(&dDiabetesMeanX, seq, ourDebug.diabetesMeanX, oracleDebug.diabetesMeanX)
        compareDouble(&dDiabetesM2, seq, ourDebug.diabetesM2, oracleDebug.diabetesM2)
        compareDouble(&dDiabetesTAR, seq, ourDebug.diabetesTAR, oracleDebug.diabetesTAR)
        compareDouble(&dDiabetesTBR, seq, ourDebug.diabetesTBR, oracleDebug.diabetesTBR)
        compareDouble(&dDiabetesCV, seq, ourDebug.diabetesCV, oracleDebug.diabetesCV)
        compareInt(&dLevelDiabetes, seq, ourDebug.levelDiabetes, oracleDebug.levelDiabetes)
        compareDouble(&dOutIir, seq, ourDebug.outIir, oracleDebug.outIir)
        compareDouble(&dOutDrift, seq, ourDebug.outDrift, oracleDebug.outDrift)
        compareDouble(&dCurrBaseline, seq, ourDebug.currBaseline, oracleDebug.currBaseline)
        compareDouble(&dInitstableDiffDc, seq, ourDebug.initstableDiffDc, oracleDebug.initstableDiffDc)
        compareInt(&dInitstableInitcnt, seq, ourDebug.initstableInitcnt, oracleDebug.initstableInitcnt)
        compareDouble(&dTempLocalMean, seq, ourDebug.tempLocalMean, oracleDebug.tempLocalMean)
        compareDouble(&dSlopeRatioTemp, seq, ourDebug.slopeRatioTemp, oracleDebug.slopeRatioTemp)
        compareDouble(&dInitCg, seq, ourDebug.initCg, oracleDebug.initCg)
        compareDouble(&dOutRescale, seq, ourDebug.outRescale, oracleDebug.outRescale)
        compareDouble(&dOpcalAd, seq, ourDebug.opcalAd, oracleDebug.opcalAd)
        compareInt(&dStateInitKalman, seq, ourDebug.stateInitKalman, oracleDebug.stateInitKalman)
        compareInt(&dCalState, seq, ourDebug.calState, oracleDebug.calState)
        compareInt(&dStateReturnOpcal, seq, ourDebug.stateReturnOpcal, oracleDebug.stateReturnOpcal)
        compareInt(&dValidBgTime, seq, ourDebug.validBgTime, oracleDebug.validBgTime)
        compareDouble(&dValidBgValue, seq, ourDebug.validBgValue, oracleDebug.validBgValue)
        compareInt(&dCallogGroup, seq, ourDebug.callogGroup, oracleDebug.callogGroup)
        compareInt(&dCallogBgTime, seq, ourDebug.callogBgTime, oracleDebug.callogBgTime)
        compareDouble(&dCallogBgSeq, seq, ourDebug.callogBgSeq, oracleDebug.callogBgSeq)
        compareDouble(&dCallogBgUser, seq, ourDebug.callogBgUser, oracleDebug.callogBgUser)
        compareInt(&dCallogBgValid, seq, ourDebug.callogBgValid, oracleDebug.callogBgValid)
        compareDouble(&dCallogBgCal, seq, ourDebug.callogBgCal, oracleDebug.callogBgCal)
        compareDouble(&dCallogCgSeq1m, seq, ourDebug.callogCgSeq1m, oracleDebug.callogCgSeq1m)
        compareInt(&dCallogCgIdx, seq, ourDebug.callogCgIdx, oracleDebug.callogCgIdx)
        compareDouble(&dCallogCgCal, seq, ourDebug.callogCgCal, oracleDebug.callogCgCal)
        compareDouble(&dCallogCslopePrev, seq, ourDebug.callogCslopePrev, oracleDebug.callogCslopePrev)
        compareDouble(&dCallogCyceptPrev, seq, ourDebug.callogCyceptPrev, oracleDebug.callogCyceptPrev)
        compareDouble(&dCallogCslopeNew, seq, ourDebug.callogCslopeNew, oracleDebug.callogCslopeNew)
        compareDouble(&dCallogCyceptNew, seq, ourDebug.callogCyceptNew, oracleDebug.callogCyceptNew)
        compareInt(&dCallogInlierFlg, seq, ourDebug.callogInlierFlg, oracleDebug.callogInlierFlg)
        compareDouble(&dInitstableWeightUsercal, seq, ourDebug.initstableWeightUsercal, oracleDebug.initstableWeightUsercal)
        compareDouble(&dInitstableWeightNocal, seq, ourDebug.initstableWeightNocal, oracleDebug.initstableWeightNocal)
        compareDouble(&dInitstableFixusercal, seq, ourDebug.initstableFixusercal, oracleDebug.initstableFixusercal)
        compareInt(&dNOpcalState, seq, ourDebug.nOpcalState, oracleDebug.nOpcalState)
        compareInt(&dInitstableInitEndPoint, seq, ourDebug.initstableInitEndPoint, oracleDebug.initstableInitEndPoint)
        compareDouble(&dOutWeightAd, seq, ourDebug.outWeightAd, oracleDebug.outWeightAd)
        compareDouble(&dShiftoutAd, seq, ourDebug.shiftoutAd, oracleDebug.shiftoutAd)
        compareInt(&dErrorCode1, seq, ourDebug.errorCode1, oracleDebug.errorCode1)
        compareInt(&dErrorCode2, seq, ourDebug.errorCode2, oracleDebug.errorCode2)
        compareInt(&dErrorCode4, seq, ourDebug.errorCode4, oracleDebug.errorCode4)
        compareInt(&dErrorCode8, seq, ourDebug.errorCode8, oracleDebug.errorCode8)
        compareInt(&dErrorCode16, seq, ourDebug.errorCode16, oracleDebug.errorCode16)
        compareInt(&dErrorCode32, seq, ourDebug.errorCode32, oracleDebug.errorCode32)
        compareDouble(&dTrendrate, seq, ourDebug.trendrate, oracleDebug.trendrate)
        compareInt(&dCalAvailableFlag, seq, ourDebug.calAvailableFlag, oracleDebug.calAvailableFlag)
        // err1
        compareDouble(&dErr1ISseDMean, seq, ourDebug.err1ISseDMean, oracleDebug.err1ISseDMean)
        compareDouble(&dErr1ThSseDMean1, seq, ourDebug.err1ThSseDMean1, oracleDebug.err1ThSseDMean1)
        compareDouble(&dErr1ThSseDMean2, seq, ourDebug.err1ThSseDMean2, oracleDebug.err1ThSseDMean2)
        compareDouble(&dErr1ThSseDMean, seq, ourDebug.err1ThSseDMean, oracleDebug.err1ThSseDMean)
        compareInt(&dErr1IsContactBad, seq, ourDebug.err1IsContactBad, oracleDebug.err1IsContactBad)
        compareDouble(&dErr1CurrentAvgDiff, seq, ourDebug.err1CurrentAvgDiff, oracleDebug.err1CurrentAvgDiff)
        compareDouble(&dErr1ThDiff1, seq, ourDebug.err1ThDiff1, oracleDebug.err1ThDiff1)
        compareDouble(&dErr1ThDiff2, seq, ourDebug.err1ThDiff2, oracleDebug.err1ThDiff2)
        compareDouble(&dErr1ThDiff, seq, ourDebug.err1ThDiff, oracleDebug.err1ThDiff)
        compareInt(&dErr1Isfirst0, seq, ourDebug.err1Isfirst0, oracleDebug.err1Isfirst0)
        compareInt(&dErr1Isfirst1, seq, ourDebug.err1Isfirst1, oracleDebug.err1Isfirst1)
        compareInt(&dErr1Isfirst2, seq, ourDebug.err1Isfirst2, oracleDebug.err1Isfirst2)
        compareInt(&dErr1N, seq, ourDebug.err1N, oracleDebug.err1N)
        compareInt(&dErr1RandomNoiseTempBreak, seq, ourDebug.err1RandomNoiseTempBreak, oracleDebug.err1RandomNoiseTempBreak)
        compareInt(&dErr1Result, seq, ourDebug.err1Result, oracleDebug.err1Result)
        compareInt(&dErr1ResultTD, seq, ourDebug.err1ResultTD, oracleDebug.err1ResultTD)
        // err2
        compareDouble(&dErr2DelayRevisedValue, seq, ourDebug.err2DelayRevisedValue, oracleDebug.err2DelayRevisedValue)
        compareDouble(&dErr2DelayRoc, seq, ourDebug.err2DelayRoc, oracleDebug.err2DelayRoc)
        compareDouble(&dErr2DelaySlopeSharp, seq, ourDebug.err2DelaySlopeSharp, oracleDebug.err2DelaySlopeSharp)
        compareDouble(&dErr2DelayRocCummax, seq, ourDebug.err2DelayRocCummax, oracleDebug.err2DelayRocCummax)
        compareDouble(&dErr2DelaySlopeCummax, seq, ourDebug.err2DelaySlopeCummax, oracleDebug.err2DelaySlopeCummax)
        compareDouble(&dErr2DelayGluCummax, seq, ourDebug.err2DelayGluCummax, oracleDebug.err2DelayGluCummax)
        compareInt(&dErr2DelayFlag, seq, ourDebug.err2DelayFlag, oracleDebug.err2DelayFlag)
        compareDouble(&dErr2Cummax, seq, ourDebug.err2Cummax, oracleDebug.err2Cummax)
        for i in 0..<2 {
            compareInt(&dErr2CrtCurrent[i], seq, ourDebug.err2CrtCurrent[i], oracleDebug.err2CrtCurrent[i])
            compareInt(&dErr2CrtGlu[i], seq, ourDebug.err2CrtGlu[i], oracleDebug.err2CrtGlu[i])
            compareInt(&dErr2Condi[i], seq, ourDebug.err2Condi[i], oracleDebug.err2Condi[i])
        }
        // err4
        compareDouble(&dErr4Min, seq, ourDebug.err4Min, oracleDebug.err4Min)
        compareDouble(&dErr4Range, seq, ourDebug.err4Range, oracleDebug.err4Range)
        compareDouble(&dErr4MinDiff, seq, ourDebug.err4MinDiff, oracleDebug.err4MinDiff)
        // err16
        compareDouble(&dErr16CgmPlasma, seq, ourDebug.err16CgmPlasma, oracleDebug.err16CgmPlasma)
        compareDouble(&dErr16CgmIsfSmooth, seq, ourDebug.err16CgmIsfSmooth, oracleDebug.err16CgmIsfSmooth)
        // err128
        compareInt(&dErr128Flag, seq, ourDebug.err128Flag, oracleDebug.err128Flag)
        compareDouble(&dErr128RevisedValue, seq, ourDebug.err128RevisedValue, oracleDebug.err128RevisedValue)
        compareDouble(&dErr128Normal, seq, ourDebug.err128Normal, oracleDebug.err128Normal)

        // tran_inA array (30 doubles)
        for i in 0..<30 {
            compareDouble(&dTranInA, seq, ourDebug.tranInA[i], oracleDebug.tranInA[i])
        }

        // Progress: print first 5, then every 50th
        if seq <= 5 || seq % 50 == 0 || seq == readingsPerLot {
            print("  lot\(lotNum) seq \(seq): glu ours=\(ourOutput.resultGlucose) oracle=\(oracleOutput.resultGlucose) | err ours=\(ourOutput.errcode) oracle=\(oracleOutput.errcode)")
        }

        readingsCompared += 1
    }

    // Print reports
    print()
    print("=== Lot \(lotNum): \(readingsCompared) readings compared ===")
    printReport("OUTPUT", allOutputStats)
    printReport("DEBUG", allDebugStats)

    return LotResult(lotNum: lotNum, readingsCompared: readingsCompared,
                     glucoseMismatches: glucoseMismatches, errcodeMismatches: errcodeMismatches,
                     calAvailableMismatches: calAvailableMismatches,
                     currentStageMismatches: currentStageMismatches,
                     trendrateMismatches: trendrateMismatches,
                     outputStats: allOutputStats, debugStats: allDebugStats)
}

func printReport(_ section: String, _ fields: [FieldStats]) {
    print("")
    print("--- \(section) Field Match Report ---")
    print("%-45s %6s %6s %6s %10s %10s %s", "Field", "Total", "Match", "Miss", "MaxAbsE", "MaxRelE", "FirstMiss")
    print("%-45s %6s %6s %6s %10s %10s %s", "-----", "-----", "-----", "----", "-------", "-------", "---------")

    var totalMatch = 0, totalMismatch = 0, totalTotal = 0
    var fieldsCompared = 0
    var fieldsMatching = 0
    var mismatchingFields: [FieldStats] = []

    for f in fields {
        totalMatch += f.match
        totalMismatch += f.mismatch
        totalTotal += f.total
        fieldsCompared += 1

        let absStr = (f.maxAbsErr > 0) ? String(format: "%.1e", f.maxAbsErr) : "-"
        let relStr = (f.maxRelErr > 0) ? String(format: "%.1e", f.maxRelErr) : "-"
        let firstStr = (f.firstMismatchSeq > 0) ? "seq " + String(f.firstMismatchSeq) : "-"
        let status = (f.mismatch == 0) ? " OK" : " FAIL"

        if f.mismatch == 0 {
            fieldsMatching += 1
        } else {
            mismatchingFields.append(f)
        }

        print("%-45s %6d %6d %6d %10s %10s %-12s\(status)",
              f.name, f.total, f.match, f.mismatch,
              absStr, relStr, firstStr)
    }

    let pct = (totalTotal > 0) ? 100.0 * Double(totalMatch) / Double(totalTotal) : 0.0
    print("")
    print("  TOTAL: \(totalMatch)/\(totalTotal) field-readings match (\(String(format: "%.1f", pct))%)")
    print("  FIELDS: \(fieldsMatching)/\(fieldsCompared) fields fully matching")

    if !mismatchingFields.isEmpty {
        print("")
        print("  MISMATCHING FIELDS (\(mismatchingFields.count)):")
        for f in mismatchingFields {
            print("    %-45s \(f.mismatch)/\(f.total) mismatches, first at seq \(f.firstMismatchSeq)")
            if let detail = f.firstMismatchDetail {
                print("      -> \(detail)")
            }
        }
    }
}

// MARK: - Test Methods

extension OracleVerificationTest {
    @ParameterizedTest(name: "lot\(0)")
    @ValueSource(ints: [0, 1, 2, 3, 4])
    @DisplayName("Oracle verification")
    func verifyLot(_ lotNum: Int) throws {
        try XCTSkipIf(oracleBase == nil, "Oracle data directory not found")

        let result = try runLotVerification(lotNum)

        // --- Summary of safety-critical fields ---
        print("")
        print("=== Lot \(lotNum) Safety-Critical Summary ===")
        print("  Readings compared:      \(result.readingsCompared)")
        print("  Glucose mismatches:     \(result.glucoseMismatches)")
        print("  Errcode mismatches:     \(result.errcodeMismatches)")
        print("  CalAvailable mismatches:\(result.calAvailableMismatches)")
        print("  CurrentStage mismatches:\(result.currentStageMismatches)")
        print("  Trendrate mismatches:   \(result.trendrateMismatches)")
        print("  Output fields:          \(result.totalOutputMatch)/\(result.totalOutputMatch + result.totalOutputMismatch) match")
        print("  Debug fields:           \(result.totalDebugMatch)/\(result.totalDebugMatch + result.totalDebugMismatch) match")

        // CRITICAL ASSERTIONS: safety-critical output fields must match the oracle
        XCTAssertEqual(0, result.glucoseMismatches,
            "PATIENT SAFETY: \(result.glucoseMismatches) glucose value mismatches in lot\(lotNum). Every glucose reading must match the oracle.")

        XCTAssertEqual(0, result.errcodeMismatches,
            "PATIENT SAFETY: \(result.errcodeMismatches) errcode mismatches in lot\(lotNum). Errcode determines whether a reading is shown to the patient.")

        XCTAssertEqual(0, result.calAvailableMismatches,
            "PATIENT SAFETY: \(result.calAvailableMismatches) cal_available_flag mismatches in lot\(lotNum)")

        XCTAssertEqual(0, result.currentStageMismatches,
            "PATIENT SAFETY: \(result.currentStageMismatches) current_stage mismatches in lot\(lotNum)")

        XCTAssertEqual(0, result.trendrateMismatches,
            "PATIENT SAFETY: \(result.trendrateMismatches) trendrate mismatches in lot\(lotNum). Trend arrows guide insulin dosing decisions.")
    }

    // MARK: - Oracle Data Existence Check

    @Test
    @DisplayName("Oracle data exists - warns visibly if missing (not silently skipped)")
    func oracleDataExists() {
        if oracleBase == nil {
            print("WARNING: Oracle data directory not found!")
            print("WARNING: Oracle verification tests are being SKIPPED.")
            print("WARNING: This means ZERO oracle coverage in this test run.")
            print("WARNING: Expected oracle data at: \(oracleRoot)")
            print("WARNING: Or at: /Users/erik/github.com/erikdebruijn/OpenCareSens-air/oracle/output")
            return
        }
        var lotsFound = 0
        for lot in 0..<5 {
            let lotDir = URL(fileURLWithPath: oracleBase!).appendingPathComponent("/lot" + String(lot))
            if FileManager.default.fileExists(atPath: lotDir.path) {
                lotsFound += 1
            } else {
                print("WARNING: Oracle data missing for lot\(lot) at \(lotDir.path)")
            }
        }
        print("Oracle data check: \(lotsFound)/5 lots available")
        XCTAssertGreaterThan(lotsFound, 0,
            "At least one lot of oracle data should be present when oracleBase exists")
    }

    // MARK: - Aggregate Summary Test

    @Test
    @DisplayName("Full oracle verification summary across all lots")
    func fullOracleVerificationSummary() throws {
        try XCTSkipIf(oracleBase == nil, "Oracle data directory not found")

        var totalReadings = 0
        var totalGluMismatches = 0
        var totalErrcodeMismatches = 0
        var totalCalAvailMismatches = 0
        var totalStageMismatches = 0
        var totalTrendrateMismatches = 0
        var totalOutputMatch = 0, totalOutputMismatch = 0
        var totalDebugMatch = 0, totalDebugMismatch = 0

        for lot in 0..<5 {
            let lotDir = oracleBase! + "/lot" + String(lot)
            if !FileManager.default.fileExists(atPath: lotDir) {
                print("Skipping lot\(lot) (no oracle data)")
                continue
            }

            let result = try runLotVerification(lot)
            totalReadings += result.readingsCompared
            totalGluMismatches += result.glucoseMismatches
            totalErrcodeMismatches += result.errcodeMismatches
            totalCalAvailMismatches += result.calAvailableMismatches
            totalStageMismatches += result.currentStageMismatches
            totalTrendrateMismatches += result.trendrateMismatches
            totalOutputMatch += result.totalOutputMatch
            totalOutputMismatch += result.totalOutputMismatch
            totalDebugMatch += result.totalDebugMatch
            totalDebugMismatch += result.totalDebugMismatch
        }

        print("")
        print("========================================")
        print("FULL ORACLE VERIFICATION SUMMARY")
        print("========================================")
        print("Total readings:          \(totalReadings)")
        print("Glucose mismatches:      \(totalGluMismatches)")
        print("Errcode mismatches:      \(totalErrcodeMismatches)")
        print("CalAvailable mismatches: \(totalCalAvailMismatches)")
        print("CurrentStage mismatches: \(totalStageMismatches)")
        print("Trendrate mismatches:    \(totalTrendrateMismatches)")
        print("Output fields match:     \(totalOutputMatch)/\(totalOutputMatch + totalOutputMismatch) (%.1f%%)",
              (totalOutputMatch + totalOutputMismatch > 0)
                  ? 100.0 * Double(totalOutputMatch) / Double(totalOutputMatch + totalOutputMismatch) : 0.0)
        print("Debug fields match:      \(totalDebugMatch)/\(totalDebugMatch + totalDebugMismatch) (%.1f%%)",
              (totalDebugMatch + totalDebugMismatch > 0)
                  ? 100.0 * Double(totalDebugMatch) / Double(totalDebugMatch + totalDebugMismatch) : 0.0)
        print("========================================")

        XCTAssertEqual(0, totalGluMismatches,
            "PATIENT SAFETY: \(totalGluMismatches) total glucose value mismatches across all lots.")
        XCTAssertEqual(0, totalErrcodeMismatches,
            "PATIENT SAFETY: \(totalErrcodeMismatches) total errcode mismatches across all lots.")
        XCTAssertEqual(0, totalCalAvailMismatches,
            "PATIENT SAFETY: \(totalCalAvailMismatches) total cal_available_flag mismatches across all lots.")
        XCTAssertEqual(0, totalStageMismatches,
            "PATIENT SAFETY: \(totalStageMismatches) total current_stage mismatches across all lots.")
        XCTAssertEqual(0, totalTrendrateMismatches,
            "PATIENT SAFETY: \(totalTrendrateMismatches) total trendrate mismatches across all lots.")
    }
}
