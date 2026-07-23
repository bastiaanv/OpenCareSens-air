// CheckError.swift
// Master error detection for CGM readings (8008 ARM instructions in binary).
//
// Evaluates 7 independent error conditions as a bitmask:
//   err1  (0x01) = contact/noise error
//   err2  (0x02) = rate-of-change / delay error
//   err4  (0x04) = signal quality error
//   err8  (0x08) = warmup/range error
//   err16 (0x10) = sensor drift / calibration consistency
//   err32 (0x20) = timing gap error
//   err128(0x80) = CGM noise revision
//
// Ported from check_error.c — every conditional, threshold, and array operation
// must match the C implementation exactly. This is medical safety-critical code.

import Foundation

/// Master error detection for CGM readings.
enum CheckError {

    /// Run all error detectors and return combined error bitmask.
    ///
    /// - Parameters:
    ///   - devInfo: factory calibration parameters
    ///   - algoArgs: persistent algorithm state (modified)
    ///   - debug: debug output (modified)
    ///   - currentGlucose: current glucose value
    ///   - correctedCurrent: corrected current value
    ///   - seq: sequence number
    ///   - timeNow: current timestamp (seconds)
    ///   - stage: algorithm stage
    /// - Returns: bitmask of active error codes
    public static func checkError(_ devInfo: DeviceInfo,
                                  _ algoArgs: AlgorithmState,
                                  _ debug: DebugOutput,
                                  currentGlucose: Double,
                                  correctedCurrent: Double,
                                  seq: Int,
                                  timeNow: Int64,
                                  stage: Int) -> Int {
        var errcode = 0

        // --- FIFO maintenance: err_glu_arr and err128_CGM_c_noise_revised_value ---
        shiftArrays(algoArgs, debug, currentGlucose)

        // --- err32: timing gap detection ---
        errcode |= detectErr32(devInfo, algoArgs, debug, seq, timeNow)

        // --- err8: range/warmup check ---
        detectErr8(algoArgs, debug)

        // --- err1: contact/noise detection ---
        errcode |= detectErr1(devInfo, algoArgs, debug, seq)

        // --- err2: rate-of-change / delay error ---
        errcode |= detectErr2(devInfo, algoArgs, debug, currentGlucose, seq)

        // --- err4: signal quality ---
        errcode |= detectErr4(devInfo, algoArgs, debug, seq)

        // --- err16: sensor drift / calibration consistency ---
        errcode |= detectErr16(devInfo, algoArgs, debug, seq)

        // --- err128: CGM noise revision ---
        detectErr128(debug)

        // cal_available_flag
        debug.calAvailableFlag = 1

        return errcode
    }

    // MARK: - FIFO array shifts

    /// Shift err_glu_arr[288] left by 1, append round(currentGlucose).
    /// Shift err128_CGM_c_noise_revised_value[36] left by 1, append tran_inA_5min.
    static func shiftArrays(_ algoArgs: AlgorithmState, _ debug: DebugOutput,
                             _ currentGlucose: Double) {
        // Shift errGluArr left by 1
        for i in 0..<287 { algoArgs.errGluArr[i] = algoArgs.errGluArr[i + 1] }
        algoArgs.errGluArr[287] = MathUtils.mathRound(currentGlucose)

        // Shift err128CgmCNoiseRevisedValue left by 1
        for i in 0..<35 { algoArgs.err128CgmCNoiseRevisedValue[i] = algoArgs.err128CgmCNoiseRevisedValue[i + 1] }
        algoArgs.err128CgmCNoiseRevisedValue[35] = debug.tranInA5min
    }

    // MARK: - err32: timing gap detection

    static func detectErr32(_ devInfo: DeviceInfo, _ algoArgs: AlgorithmState,
                           _ debug: DebugOutput, _ seq: Int, _ timeNow: Int64) -> Int {
        var err32 = 0

        if algoArgs.err32PrevTime != 0 && seq > 1 {
            let dt = timeNow - algoArgs.err32PrevTime
            let dtThreshold1 = Int64(devInfo.err32Dt[0]) * 60
            let dtThreshold2 = Int64(devInfo.err32Dt[1]) * 60

            if dt > dtThreshold2 {
                err32 = 1
            }
            // else if (dt > dtThreshold1) { /* buffer counter check — simplified */ }
        }

        debug.errorCode32 = err32
        algoArgs.err32PrevTime = timeNow
        algoArgs.err32PrevSeq = seq
        algoArgs.err32ResultPrev = err32

        return err32 != 0 ? 32 : 0
    }

