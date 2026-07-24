import Foundation

// MARK: - Constants

/// Main 14-step calibration pipeline for the CareSens Air CGM.
/// Ported from air1_opcal4_algorithm() in calibration.c.
///
/// MEDICAL SAFETY: This is life-critical code. Every calculation must match
/// the C implementation at machine-epsilon precision. Incorrect glucose values
/// lead to wrong insulin dosing, causing dangerous hypo/hyperglycemia.
public enum CalibrationAlgorithm {

    // MARK: - Constants

    // Temperature correction (lot type 1)
    static let TEMP_REF: Double = 37.0
    static let TEMP_COEFF: Double = 0.1584

    // Temperature correction (lot type 2) — retained for reference; the oracle
    // uses the lot type 1 formula for all lot types (see computeSlopeRatioTempBuffered)
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
    static let PHI: Double = 0.60653065971263342  // exp(-0.5)
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
    static func determineLotType(_ eapp: Float) -> Int {
        let dEapp: Double = Double(eapp)
        if Double.isNaN(dEapp) {
            dEapp = 0.0
        }
        let threshold: Double = 0.075
        if dEapp < threshold {
            return 2
        }
        if dEapp > threshold {
            return 1
        }
        return 0
    }

    // MARK: - ADC to current conversion

    /// Convert 30 ADC values to current.
    /// Formula: current[i] = (adc[i] * vref / 40950.0 - eapp) * 100.0
    static func adcToCurrent(_ adc: [Int], vref: Float, eapp: Float) -> [Double] {
        var current: [Double] = Array(repeating: 0.0, count: 30)
        for i in 0..<30 {
            current[i] = (Double(adc[i]) * Double(vref) / ADC_DIVISOR
                         - Double(eapp)) * 100.0
        }
        return current
    }

    // MARK: - IIR filter

