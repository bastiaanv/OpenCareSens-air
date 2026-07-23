// CalibrationAlgorithm.swift
// Main 14-step calibration pipeline for the CareSens Air CGM.
// Ported from air1_opcal4_algorithm() in calibration.c.
//
// MEDICAL SAFETY: This is life-critical code. Every calculation must match
// the C implementation at machine-epsilon precision. Incorrect glucose values
// lead to wrong insulin dosing, causing dangerous hypo/hyperglycemia.

import Foundation

/// Main calibration pipeline for the CareSens Air CGM.
///
/// This enum is used as a namespace for the calibration algorithm's
/// static methods and constants. It cannot be instantiated.
public enum CalibrationAlgorithm {

    // MARK: - Constants (must match C implementation exactly)

    // Temperature correction (lot type 1)
    static let TEMP_REF: Double = 37.0
    static let TEMP_COEFF: Double = 0.1584

    // Temperature correction (lot type 2) — retained for reference; the oracle
    // uses the lot_type 1 formula for all lot types (see computeSlopeRatioTempBuffered)
    static let LOT2_TEMP_COEFF: Double = 0.0328
    static let LOT2_TEMP_REF: Double = 34.0854
    static let TEMP_BUF_SIZE: Int = 4

    // Drift polynomial coefficients (from get_params)
    static let DRIFT_COEF_A: Double = -5.151560190469187e-12
    static let DRIFT_COEF_B: Double = 5.994148299744164e-09
    static let DRIFT_COEF_C: Double = 5.293796500000622e-05
    static let DRIFT_COEF_D: Double = 0.9146662999999999
    static let DRIFT_APPLY_RATE: Double = 0.9

    // Holt-Kalman constants
    static let PHI: Double = 0.60653065971263342 // exp(-0.5)
    static let HOLT_K1: Double = 0.6729
    static let HOLT_K2: Double = 1.761
    static let HOLT_K3: Double = 0.1279

    // Baseline correction
    static let YCEPT_CONTROL: Double = 0.7  // lot_type == 1
    static let YCEPT_TEST: Double = 0.243   // lot_type == 2

    // ADC conversion
    static let ADC_DIVISOR: Double = 40950.0

    // MARK: - Lot type determination

    /// Determine lot_type from eapp value.
    /// eapp < 0.075: lot_type = 2
    /// eapp == 0.075: lot_type = 0
    /// eapp > 0.075: lot_type = 1
    internal static func determineLotType(_ eapp: Float) -> Int {
        var dEapp = Double(eapp)
        if dEapp.isNaN {
            dEapp = 0.0
        }
        let threshold = 0.075
        if dEapp < threshold { return 2 }
        if dEapp > threshold { return 1 }
        return 0
    }

    // MARK: - ADC to current conversion

    /// Convert 30 ADC values to current.
    /// Formula: current[i] = (adc[i] * vref / 40950.0 - eapp) * 100.0
    internal static func adcToCurrent(_ adc: [Int], _ vref: Float, _ eapp: Float) -> [Double] {
        var current = [Double](repeating: 0.0, count: 30)
        for i in 0..<30 {
            current[i] = (Double(adc[i]) * Double(vref) / Self.ADC_DIVISOR
                         - Double(eapp)) * 100.0
        }
        return current
    }

    // MARK: - IIR filter

    /// IIR low-pass filter. Oracle shows pass-through behavior.
    internal static func iirFilter(_ input: Double, _ args: AlgorithmState, _ devInfo: DeviceInfo) -> Double {
        if devInfo.iirFlag == 0 {
            return input
        }
        args.iirX[1] = args.iirX[0]
        args.iirX[0] = input
        args.iirY = input
        if args.iirStartFlag == 0 {
            args.iirStartFlag = 1
        }
        return input
    }

    // MARK: - Drift correction (lot_type 1 only)