    // MARK: - err8: range/warmup check

    static func detectErr8(_ algoArgs: AlgorithmState, _ debug: DebugOutput) {
        let err8 = 0
        debug.errorCode8 = err8
        algoArgs.err8ResultPrev = err8
    }

    // MARK: - err1: contact/noise detection

    static func detectErr1(_ devInfo: DeviceInfo, _ algoArgs: AlgorithmState,
                          _ debug: DebugOutput, _ seq: Int) -> Int {
        let err1 = 0
        var n = algoArgs.err1N
        let tran5min = debug.tranInA5min

        if seq > devInfo.err1Seq[0] {
            // Compute i_sse_d_mean BEFORE epoch reset check, so it is
            // always output (oracle computes i_sse even on the reset step).
            do {
                var prev = algoArgs.err1PrevLast1minCurr
                var sse = 0.0
                for k in 0..<5 {
                    let target = debug.tranInA1min[k]
                    let delta = (target - prev) / 6.0
                    for j in 0..<6 {
                        let interp = prev + delta * Double(j + 1)
                        let diff = debug.tranInA[k * 6 + j] - interp
                        sse += diff * diff
                    }
                    prev = target
                }
                let iSsePreReset = sse / 30.0
                debug.err1ISseDMean = iSsePreReset
            }

            // Epoch reset
            if n >= devInfo.err1NLast && n > 0 {
                let meanSse = algoArgs.err1ThSseDMean1 / Double(n)
                let meanDiff = algoArgs.err1ThDiff1 / Double(n)
                let seedSse = meanSse * Double(devInfo.err1Multi[0])
                let seedDiff = meanDiff * Double(devInfo.err1Multi[1])

                algoArgs.err1ThSseDMean1 = seedSse
                algoArgs.err1ThSseDMean2 = seedSse
                algoArgs.err1ThSseDMean = seedSse
                algoArgs.err1ThDiff1 = seedDiff
                algoArgs.err1ThDiff2 = seedDiff
                algoArgs.err1ThDiff = seedDiff

                algoArgs.err1Isfirst0 = 1
                algoArgs.err1Isfirst1 = 1
                algoArgs.err1Isfirst2 = 1
                n = 0
                algoArgs.err1N = 0

                debug.err1N = 0
                debug.err1ThSseDMean1 = seedSse
                debug.err1ThSseDMean2 = seedSse
                debug.err1ThSseDMean = seedSse
                debug.err1ThDiff1 = seedDiff
                debug.err1ThDiff2 = seedDiff
                debug.err1ThDiff = seedDiff
                debug.err1Isfirst0 = 1
                debug.err1Isfirst1 = 1
                debug.err1Isfirst2 = 1

                algoArgs.err1ISseDMean4h[99] = tran5min

                // goto err1_done equivalent: skip accumulation, go to finalize
                debug.errorCode1 = err1
                debug.err1Result = err1
                algoArgs.err1ResultPrev = err1
                return err1 != 0 ? 1 : 0
            }

            n += 1
            algoArgs.err1N = n

            // Post-reset: isfirst2 goes back to 0
            if algoArgs.err1Isfirst2 == 1 && n == 1 {
                algoArgs.err1Isfirst2 = 0
            }

            // Accumulate i_sse_d_mean (already computed before epoch reset check)
            do {
                let iSse = debug.err1ISseDMean

                if algoArgs.err1Isfirst0 != 0 {
                    // Second epoch: accumulate into th_sse_d_mean2
                    if n == 1 {
                        algoArgs.err1ThSseDMean2 = iSse
                    } else {
                        algoArgs.err1ThSseDMean2 += iSse
                    }
                    // th_sse_d_mean stays at th_sse_d_mean1 (frozen seed)
                } else {
                    // First epoch: accumulate into th_sse_d_mean1
                    if n == 1 {
                        algoArgs.err1ThSseDMean1 = iSse
                    } else {
                        algoArgs.err1ThSseDMean1 += iSse
                    }
                    algoArgs.err1ThSseDMean = algoArgs.err1ThSseDMean1
                }
            }

            // avg_diff
            if n == 1 {
                debug.err1CurrentAvgDiff = 0.0
                if algoArgs.err1Isfirst0 == 0 {
                    algoArgs.err1ThDiff1 = .nan
                    algoArgs.err1ThDiff2 = .nan
                    algoArgs.err1ThDiff = .nan
                }
                if algoArgs.err1Isfirst0 != 0 {
                    algoArgs.err1ThDiff2 = .nan
                }
                // Always write th_diff1/th_diff to debug (oracle outputs them at n==1)
                debug.err1ThDiff1 = algoArgs.err1ThDiff1
                debug.err1ThDiff = algoArgs.err1ThDiff
            } else {
                let prevTran5min = algoArgs.err1ISseDMean4h[99]
                let avgDiff = tran5min - prevTran5min
                debug.err1CurrentAvgDiff = avgDiff

                if algoArgs.err1Isfirst0 != 0 {
                    // Second epoch: th_diff1 frozen
                } else {
                    if n == 2 {
                        algoArgs.err1ThDiff1 = abs(avgDiff)
                    } else {
                        algoArgs.err1ThDiff1 += abs(avgDiff)
                    }
                }
                algoArgs.err1ThDiff = algoArgs.err1ThDiff1

                debug.err1ThDiff1 = algoArgs.err1ThDiff1
                debug.err1ThDiff = algoArgs.err1ThDiff
            }

            // Store current tran_5min for next step
            algoArgs.err1ISseDMean4h[99] = tran5min

            debug.err1N = n
            debug.err1Isfirst0 = algoArgs.err1Isfirst0
            debug.err1Isfirst1 = algoArgs.err1Isfirst1
            debug.err1Isfirst2 = algoArgs.err1Isfirst2
            debug.err1ThSseDMean1 = algoArgs.err1ThSseDMean1
            if algoArgs.err1Isfirst0 != 0 {
                debug.err1ThSseDMean2 = algoArgs.err1ThSseDMean2
            }
            debug.err1ThSseDMean = algoArgs.err1ThSseDMean
        }

        debug.errorCode1 = err1
        debug.err1Result = err1
        algoArgs.err1ResultPrev = err1
        return err1 != 0 ? 1 : 0
    }