    /// IIR low-pass filter. Oracle shows pass-through behavior.
    static func iirFilter(_ input: Double, args: AlgorithmState, devInfo: DeviceInfo) -> Double {
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
    static func driftCorrection(_ outIir: Double, args: AlgorithmState, debug: DebugOutput) -> Double {
        let n: Int = args.idxOriginSeq
        let seq: Double = Double(n)

        // Cubic polynomial drift factor
        let poly: Double = DRIFT_COEF_A * seq * seq * seq
            + DRIFT_COEF_B * seq * seq
            + DRIFT_COEF_C * seq
            + DRIFT_COEF_D

        // Rate blending (clamped)
        var divisor: Double
        if poly > 1.0 {
            divisor = 1.0
        } else {
            divisor = (1.0 - DRIFT_APPLY_RATE) + poly * DRIFT_APPLY_RATE
        }

        let outDrift: Double = outIir / divisor
        debug.outDrift = outDrift

        // Baseline extraction: running average
        if n == 1 {
            args.baselinePrev = outDrift
            debug.currBaseline = outDrift
            debug.initstableDiffDc = outDrift
        } else {
            let prevBaseline: Double = args.baselinePrev
            let newBaseline: Double = (prevBaseline * Double(n - 1) + outDrift) / Double(n)
            debug.currBaseline = newBaseline
            debug.initstableDiffDc = newBaseline - prevBaseline
            args.baselinePrev = newBaseline
        }

        return outDrift
    }

    // MARK: - Temperature correction with circular buffer

    /// Compute slope_ratio_temp using a 4-element circular buffer of temperatures.
    static func computeSlopeRatioTempBuffered(_ temperature: Double,
                                               args: AlgorithmState,
                                               lotType: Int) -> Double {
        let buf: [Double] = args.slopeRatioTempBuffer
        let idx: Int = args.idxOriginSeq
        let bufLen: Int = (idx < TEMP_BUF_SIZE) ? idx : TEMP_BUF_SIZE
        let bufPos: Int = (idx - 1) % TEMP_BUF_SIZE
        buf[bufPos] = temperature

        // Mean of buffered temperatures
        var tMean: Double = 0.0
        for i in 0..<bufLen {
            tMean += buf[i]
        }
        tMean /= Double(bufLen)

        // Oracle-verified: the proprietary binary uses the same temperature correction
        // formula for ALL lot types (lot_type 1 formula), not a lot_type-specific one.
        // Verified: lot0 (eapp=0.10067) and lot2 (eapp=0.05) both produce
        // srt = 1 + (-0.1584) * (T_mean - 37.0) = 1.0792 at T=36.5.
        if lotType == 1 || lotType == 2 {
            return 1.0 + (-TEMP_COEFF) * (tMean - TEMP_REF)
        } else {
            return 1.0  // lot_type 0: no correction
        }
    }

    // MARK: - Main pipeline: process()

    /// Main calibration algorithm entry point.
    /// Matches air1_opcal4_algorithm() from calibration.c.
    ///
    /// @return 1 on success, 0 on failure (matches C uint8_t return)
    public static func process(devInfo: DeviceInfo,
                               cgmInput: CgmInput,
                               calInput: CalibrationList,
                               algoArgs: AlgorithmState,
                               algoOutput: AlgorithmOutput,
                               algoDebug: DebugOutput) -> Int {
        // Clear output and debug
        clearOutput(algoOutput)
        clearDebug(algoDebug)

        let seq: Int = cgmInput.seqNumber
        let timeNow: Int64 = cgmInput.measurementTimeStandard

        // --- Step 0: First-call initialization ---
        algoArgs.idxOriginSeq += 1

        if algoArgs.idxOriginSeq == 1 {
            algoArgs.lotType = determineLotType(devInfo.eapp)
            algoArgs.sensorStartTime = devInfo.sensorStartTime
            algoArgs.stateReturnOpcal = -1
        }

        // Cumulative sequence number
        let seqFinal: Int = seq + algoArgs.cumulSum

        // --- Populate output header ---
        algoOutput.seqNumberOriginal = seq
        algoOutput.seqNumberFinal = seqFinal
        algoOutput.measurementTimeStandard = timeNow
        for i in 0..<30 {
            algoOutput.workout[i] = cgmInput.workout[i]
        }

        // --- Populate debug header ---
        algoDebug.seqNumberOriginal = seq
        algoDebug.seqNumberFinal = seqFinal
        algoDebug.measurementTimeStandard = timeNow
        algoDebug.dataType = 0
        // Note: temperature is set AFTER the eapp check below (oracle-verified:
        // the binary returns before setting temperature when eapp is invalid)
        for i in 0..<30 {
            algoDebug.workout[i] = cgmInput.workout[i]
        }

        // --- Parameter validation: eapp range check ---
        // Oracle-verified: the proprietary binary rejects eapp values outside the
        // sensor's valid operating range. eapp >= 0.12 produces errcode=64 (bit 6)
        // with zeroed output. The debug struct retains header fields (seq, time,
        // workout) but temperature stays zeroed.
        let dEappCheck: Double = Double(devInfo.eapp)
        if dEappCheck >= 0.12 {
            algoOutput.errcode = 64
            algoOutput.resultGlucose = 0.0
            return 1
        }

        algoDebug.temperature = cgmInput.temperature

        // --- Debug initialization (oracle-verified) ---
        algoDebug.stateReturnOpcal = algoArgs.stateReturnOpcal
        algoDebug.nOpcalState = -1
        algoDebug.diabetesTAR = Double.nan
        algoDebug.diabetesTBR = Double.nan
        algoDebug.diabetesCV = Double.nan
        algoDebug.levelDiabetes = 6
        algoDebug.err1ThSseDMean1 = Double.nan
        algoDebug.err1ThSseDMean2 = Double.nan
        algoDebug.err1ThSseDMean = Double.nan
        algoDebug.err1ThDiff1 = Double.nan
        algoDebug.err1ThDiff2 = Double.nan
        algoDebug.err1ThDiff = Double.nan
        algoDebug.callogCslopePrev = 1.0
        algoDebug.callogCslopeNew = 1.0
        algoDebug.initstableWeightUsercal = 1.0
        algoDebug.initstableFixusercal = 0.8
        algoDebug.trendrate = 100.0
        algoDebug.tempLocalMean = cgmInput.temperature

        // --- Validate device_info parameters ---
        let dEapp: Double = Double(devInfo.eapp)
        let dVref: Double = Double(devInfo.vref)
        let dSlope100: Double = Double(devInfo.slope100)

        if dEapp < 0.0 || dEapp > 0.5 ||
            dVref < 0.0 || dVref > 3.0 ||
            dSlope100 <= 0.0 || dSlope100 > 10.0 {
            algoDebug.nOpcalState = 1
            algoOutput.errcode = 0
            algoOutput.resultGlucose = 0.0
            return 1
        }

        // --- Step 1: ADC to current conversion ---
        let tranInA: [Double] = CalibrationAlgorithm.adcToCurrent(cgmInput.workout, vref: devInfo.vref, eapp: devInfo.eapp)
        for i in 0..<30 {
            algoDebug.tranInA[i] = tranInA[i]
        }

        // --- Step 2: Compute 1-minute averages via LOESS pipeline ---
        var timeGap: Double = 300.0  // default 5-min interval
        if algoArgs.idxOriginSeq > 1 && algoArgs.timePrev > 0 {
            timeGap = Double(timeNow - algoArgs.timePrev)
        }

        // Bridge Int8[] to UInt8[] for SignalProcessing
        var outlierFifo: [UInt8] = Array(repeating: 0, count: 6)
        for i in 0..<6 {
            outlierFifo[i] = UInt8(algoArgs.outlierMaxIndex[i])
        }

        let tranInA1min: [Double] = SignalProcessing.computeTranInA1min(
            tranInA,
            algoArgs.prevOutlierRemovedCurr,
            algoArgs.prevMovMedianCurr,
            algoArgs.prevCurrent,
            algoArgs.prevNewISig,
            outlierFifo,
            algoArgs.idxOriginSeq,
            timeGap)

        // Copy back outlier FIFO state
        for i in 0..<6 {
            algoArgs.outlierMaxIndex[i] = Int32(Int8(outlierFifo[i]))
        }

        for i in 0..<5 {
            algoDebug.tranInA1min[i] = tranInA1min[i]
        }

        // tran_inA_5min = average of 1-min values excluding min and max
        let tranInA5min: Double = MathUtils.calAverageWithoutMinMax(tranInA1min, 5)
        algoDebug.tranInA5min = tranInA5min

        // --- Step 3: Correct baseline (ycept subtraction) ---
        var correctedCurrent: Double
        let lotType: Int = algoArgs.lotType
        if lotType == 1 {
            correctedCurrent = tranInA5min - YCEPT_CONTROL
        } else if lotType == 2 {
            correctedCurrent = tranInA5min - YCEPT_TEST
        } else {
            correctedCurrent = tranInA5min
        }
        algoDebug.correctedReCurrent = correctedCurrent

        // --- Step 4: ycept = corrected current ---
        algoDebug.ycept = correctedCurrent

        // --- Step 5: IIR filter ---
        let outIir: Double = CalibrationAlgorithm.iirFilter(correctedCurrent, args: algoArgs, devInfo: devInfo)
        algoDebug.outIir = outIir

        // --- Step 6: Temperature correction ---
        let slopeRatioTemp: Double = CalibrationAlgorithm.computeSlopeRatioTempBuffered(
            cgmInput.temperature, args: algoArgs, lotType: algoArgs.lotType)
        algoDebug.slopeRatioTemp = slopeRatioTemp

        // --- Step 7: Drift correction and baseline extraction ---
        // Oracle-verified: drift correction is applied for ALL lot types (lot_type 1 and 2).
        // The proprietary binary uses the same cubic polynomial drift + baseline extraction
        // regardless of eapp/lot_type. Verified: lot2 (eapp=0.05) oracle shows
        // out_drift = out_iir / divisor, not out_drift = out_iir.
        let outDrift: Double = CalibrationAlgorithm.driftCorrection(outIir, args: algoArgs, debug: algoDebug)

        // --- Step 7b: Initstable counter ---
        {
            let threshold: Double = 0.01
            if algoArgs.idxOriginSeq > 1 {
                let diffDc: Double = algoDebug.initstableDiffDc
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
        let slopeTempProduct: Double = dSlope100 * slopeRatioTemp
        if abs(slopeTempProduct) < 1e-10 {
            algoDebug.nOpcalState = 1
            algoOutput.errcode = 64
            algoOutput.resultGlucose = 0.0
            return 1
        }
        let initCg: Double = outDrift * 100.0 / slopeTempProduct
        algoDebug.initCg = initCg

        // --- Step 9: Compute stage ---
        var currentStage: Int
        if seq <= devInfo.err345Seq2 {
            currentStage = 0
        } else {
            currentStage = 1
        }
        algoDebug.stage = currentStage
        algoOutput.currentStage = currentStage

        // --- Step 10: Kalman pass-through + bias correction state ---
        var outRescale: Double = initCg
        algoDebug.outRescale = outRescale

        // Bias correction state machine
        {
            let prevFlag: Int = algoArgs.biasFlag
            let idx: Int = algoArgs.idxOriginSeq
            let bw: Int = devInfo.basicWarmup
            let sf: Int = seqFinal

            // Track init_cg stability
            if idx > 1 {
                let deltaCg: Double = abs(initCg - algoArgs.initCgPrev)
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
        for i in 1..<4 {
            algoArgs.kalmanRoc[i] = algoArgs.kalmanRoc[i - 1]
        }
        algoArgs.kalmanRoc[0] = 0.0

        // --- Step 11: Savitzky-Golay smoothing ---
        // Save timestamps before smooth_sg corrupts via int aliasing
        var savedSmoothTime: [Int64] = Array(repeating: 0, count: 9)
        for i in 1..<10 {
            savedSmoothTime[i - 1] = algoArgs.smoothTimeIn[i]
        }

        // Convert Int64[] to Int32[] for SG
        var seqInSg: [Int32] = Array(repeating: 0, count: 10)
        for i in 0..<10 {
            seqInSg[i] = Int32(algoArgs.smoothTimeIn[i])
        }
        var frepInSg: [Int32] = Array(repeating: 0, count: 6)
        for i in 0..<6 {
            frepInSg[i] = algoArgs.smoothFRepIn[i]
        }

        let sgResult: SignalProcessing.SgResult = SignalProcessing.smoothSg(
            algoArgs.smoothSigIn, seqInSg, frepInSg,
            outRescale, seq, 0,
            devInfo.wSgX100)

        // Copy results back to state
        for i in 0..<10 {
            algoArgs.smoothSigIn[i] = sgResult.sigOut[i]
        }
        for i in 0..<10 {
            algoArgs.smoothTimeIn[i] = sgResult.seqOut[i]
        }
        for i in 0..<6 {
            algoArgs.smoothFRepIn[i] = sgResult.frepOut[i]
        }

        // Oracle-verified: smooth_result_glucose corresponds to SG buffer positions [3..8].
        // The SG buffer has 10 elements: positions [0..2] are unsmoothed
        // (shifted raw values), [3..9] are SG-convolved. The 6 output smooth values
        // come from positions [3..8]. Similarly for smooth_seq.
        for i in 0..<6 {
            algoDebug.smoothSig[i] = algoArgs.smoothSigIn[i + 3]
            algoDebug.smoothSeq[i] = Int(sgResult.seqOut[i + 3])
            algoDebug.smoothFrep[i] = sgResult.frepOut[i]
        }

        // Restore proper timestamps for trendrate
        for i in 0..<9 {
            algoArgs.smoothTimeIn[i] = savedSmoothTime[i]
        }
        algoArgs.smoothTimeIn[9] = timeNow

        // --- Step 11b: Holt bias correction ---
        var opcalAd: Double
        {
            let cnt: Int = algoArgs.biasCnt
            if cnt <= 1 {
                if cnt == 1 {
                    algoArgs.holtLevel = initCg
                    algoArgs.holtForecast = initCg
                    algoArgs.holtTrend = 0.0
                }
                opcalAd = initCg
            } else {
                // State prediction
                let levelPred: Double = PHI * algoArgs.holtLevel
                    + (1.0 - PHI) * algoArgs.holtForecast
                let forecastPred: Double = algoArgs.holtForecast + algoArgs.holtTrend
                let trendPred: Double = algoArgs.holtTrend

                // Innovation and Kalman update
                let innovation: Double = initCg - levelPred
                algoArgs.holtLevel = levelPred + HOLT_K1 * innovation
                algoArgs.holtForecast = forecastPred + HOLT_K2 * innovation
                algoArgs.holtTrend = trendPred + HOLT_K3 * innovation

                if cnt > 25 {
                    opcalAd = algoArgs.holtForecast
                } else {
                    opcalAd = initCg + (algoArgs.holtForecast - initCg)
                        * Double(cnt - 1) / 24.0
                }
            }
        }
        algoDebug.opcalAd = opcalAd
        var resultGlucose: Double = opcalAd

        algoDebug.outWeightAd = opcalAd
        algoDebug.shiftoutAd = opcalAd

        // --- Step 12: Calibration state ---
        algoDebug.calState = algoArgs.calState

        // --- Step 13: Error detection ---
        let errcode: Int = CheckError.checkError(devInfo, algoArgs, algoDebug,
            resultGlucose, correctedCurrent, seq, timeNow, currentStage)

        // Update prev_last_1min_curr
        algoArgs.err1PrevLast1minCurr = tranInA1min[4]

        // --- Step 13b: Trendrate computation ---
        computeTrendrate(algoArgs, algoDebug, errcode, timeNow)

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
        for i in 0..<30 {
            algoArgs.adcPrev[i] = cgmInput.workout[i]
        }
        algoArgs.tempPrev = cgmInput.temperature
        algoArgs.initCgPrev = initCg

        return 1
    }

    // MARK: - Trendrate computation (Step 13b)

    /// Trendrate computation
    static func computeTrendrate(_ algoArgs: AlgorithmState, _ algoDebug: DebugOutput,
                                  _ errcode: Int, _ timeNow: Int64) {
        // Update err_delay_arr: shift left, append current error status
        for i in 0..<6 {
            algoArgs.errDelayArr[i] = algoArgs.errDelayArr[i + 1]
        }
        algoArgs.errDelayArr[6] = (errcode != 0) ? 1 : 0

        // Guard: need at least 12 readings
        if algoArgs.idxOriginSeq < 12 {
            return
        }

        // Guard: 6 consecutive timestamp pairs spaced >= 181s
        // T points to smoothTimeIn[3..9]
        for i in 0..<6 {
            if algoArgs.smoothTimeIn[3 + i + 1] - algoArgs.smoothTimeIn[3 + i] < 181 {
                return
            }
        }

        // Guard: total span in [1200, 2100] seconds
        let span: Int64 = timeNow - algoArgs.smoothTimeIn[3]
        if span < 1200 || span > 2100 {
            return
        }

        // Guard: no error flags in delay array
        for i in 0..<7 {
            if algoArgs.errDelayArr[i] == 1 {
                return
            }
        }

        // Compute calibrated glucose from smooth buffer
        var glu: [Double] = Array(repeating: 0.0, count: 7)
        for i in 0..<7 {
            glu[i] = algoArgs.smoothSigIn[3 + i]
            if glu[i] <= 0.0 || glu[i] < 40.0 || glu[i] > 500.0 {
                return
            }
        }

        // Rate computation (with zero-denominator guards to prevent NaN/Infinity)
        let denomLong: Double = Double(timeNow - algoArgs.smoothTimeIn[3]) / 60.0
        if denomLong == 0.0 {
            return
        }
        let rateLong: Double = (glu[6] - glu[0]) / denomLong

        let denomShort: Double = Double(timeNow - algoArgs.smoothTimeIn[8]) / 60.0
        if denomShort == 0.0 {
            return
        }
        let rateShort: Double = (glu[6] - glu[5]) / denomShort

        // Direction guard
        if rateShort < 0.0 && rateLong >= 1.0 {
            return
        }
        if rateShort > 0.0 && rateLong <= -1.0 {
            return
        }

        let denomMid: Double = Double(algoArgs.smoothTimeIn[8] - algoArgs.smoothTimeIn[7]) / 60.0
        if denomMid == 0.0 {
            return
        }
        let rateMid: Double = (glu[5] - glu[4]) / denomMid
        algoDebug.trendrate = (rateShort * rateMid >= 0.0) ? rateShort : 0.0
    }

    // MARK: - Output/Debug clearing helpers

    /// Clear output structure
    private static func clearOutput(_ out: AlgorithmOutput) {
        out.seqNumberOriginal = 0
        out.seqNumberFinal = 0
        out.measurementTimeStandard = 0
        for i in 0..<30 {
            out.workout[i] = 0
        }
        out.resultGlucose = 0.0
        out.trendrate = 0.0
        out.currentStage = 0
        for i in 0..<6 {
            out.smoothFixedFlag[i] = 0
            out.smoothSeq[i] = 0
            out.smoothResultGlucose[i] = 0.0
        }
        out.errcode = 0
        out.calAvailableFlag = 0
        out.dataType = 0
    }

    /// Clear debug structure
    private static func clearDebug(_ d: DebugOutput) {
        d.seqNumberOriginal = 0
        d.seqNumberFinal = 0
        d.measurementTimeStandard = 0
        d.dataType = 0
        d.stage = 0
        d.temperature = 0.0
        for i in 0..<30 {
            d.workout[i] = 0
        }
        for i in 0..<30 {
            d.tranInA[i] = 0.0
        }
        for i in 0..<5 {
            d.tranInA1min[i] = 0.0
        }
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
        for i in 0..<6 {
            d.smoothSeq[i] = 0
        }
        for i in 0..<30 {
            d.smoothSig[i] = 0.0
        }
        for i in 0..<6 {
            d.smoothFrep[i] = 0
        }
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
        for i in 0..<6 {
            d.calSlope[i] = 0.0
            d.calYcept[i] = 0.0
            d.calInput[i] = 0.0
            d.calOutput[i] = 0.0
        }
        d.initstableWeightUsercal = 0.0
        d.initstableWeightNocal = 0.0
        d.initstableFixusercal = 0.0
        d.nOpcalState = 0
        d.initstableInitEndPoint = 0
        for i in 0..<30 {
            d.outWeightSd[i] = 0.0
        }
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
        for i in 0..<3 {
            d.err1ResultConditionTD[i] = 0
        }
        d.err1TDCount = 0
        d.err1TDTemporaryBreakFlag = 0
        for i in 0..<3 {
            d.err1TDTimeTrio[i] = 0
        }
        for i in 0..<3 {
            d.err1TDValueTrio[i] = 0.0
        }
        d.err2DelayRevisedValue = 0.0
        d.err2DelayRoc = 0.0
        d.err2DelaySlopeSharp = 0.0
        d.err2DelayRocCummax = 0.0
        d.err2DelayRocTrimmedMean = 0.0
        d.err2DelaySlopeCummax = 0.0
        d.err2DelaySlopeTrimmedMean = 0.0
        d.err2DelayGluCummax = 0.0
        d.err2DelayGluTrimmedMean = 0.0
        for i in 0..<6 {
            d.err2DelayPreCondi[i] = 0
        }
        for i in 0..<6 {
            d.err2DelayCondi[i] = 0
        }
        d.err2DelayFlag = 0
        d.err2Cummax = 0.0
        for i in 0..<6 {
            d.err2CrtCurrent[i] = 0.0
        }
        for i in 0..<6 {
            d.err2CrtGlu[i] = 0.0
        }
        d.err2CrtCv = 0.0
        for i in 0..<6 {
            d.err2Condi[i] = 0
        }
        d.err4Min = 0.0
        d.err4Range = 0.0
        d.err4MinDiff = 0.0
        for i in 0..<6 {
            d.err4Condi[i] = 0
        }
        for i in 0..<6 {
            d.err4DelayCondi[i] = 0
        }
        d.err4DelayFlag = 0
        for i in 0..<6 {
            d.err8Condi[i] = 0
        }
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
        for i in 0..<6 {
            d.err16Condi[i] = 0
        }
        d.err128Flag = 0
        d.err128RevisedValue = 0.0
        d.err128Normal = 0.0
    }
}

// Continued in next part...