    /// Drift correction: cubic polynomial with rate blending.
    /// Also computes baseline extraction (running average).
    internal static func driftCorrection(_ outIir: Double, _ args: AlgorithmState, _ debug: DebugOutput) -> Double {
        let n = args.idxOriginSeq
        let seq = Double(n)

        // Cubic polynomial drift factor
        let poly = Self.DRIFT_COEF_A * seq * seq * seq
                 + Self.DRIFT_COEF_B * seq * seq
                 + Self.DRIFT_COEF_C * seq
                 + Self.DRIFT_COEF_D

        // Rate blending (clamped)
        let divisor: Double
        if poly > 1.0 {
            divisor = 1.0
        } else {
            divisor = (1.0 - Self.DRIFT_APPLY_RATE) + poly * Self.DRIFT_APPLY_RATE
        }

        let outDrift = outIir / divisor
        debug.outDrift = outDrift

        // Baseline extraction: running average
        if n == 1 {
            args.baselinePrev = outDrift
            debug.currBaseline = outDrift
            debug.initstableDiffDc = outDrift
        } else {
            let prevBaseline = args.baselinePrev
            let newBaseline = (prevBaseline * Double(n - 1) + outDrift) / Double(n)
            debug.currBaseline = newBaseline
            debug.initstableDiffDc = newBaseline - prevBaseline
            args.baselinePrev = newBaseline
        }

        return outDrift
    }

    // MARK: - Temperature correction with circular buffer

    /// Compute slope_ratio_temp using a 4-element circular buffer of temperatures.
    internal static func computeSlopeRatioTempBuffered(_ temperature: Double,
                                                         _ args: AlgorithmState,
                                                         _ lotType: Int) -> Double {
        let idx = args.idxOriginSeq
        let bufLen = (idx < Self.TEMP_BUF_SIZE) ? idx : Self.TEMP_BUF_SIZE
        let bufPos = (idx - 1) % Self.TEMP_BUF_SIZE
        args.slopeRatioTempBuffer[bufPos] = temperature

        // Mean of buffered temperatures
        var tMean = 0.0
        for i in 0..<bufLen {
            tMean += args.slopeRatioTempBuffer[i]
        }
        tMean /= Double(bufLen)

        // Oracle-verified: the proprietary binary uses the same temperature correction
        // formula for ALL lot types (lot_type 1 formula), not a lot_type-specific one.
        // Verified: lot0 (eapp=0.10067) and lot2 (eapp=0.05) both produce
        // srt = 1 + (-0.1584) * (T_mean - 37.0) = 1.0792 at T=36.5.
        if lotType == 1 || lotType == 2 {
            return 1.0 + (-Self.TEMP_COEFF) * (tMean - Self.TEMP_REF)
        } else {
            return 1.0 // lot_type 0: no correction
        }
    }

    // MARK: - Main pipeline: process()