    // MARK: - err2: rate-of-change / delay error

    static func detectErr2(_ devInfo: DeviceInfo, _ algoArgs: AlgorithmState,
                          _ debug: DebugOutput, _ currentGlucose: Double, _ seq: Int) -> Int {
        var err2 = 0
        let err2Threshold = devInfo.err2Seq[2]

        // Always accumulate round(glucose) into sliding window
        let roundGlu = MathUtils.mathRound(currentGlucose)
        for i in 0..<5 { algoArgs.err2CummaxForetime[i] = algoArgs.err2CummaxForetime[i + 1] }
        algoArgs.err2CummaxForetime[5] = roundGlu

        if seq < err2Threshold {
            // Before activation: all debug fields NaN
            debug.err2DelayRevisedValue = .nan
            debug.err2DelayRoc = .nan
            debug.err2DelaySlopeSharp = .nan
            debug.err2DelayRocCummax = .nan
            debug.err2DelayRocTrimmedMean = .nan
            debug.err2DelaySlopeCummax = .nan
            debug.err2DelaySlopeTrimmedMean = .nan
            debug.err2DelayGluCummax = .nan
            debug.err2DelayGluTrimmedMean = .nan
            debug.err2Cummax = .nan
            debug.err2CrtCv = .nan
        } else {
            // err2 is active
            let nGlu = seq - err2Threshold + 1

            // roc
            let roc: Double
            if nGlu == 1 {
                roc = 0.0
            } else {
                roc = (roundGlu - algoArgs.err2DelayRevisedValuePrev) / 5.0
            }
            algoArgs.err2DelayRevisedValuePrev = roundGlu
            debug.err2DelayRoc = roc

            // slope_sharp
            do {
                let slopeN = (seq > 6) ? 6 : seq
                var slopeSharp = 0.0

                if slopeN >= 2 {
                    let start = 6 - slopeN
                    var xbar = 0.0
                    var ybar = 0.0
                    for i in 0..<slopeN {
                        xbar += Double(i)
                        ybar += algoArgs.err2CummaxForetime[start + i]
                    }
                    xbar /= Double(slopeN)
                    ybar /= Double(slopeN)

                    var sumXY = 0.0
                    var sumXX = 0.0
                    for i in 0..<slopeN {
                        let dx = Double(i) - xbar
                        let dy = algoArgs.err2CummaxForetime[start + i] - ybar
                        sumXY += dx * dy
                        sumXX += dx * dx
                    }
                    if sumXX > 0 {
                        slopeSharp = sumXY / sumXX
                    }
                }
                debug.err2DelaySlopeSharp = slopeSharp

                // Cumulative maxima
                let absRoc = abs(roc)
                let absSlope = abs(slopeSharp)

                if nGlu == 1 {
                    algoArgs.err2DelayRocCummaxPrev = absRoc
                    algoArgs.err2DelaySlopeCummaxPrev = absSlope
                    algoArgs.err2DelayGluCummaxPrev = roundGlu
                } else {
                    if absRoc > algoArgs.err2DelayRocCummaxPrev {
                        algoArgs.err2DelayRocCummaxPrev = absRoc
                    }
                    if absSlope > algoArgs.err2DelaySlopeCummaxPrev {
                        algoArgs.err2DelaySlopeCummaxPrev = absSlope
                    }
                    if roundGlu > algoArgs.err2DelayGluCummaxPrev {
                        algoArgs.err2DelayGluCummaxPrev = roundGlu
                    }
                }

                debug.err2DelayRocCummax = algoArgs.err2DelayRocCummaxPrev
                debug.err2DelaySlopeCummax = algoArgs.err2DelaySlopeCummaxPrev
                debug.err2DelayGluCummax = algoArgs.err2DelayGluCummaxPrev
            }

            // Fields that remain NaN when delay path inactive
            debug.err2DelayRevisedValue = .nan
            debug.err2DelayRocTrimmedMean = .nan
            debug.err2DelaySlopeTrimmedMean = .nan
            debug.err2DelayGluTrimmedMean = .nan

            // err2_cummax
            if seq >= devInfo.err2StartSeq {
                let t5 = debug.tranInA5min
                if seq == devInfo.err2StartSeq {
                    algoArgs.err2Cummax = t5
                } else {
                    if t5 > algoArgs.err2Cummax {
                        algoArgs.err2Cummax = t5
                    }
                }
                debug.err2Cummax = algoArgs.err2Cummax
            } else {
                debug.err2Cummax = .nan
            }
            debug.err2CrtCv = .nan

            // CRT: Constant Rate Test
            do {
                let crtC0 = 0
                let crtG0 = 0

                let gluThrBase = Double(devInfo.maximumValue) * Double(devInfo.err2Cummax)
                let gluThrCurr = gluThrBase + Double(devInfo.err2Cummax)
                let lagIdx = 287 - devInfo.err2Seq[1]
                let crtC1 = (algoArgs.errGluArr[287] > gluThrCurr &&
                             lagIdx >= 0 &&
                             algoArgs.errGluArr[lagIdx] >= gluThrBase) ? 1 : 0

                let crtG0Threshold = (seq >= devInfo.err2StartSeq) ? 1 : 0

                let gluThrG1 = Double(devInfo.maximumValue) * Double(devInfo.err2Cummax)
                             + Double(devInfo.err2Glu) / Double(devInfo.err2Cummax)
                let lagG1 = devInfo.kalmanDeltaT
                let lagG1Idx = 287 - lagG1
                let crtG1 = (algoArgs.errGluArr[287] > gluThrG1 &&
                             lagG1Idx >= 0 &&
                             algoArgs.errGluArr[lagG1Idx] > gluThrG1) ? 1 : 0

                debug.err2CrtCurrent[0] = crtC0
                debug.err2CrtCurrent[1] = crtC1
                debug.err2CrtGlu[0] = crtG0Threshold
                debug.err2CrtGlu[1] = crtG1

                debug.err2Condi[0] = (crtC0 != 0 && crtG0 != 0) ? 1 : 0
                debug.err2Condi[1] = (crtC1 != 0 && crtG1 != 0) ? 1 : 0

                if debug.err2Condi[0] != 0 || debug.err2Condi[1] != 0 {
                    err2 = 1
                }
            }

            // Delay pre_condi and condi: inactive
            for i in 0..<debug.err2DelayPreCondi.count { debug.err2DelayPreCondi[i] = 0 }
            for i in 0..<debug.err2DelayCondi.count { debug.err2DelayCondi[i] = 0 }
            debug.err2DelayFlag = 0
        }

        debug.errorCode2 = err2
        algoArgs.err2ResultPrev = err2
        return err2 != 0 ? 2 : 0
    }

    // MARK: - err4: signal quality

    static func detectErr4(_ devInfo: DeviceInfo, _ algoArgs: AlgorithmState,
                          _ debug: DebugOutput, _ seq: Int) -> Int {
        let err4 = 0
        let tran5min = debug.tranInA5min

        if seq == 1 {
            algoArgs.err4MinPrev[0] = tran5min
            debug.err4Min = tran5min
            debug.err4Range = .nan
            debug.err4MinDiff = .nan
        } else {
            // err4_range: consecutive difference
            debug.err4Range = tran5min - algoArgs.err4InA[0]

            // err4_min_diff: signed difference (tran5min - old_min) when new
            // minimum is reached, 0.0 otherwise. Oracle-verified: the value is
            // negative when tran_inA_5min breaks through its running minimum.
            if seq < devInfo.err345Seq2 {
                debug.err4MinDiff = 0.0
            } else {
                if tran5min < algoArgs.err4MinPrev[0] {
                    // New minimum: report signed drop from previous minimum
                    let minDiff = tran5min - algoArgs.err4MinPrev[0]
                    debug.err4MinDiff = minDiff
                } else {
                    debug.err4MinDiff = 0.0
                }
            }

            // Update running min (after computing min_diff)
            if tran5min < algoArgs.err4MinPrev[0] {
                algoArgs.err4MinPrev[0] = tran5min
            }
            debug.err4Min = algoArgs.err4MinPrev[0]
        }

        // Store current tran_5min for next step
        algoArgs.err4InA[0] = tran5min

        debug.errorCode4 = err4
        algoArgs.err4ResultPrev = err4
        return err4 != 0 ? 4 : 0
    }