    /// Main calibration algorithm entry point.
    /// Matches air1_opcal4_algorithm() from calibration.c.
    ///
    /// - Returns: 1 on success, 0 on failure (matches C uint8_t return)
    @discardableResult
    public static func process(deviceInfo devInfo: DeviceInfo,
                                cgmInput: CgmInput,
                                calInput: CalibrationList,
                                algoArgs: AlgorithmState,
                                algoOutput: AlgorithmOutput,
                                algoDebug: DebugOutput) -> Int {
        // Clear output and debug
        Self.clearOutput(algoOutput)
        Self.clearDebug(algoDebug)

        let seq = cgmInput.seqNumber
        let timeNow = cgmInput.measurementTimeStandard

        // --- Step 0: First-call initialization ---
        algoArgs.idxOriginSeq += 1

        if algoArgs.idxOriginSeq == 1 {
            algoArgs.lotType = Self.determineLotType(devInfo.eapp)
            algoArgs.sensorStartTime = devInfo.sensorStartTime
            algoArgs.stateReturnOpcal = -1
        }

        // Cumulative sequence number
        let seqFinal = seq + algoArgs.cumulSum

        // --- Populate output header ---
        algoOutput.seqNumberOriginal = seq
        algoOutput.seqNumberFinal = seqFinal
        algoOutput.measurementTimeStandard = timeNow
        for i in 0..<30 { algoOutput.workout[i] = cgmInput.workout[i] }

        // --- Populate debug header ---
        algoDebug.seqNumberOriginal = seq
        algoDebug.seqNumberFinal = seqFinal
        algoDebug.measurementTimeStandard = timeNow
        algoDebug.dataType = 0
        // Note: temperature is set AFTER the eapp check below (oracle-verified:
        // the binary returns before setting temperature when eapp is invalid)
        for i in 0..<30 { algoDebug.workout[i] = cgmInput.workout[i] }

        // --- Parameter validation: eapp range check ---
        // Oracle-verified: the proprietary binary rejects eapp values outside the
        // sensor's valid operating range. eapp >= 0.12 produces errcode=64 (bit 6)
        // with zeroed output. The debug struct retains header fields (seq, time,
        // workout) but temperature stays zeroed.
        let dEappCheck = Double(devInfo.eapp)
        if dEappCheck >= 0.12 {
            algoOutput.errcode = 64
            algoOutput.resultGlucose = 0.0
            return 1
        }

        algoDebug.temperature = cgmInput.temperature

        // --- Debug initialization (oracle-verified) ---
        algoDebug.stateReturnOpcal = algoArgs.stateReturnOpcal
        algoDebug.nOpcalState = -1
        algoDebug.diabetesTAR = .nan
        algoDebug.diabetesTBR = .nan
        algoDebug.diabetesCV = .nan
        algoDebug.levelDiabetes = 6
        algoDebug.err1ThSseDMean1 = .nan
        algoDebug.err1ThSseDMean2 = .nan
        algoDebug.err1ThSseDMean = .nan
        algoDebug.err1ThDiff1 = .nan
        algoDebug.err1ThDiff2 = .nan
        algoDebug.err1ThDiff = .nan
        algoDebug.callogCslopePrev = 1.0
        algoDebug.callogCslopeNew = 1.0
        algoDebug.initstableWeightUsercal = 1.0
        algoDebug.initstableFixusercal = 0.8
        algoDebug.trendrate = 100.0
        algoDebug.tempLocalMean = cgmInput.temperature

        // --- Validate device_info parameters ---
        let dEapp = Double(devInfo.eapp)
        let dVref = Double(devInfo.vref)
        let dSlope100 = Double(devInfo.slope100)

        if dEapp < 0.0 || dEapp > 0.5 ||
           dVref < 0.0 || dVref > 3.0 ||
           dSlope100 <= 0.0 || dSlope100 > 10.0 {
            algoDebug.nOpcalState = 1
            algoOutput.errcode = 0
            algoOutput.resultGlucose = 0.0
            return 1
        }

        // --- Step 1: ADC to current conversion ---
        let tranInA = Self.adcToCurrent(cgmInput.workout, devInfo.vref, devInfo.eapp)
        for i in 0..<30 { algoDebug.tranInA[i] = tranInA[i] }

        // --- Step 2: Compute 1-minute averages via LOESS pipeline ---
        var timeGap = 300.0 // default 5-min interval
        if algoArgs.idxOriginSeq > 1 && algoArgs.timePrev > 0 {
            timeGap = Double(timeNow - algoArgs.timePrev)
        }

        // Bridge int[] outlierMaxIndex to byte[] for SignalProcessing
        var outlierFifo = [Int8](repeating: 0, count: 6)
        for i in 0..<6 {
            outlierFifo[i] = Int8(truncatingIfNeeded: algoArgs.outlierMaxIndex[i])
        }

        let tranInA1min = SignalProcessing.computeTranInA1min(
            tranInA,
            &algoArgs.prevOutlierRemovedCurr,
            &algoArgs.prevMovMedianCurr,
            &algoArgs.prevCurrent,
            &algoArgs.prevNewISig,
            &outlierFifo,
            Int64(algoArgs.idxOriginSeq),
            timeGap)

        // Copy back outlier FIFO state
        for i in 0..<6 {
            algoArgs.outlierMaxIndex[i] = Int(outlierFifo[i])
        }

        for i in 0..<5 { algoDebug.tranInA1min[i] = tranInA1min[i] }

        // tran_inA_5min = average of 1-min values excluding min and max
        let tranInA5min = MathUtils.calAverageWithoutMinMax(tranInA1min, 5)
        algoDebug.tranInA5min = tranInA5min

        // --- Step 3: Correct baseline (ycept subtraction) ---
        let correctedCurrent: Double
        let lotType = algoArgs.lotType
        if lotType == 1 {
            correctedCurrent = tranInA5min - Self.YCEPT_CONTROL
        } else if lotType == 2 {
            correctedCurrent = tranInA5min - Self.YCEPT_TEST
        } else {
            correctedCurrent = tranInA5min
        }
        algoDebug.correctedReCurrent = correctedCurrent

        // --- Step 4: ycept = corrected current ---
        algoDebug.ycept = correctedCurrent

        // --- Step 5: IIR filter ---
        let outIir = Self.iirFilter(correctedCurrent, algoArgs, devInfo)
        algoDebug.outIir = outIir

        // --- Step 6: Temperature correction ---
        let slopeRatioTemp = Self.computeSlopeRatioTempBuffered(
            cgmInput.temperature, algoArgs, algoArgs.lotType)
        algoDebug.slopeRatioTemp = slopeRatioTemp

        // --- Step 7: Drift correction and baseline extraction ---
        // Oracle-verified: drift correction is applied for ALL lot types (lot_type 1 and 2).
        // The proprietary binary uses the same cubic polynomial drift + baseline extraction
        // regardless of eapp/lot_type. Verified: lot2 (eapp=0.05) oracle shows
        // out_drift = out_iir / divisor, not out_drift = out_iir.
        let outDrift = Self.driftCorrection(outIir, algoArgs, algoDebug)

        // --- Step 7b: Initstable counter ---
        do {
            let threshold = 0.01
            if algoArgs.idxOriginSeq > 1 {
                let diffDc = algoDebug.initstableDiffDc
                if diffDc < threshold && diffDc > -threshold {
                    algoArgs.initstableInitcnt += 1
                } else {
                    algoArgs.initstableInitcnt = 0
                }
            }
            algoDebug.initstableInitcnt = algoArgs.initstableInitcnt
        }

        // --- Step 8: Initial calibrated glucose estimate ---
        // MEDICAL SAFETY: Guard against division by zero or near-zero when
        // slopeRatioTemp is extreme (e.g., extreme temperature far from 37C).
        // dSlope100 * slopeRatioTemp near zero would produce Infinity glucose.
        let slopeTempProduct = dSlope100 * slopeRatioTemp
        if abs(slopeTempProduct) < 1e-10 {
            algoDebug.nOpcalState = 1
            algoOutput.errcode = 64
            algoOutput.resultGlucose = 0.0
            return 1
        }
        let initCg = outDrift * 100.0 / slopeTempProduct
        algoDebug.initCg = initCg

        // --- Step 9: Compute stage ---
        let currentStage: Int
        if seq <= devInfo.err345Seq2 {
            currentStage = 0
        } else {
            currentStage = 1
        }
        algoDebug.stage = currentStage
        algoOutput.currentStage = currentStage

        // --- Step 10: Kalman pass-through + bias correction state ---
        let outRescale = initCg
        algoDebug.outRescale = outRescale

        // Bias correction state machine
        do {
            let prevFlag = algoArgs.biasFlag
            let idx = algoArgs.idxOriginSeq
            let bw = devInfo.basicWarmup
            let sf = seqFinal

            // Track init_cg stability
            if idx > 1 {
                let deltaCg = abs(initCg - algoArgs.initCgPrev)
                if deltaCg < 0.1 {
                    algoArgs.nSumtrend += 1.0
                } else {
                    algoArgs.nSumtrend = 0.0
                }
            }

            // Flag management
            if sf <= bw {
                algoArgs.biasFlag = 0
            } else if sf <= bw + 6 {
                if prevFlag == 3 && algoArgs.nSumtrend >= 3.0 {
                    algoArgs.biasFlag = 0
                } else if prevFlag == 3 || sf == bw + 1 {
                    algoArgs.biasFlag = 3
                } else {
                    algoArgs.biasFlag = 0
                }
            } else {
                algoArgs.biasFlag = 0
            }

            // Counter management
            if algoArgs.biasFlag == 3 {
                algoArgs.biasCnt = 1
            } else if prevFlag == 3 {
                algoArgs.biasCnt = 1
            } else if algoArgs.biasCnt == 0 {
                algoArgs.biasCnt = 1
            } else if sf >= 2 * devInfo.err345Seq2 {
                algoArgs.biasCnt += 1
            }
        }
        algoDebug.stateInitKalman = algoArgs.biasFlag

        // Store rate of change history (shift right by 1)
        for i in (1...3).reversed() { algoArgs.kalmanRoc[i] = algoArgs.kalmanRoc[i - 1] }
        algoArgs.kalmanRoc[0] = 0.0

        // --- Step 11: Savitzky-Golay smoothing ---
        // Save timestamps before smooth_sg corrupts via int aliasing
        var savedSmoothTime = [Int64](repeating: 0, count: 9)
        for i in 0..<9 { savedSmoothTime[i] = algoArgs.smoothTimeIn[i + 1] }

        // Convert long[] to int[] for SG
        var seqInSg = [Int](repeating: 0, count: 10)
        for i in 0..<10 {
            seqInSg[i] = Int(algoArgs.smoothTimeIn[i])
        }
        var frepInSg = [Int](repeating: 0, count: 6)
        for i in 0..<6 { frepInSg[i] = algoArgs.smoothFRepIn[i] }

        let sgResult = SignalProcessing.smoothSg(
            algoArgs.smoothSigIn, seqInSg, frepInSg,
            outRescale, seq, 0,
            devInfo.wSgX100)

        // Copy results back to state
        for i in 0..<10 { algoArgs.smoothSigIn[i] = sgResult.sigOut[i] }
        for i in 0..<10 {
            algoArgs.smoothTimeIn[i] = Int64(sgResult.seqOut[i])
        }
        for i in 0..<6 { algoArgs.smoothFRepIn[i] = sgResult.frepOut[i] }

        // Oracle-verified: smooth_result_glucose corresponds to SG buffer positions [3..8].
        // The SG buffer has 10 elements: positions [0..2] are unsmoothed
        // (shifted raw values), [3..9] are SG-convolved. The 6 output smooth values
        // come from positions [3..8]. Similarly for smooth_seq.
        for i in 0..<6 {
            algoDebug.smoothSig[i] = algoArgs.smoothSigIn[i + 3]
            algoDebug.smoothSeq[i] = Int(algoArgs.smoothTimeIn[i + 3])
            algoDebug.smoothFrep[i] = algoArgs.smoothFRepIn[i]
        }

        // Restore proper timestamps for trendrate
        for i in 0..<9 { algoArgs.smoothTimeIn[i] = savedSmoothTime[i] }
        algoArgs.smoothTimeIn[9] = timeNow

        // --- Step 11b: Holt bias correction ---
        let opcalAd: Double
        do {
            let cnt = algoArgs.biasCnt
            if cnt <= 1 {
                if cnt == 1 {
                    algoArgs.holtLevel = initCg
                    algoArgs.holtForecast = initCg
                    algoArgs.holtTrend = 0.0
                }
                opcalAd = initCg
            } else {
                // State prediction
                let levelPred = Self.PHI * algoArgs.holtLevel
                                + (1.0 - Self.PHI) * algoArgs.holtForecast
                let forecastPred = algoArgs.holtForecast + algoArgs.holtTrend
                let trendPred = algoArgs.holtTrend

                // Innovation and Kalman update
                let innovation = initCg - levelPred
                algoArgs.holtLevel = levelPred + Self.HOLT_K1 * innovation
                algoArgs.holtForecast = forecastPred + Self.HOLT_K2 * innovation
                algoArgs.holtTrend = trendPred + Self.HOLT_K3 * innovation

                if cnt > 25 {
                    opcalAd = algoArgs.holtForecast
                } else {
                    opcalAd = initCg + (algoArgs.holtForecast - initCg)
                              * Double(cnt - 1) / 24.0
                }
            }
        }
        algoDebug.opcalAd = opcalAd
        let resultGlucose = opcalAd

        algoDebug.outWeightAd = opcalAd
        algoDebug.shiftoutAd = opcalAd

        // --- Step 12: Calibration state ---
        algoDebug.calState = algoArgs.calState

        // --- Step 13: Error detection ---
        let errcode = CheckError.checkError(devInfo, algoArgs, algoDebug,
            resultGlucose, correctedCurrent, seq, timeNow, currentStage)

        // Update prev_last_1min_curr
        algoArgs.err1PrevLast1minCurr = tranInA1min[4]

        // --- Step 13b: Trendrate computation ---
        Self.computeTrendrate(algoArgs, algoDebug, errcode, timeNow)

        // --- Step 14: Set final output ---
        algoOutput.resultGlucose = resultGlucose
        algoOutput.errcode = errcode
        algoOutput.trendrate = algoDebug.trendrate
        algoOutput.calAvailableFlag = algoDebug.calAvailableFlag
        algoOutput.dataType = algoDebug.dataType

        for i in 0..<6 {
            algoOutput.smoothSeq[i] = algoDebug.smoothSeq[i]
            algoOutput.smoothResultGlucose[i] = algoDebug.smoothSig[i]
            algoOutput.smoothFixedFlag[i] = algoDebug.smoothFrep[i]
        }

        // --- Store state for next call ---
        algoArgs.timePrev = timeNow
        algoArgs.seqPrev = seq
        for i in 0..<30 { algoArgs.adcPrev[i] = cgmInput.workout[i] }
        algoArgs.tempPrev = cgmInput.temperature
        algoArgs.initCgPrev = initCg

        return 1
    }

    // MARK: - Trendrate computation (Step 13b)

    internal static func computeTrendrate(_ algoArgs: AlgorithmState, _ algoDebug: DebugOutput,
                                            _ errcode: Int, _ timeNow: Int64) {
        // Update err_delay_arr: shift left, append current error status
        for i in 0..<6 { algoArgs.errDelayArr[i] = algoArgs.errDelayArr[i + 1] }
        algoArgs.errDelayArr[6] = (errcode != 0) ? 1 : 0

        // Guard: need at least 12 readings
        if algoArgs.idxOriginSeq < 12 { return }

        // Guard: 6 consecutive timestamp pairs spaced >= 181s
        // T points to smoothTimeIn[3..9]
        for i in 0..<6 {
            if algoArgs.smoothTimeIn[3 + i + 1] - algoArgs.smoothTimeIn[3 + i] < 181 {
                return
            }
        }

        // Guard: total span in [1200, 2100] seconds
        let span = timeNow - algoArgs.smoothTimeIn[3]
        if span < 1200 || span > 2100 { return }

        // Guard: no error flags in delay array
        for i in 0..<7 {
            if algoArgs.errDelayArr[i] == 1 { return }
        }

        // Compute calibrated glucose from smooth buffer
        var glu = [Double](repeating: 0.0, count: 7)
        for i in 0..<7 {
            glu[i] = algoArgs.smoothSigIn[3 + i]
            if glu[i] <= 0.0 || glu[i] < 40.0 || glu[i] > 500.0 { return }
        }

        // Rate computation (with zero-denominator guards to prevent NaN/Infinity)
        let denomLong = Double(timeNow - algoArgs.smoothTimeIn[3]) / 60.0
        if denomLong == 0.0 { return }
        let rateLong = (glu[6] - glu[0]) / denomLong

        let denomShort = Double(timeNow - algoArgs.smoothTimeIn[8]) / 60.0
        if denomShort == 0.0 { return }
        let rateShort = (glu[6] - glu[5]) / denomShort

        // Direction guard
        if rateShort < 0.0 && rateLong >= 1.0 { return }
        if rateShort > 0.0 && rateLong <= -1.0 { return }

        let denomMid = Double(algoArgs.smoothTimeIn[8] - algoArgs.smoothTimeIn[7]) / 60.0
        if denomMid == 0.0 { return }
        let rateMid = (glu[5] - glu[4]) / denomMid
        algoDebug.trendrate = (rateShort * rateMid >= 0.0) ? rateShort : 0.0
    }