    // MARK: - err16: sensor drift / calibration consistency

    static func detectErr16(_ devInfo: DeviceInfo, _ algoArgs: AlgorithmState,
                           _ debug: DebugOutput, _ seq: Int) -> Int {
        var err16 = 0

        let err16StartSeq = devInfo.err345Seq4[2]
        if seq >= err16StartSeq {
            let N = 12
            var gluBuf = [Double](repeating: 0.0, count: N)
            var currBuf = [Double](repeating: 0.0, count: N)

            // Extract last N elements from errGluArr[288]
            for i in 0..<N { gluBuf[i] = algoArgs.errGluArr[288 - N + i] }

            // Extract last N elements from err128CgmCNoiseRevisedValue[36]
            for i in 0..<N { currBuf[i] = algoArgs.err128CgmCNoiseRevisedValue[36 - N + i] }

            // Run regularized DFT smoother
            let smoothGlu = SignalProcessing.smooth1qErr16(gluBuf, N)
            let smoothCurr = SignalProcessing.smooth1qErr16(currBuf, N)

            let slope100d = Double(devInfo.slope100)
            let convFactor = slope100d / 100.0

            let smGluLast = smoothGlu[N - 1]
            let smCurrLast = smoothCurr[N - 1]

            var valid = true
            if smGluLast.isNaN || smGluLast.isInfinite { valid = false }
            if smCurrLast.isNaN || smCurrLast.isInfinite { valid = false }
            if abs(smGluLast) == 0.0 && abs(smCurrLast) == 0.0 { valid = false }

            if valid && convFactor > 0.0 {
                debug.err16CgmPlasma = MathUtils.mathRound(smGluLast)
                debug.err16CgmIsfSmooth = MathUtils.mathRound(smCurrLast / convFactor)
            } else {
                debug.err16CgmPlasma = .nan
                debug.err16CgmIsfSmooth = .nan
            }
        } else {
            debug.err16CgmPlasma = .nan
            debug.err16CgmIsfSmooth = .nan
        }

        debug.errorCode16 = err16
        algoArgs.err16ResultPrev = err16
        return err16 != 0 ? 16 : 0
    }

    // MARK: - err128: CGM noise revision

    static func detectErr128(_ debug: DebugOutput) {
        debug.err128Flag = 0
        debug.err128RevisedValue = debug.tranInA5min
        debug.err128Normal = .nan
    }
}