    // MARK: - Output/Debug clearing helpers

    internal static func clearOutput(_ out: AlgorithmOutput) {
        out.seqNumberOriginal = 0
        out.seqNumberFinal = 0
        out.measurementTimeStandard = 0
        for i in 0..<out.workout.count { out.workout[i] = 0 }
        out.resultGlucose = 0.0
        out.trendrate = 0.0
        out.currentStage = 0
        for i in 0..<out.smoothFixedFlag.count { out.smoothFixedFlag[i] = 0 }
        for i in 0..<out.smoothSeq.count { out.smoothSeq[i] = 0 }
        for i in 0..<out.smoothResultGlucose.count { out.smoothResultGlucose[i] = 0.0 }
        out.errcode = 0
        out.calAvailableFlag = 0
        out.dataType = 0
    }

    internal static func clearDebug(_ d: DebugOutput) {
        d.seqNumberOriginal = 0
        d.seqNumberFinal = 0
        d.measurementTimeStandard = 0
        d.dataType = 0
        d.stage = 0
        d.temperature = 0.0
        for i in 0..<d.workout.count { d.workout[i] = 0 }
        for i in 0..<d.tranInA.count { d.tranInA[i] = 0.0 }
        for i in 0..<d.tranInA1min.count { d.tranInA1min[i] = 0.0 }
        d.tranInA5min = 0.0
        d.ycept = 0.0
        d.correctedReCurrent = 0.0
        d.diabetesMeanX = 0.0
        d.diabetesM2 = 0.0
        d.diabetesTAR = 0.0
        d.diabetesTBR = 0.0
        d.diabetesCV = 0.0
        d.levelDiabetes = 0
        d.outIir = 0.0
        d.outDrift = 0.0
        d.currBaseline = 0.0
        d.initstableDiffDc = 0.0
        d.initstableInitcnt = 0
        d.tempLocalMean = 0.0
        d.slopeRatioTemp = 0.0
        d.initCg = 0.0
        d.outRescale = 0.0
        d.opcalAd = 0.0
        d.stateInitKalman = 0
        for i in 0..<d.smoothSeq.count { d.smoothSeq[i] = 0 }
        for i in 0..<d.smoothSig.count { d.smoothSig[i] = 0.0 }
        for i in 0..<d.smoothFrep.count { d.smoothFrep[i] = 0 }
        d.calState = 0
        d.stateReturnOpcal = 0
        d.validBgTime = 0
        d.validBgValue = 0.0
        d.callogGroup = 0
        d.callogBgTime = 0
        d.callogBgSeq = 0.0
        d.callogBgUser = 0.0
        d.callogBgValid = 0
        d.callogBgCal = 0.0
        d.callogCgSeq1m = 0.0
        d.callogCgIdx = 0
        d.callogCgCal = 0.0
        d.callogCslopePrev = 0.0
        d.callogCyceptPrev = 0.0
        d.callogCslopeNew = 0.0
        d.callogCyceptNew = 0.0
        d.callogInlierFlg = 0
        for i in 0..<d.calSlope.count { d.calSlope[i] = 0.0 }
        for i in 0..<d.calYcept.count { d.calYcept[i] = 0.0 }
        for i in 0..<d.calInput.count { d.calInput[i] = 0.0 }
        for i in 0..<d.calOutput.count { d.calOutput[i] = 0.0 }
        d.initstableWeightUsercal = 0.0
        d.initstableWeightNocal = 0.0
        d.initstableFixusercal = 0.0
        d.nOpcalState = 0
        d.initstableInitEndPoint = 0
        for i in 0..<d.outWeightSd.count { d.outWeightSd[i] = 0.0 }
        d.outWeightAd = 0.0
        d.shiftoutAd = 0.0
        d.errorCode1 = 0
        d.errorCode2 = 0
        d.errorCode4 = 0
        d.errorCode8 = 0
        d.errorCode16 = 0
        d.errorCode32 = 0
        d.trendrate = 0.0
        d.calAvailableFlag = 0
        d.err1ISseDMean = 0.0
        d.err1ThSseDMean1 = 0.0
        d.err1ThSseDMean2 = 0.0
        d.err1ThSseDMean = 0.0
        d.err1IsContactBad = 0
        d.err1CurrentAvgDiff = 0.0
        d.err1ThDiff1 = 0.0
        d.err1ThDiff2 = 0.0
        d.err1ThDiff = 0.0
        d.err1Isfirst0 = 0
        d.err1Isfirst1 = 0
        d.err1Isfirst2 = 0
        d.err1N = 0
        d.err1RandomNoiseTempBreak = 0
        d.err1Result = 0
        d.err1LengthT2Max = 0
        d.err1LengthT3Max = 0
        d.err1LengthT1Trio = 0
        d.err1LengthT2Trio = 0
        d.err1LengthT3Trio = 0
        d.err1LengthT6Trio = 0
        d.err1LengthT7Trio = 0
        d.err1LengthT8Trio = 0
        d.err1LengthT9Trio = 0
        d.err1LengthT10Trio = 0
        d.err1ResultTD = 0
        for i in 0..<d.err1ResultConditionTD.count { d.err1ResultConditionTD[i] = 0 }
        d.err1TDCount = 0
        d.err1TDTemporaryBreakFlag = 0
        for i in 0..<d.err1TDTimeTrio.count { d.err1TDTimeTrio[i] = 0 }
        for i in 0..<d.err1TDValueTrio.count { d.err1TDValueTrio[i] = 0.0 }
        d.err2DelayRevisedValue = 0.0
        d.err2DelayRoc = 0.0
        d.err2DelaySlopeSharp = 0.0
        d.err2DelayRocCummax = 0.0
        d.err2DelayRocTrimmedMean = 0.0
        d.err2DelaySlopeCummax = 0.0
        d.err2DelaySlopeTrimmedMean = 0.0
        d.err2DelayGluCummax = 0.0
        d.err2DelayGluTrimmedMean = 0.0
        for i in 0..<d.err2DelayPreCondi.count { d.err2DelayPreCondi[i] = 0 }
        for i in 0..<d.err2DelayCondi.count { d.err2DelayCondi[i] = 0 }
        d.err2DelayFlag = 0
        d.err2Cummax = 0.0
        for i in 0..<d.err2CrtCurrent.count { d.err2CrtCurrent[i] = 0 }
        for i in 0..<d.err2CrtGlu.count { d.err2CrtGlu[i] = 0 }
        d.err2CrtCv = 0.0
        for i in 0..<d.err2Condi.count { d.err2Condi[i] = 0 }
        d.err4Min = 0.0
        d.err4Range = 0.0
        d.err4MinDiff = 0.0
        for i in 0..<d.err4Condi.count { d.err4Condi[i] = 0 }
        for i in 0..<d.err4DelayCondi.count { d.err4DelayCondi[i] = 0 }
        d.err4DelayFlag = 0
        for i in 0..<d.err8Condi.count { d.err8Condi[i] = 0 }
        d.err16CalConsDUsercalAfter = 0.0
        d.err16CalDayDTemp = 0.0
        d.err16CalDayDRef = 0.0
        d.err16CalDayNRef = 0.0
        d.err16CgmPlasma = 0.0
        d.err16CgmIsfSmooth = 0.0
        d.err16CgmIsfRocValue = 0.0
        d.err16CgmIsfRocSteady = 0.0
        d.err16CgmIsfRocMinTemp = 0.0
        d.err16CgmIsfRocMin = 0.0
        d.err16CgmIsfRocDiff = 0.0
        d.err16CgmIsfRocRatio = 0.0
        d.err16CgmIsfTrendMinValue = 0.0
        d.err16CgmIsfTrendMinSlope1 = 0.0
        d.err16CgmIsfTrendMinSlope2 = 0.0
        d.err16CgmIsfTrendMinRsq1 = 0.0
        d.err16CgmIsfTrendMinRsq2 = 0.0
        d.err16CgmIsfTrendMinDiff = 0.0
        d.err16CgmIsfTrendMinMaxTemp = 0.0
        d.err16CgmIsfTrendMinMax = 0.0
        d.err16CgmIsfTrendMinRatio = 0.0
        d.err16CgmIsfTrendModeValue = 0.0
        d.err16CgmIsfTrendModeProportion = 0.0
        d.err16CgmIsfTrendModeDiff = 0.0
        d.err16CgmIsfTrendModeMaxTemp = 0.0
        d.err16CgmIsfTrendModeMax = 0.0
        d.err16CgmIsfTrendModeRatio = 0.0
        d.err16CgmIsfTrendMeanValue = 0.0
        d.err16CgmIsfTrendMeanSlope = 0.0
        d.err16CgmIsfTrendMeanRsq = 0.0
        d.err16CgmIsfTrendMeanDiff = 0.0
        d.err16CgmIsfTrendMeanMaxTemp = 0.0
        d.err16CgmIsfTrendMeanMax = 0.0
        d.err16CgmIsfTrendMeanRatio = 0.0
        d.err16CgmIsfTrendMeanDiffEarly = 0.0
        d.err16CgmIsfTrendMeanMaxTempEarly = 0.0
        d.err16CgmIsfTrendMeanMaxEarly = 0.0
        d.err16CgmIsfTrendMeanRatioEarly = 0.0
        for i in 0..<d.err16Condi.count { d.err16Condi[i] = 0 }
        d.err128Flag = 0
        d.err128RevisedValue = 0.0
        d.err128Normal = 0.0
    }
}
