// OracleBinaryReader.swift
// Reads oracle binary verification files produced by the C oracle harness.
//
// Binary formats match the C structs in calibration.h:
// - output_t: 155 bytes, packed (__attribute__((packed)) / #pragma pack(1))
// - debug_t:  1579 bytes, packed
// - cgm_input_t: 74 bytes, packed
// - arguments_t: 117312 bytes, natural ARM alignment
//
// All files are little-endian (ARM).

import Foundation

/// Error type for oracle binary reading failures.
enum OracleError: Error {
    case sizeMismatch(expected: Int, actual: Int, path: String)
    case positionMismatch(expected: Int, actual: Int)
}

/// Reads oracle binary verification files produced by the C oracle harness.
enum OracleBinaryReader {

    static let outputSize = 155
    static let debugSize = 1579
    static let inputSize = 74
    static let argsSize = 117312

    // MARK: - Little-endian reading helpers

    private static func readUInt16LE(_ data: Data, at offset: Int) -> UInt16 {
        UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    private static func readUInt32LE(_ data: Data, at offset: Int) -> UInt32 {
        UInt32(data[offset]) | (UInt32(data[offset + 1]) << 8) |
        (UInt32(data[offset + 2]) << 16) | (UInt32(data[offset + 3]) << 24)
    }

    private static func readDoubleLE(_ data: Data, at offset: Int) -> Double {
        var bits: UInt64 = 0
        for i in 0..<8 {
            bits |= UInt64(data[offset + i]) << (i * 8)
        }
        return Double(bitPattern: bits)
    }

    private static func readInt8(_ data: Data, at offset: Int) -> Int8 {
        Int8(bitPattern: data[offset])
    }

    private static func readUInt8(_ data: Data, at offset: Int) -> UInt8 {
        data[offset]
    }

    // MARK: - File loading helper

    private static func loadData(from url: URL, expectedSize: Int) throws -> Data {
        let data = try Data(contentsOf: url)
        if data.count != expectedSize {
            throw OracleError.sizeMismatch(expected: expectedSize, actual: data.count, path: url.path)
        }
        return data
    }

    // MARK: - Convenience: load by directory + seq number

    static func readOutput(oracleDir: String, seq: Int) throws -> AlgorithmOutput {
        let url = URL(fileURLWithPath: oracleDir)
            .appendingPathComponent("seq_\(String(format: "%04d", seq))_output.bin")
        return try readOutput(from: url)
    }

    static func readDebug(oracleDir: String, seq: Int) throws -> DebugOutput {
        let url = URL(fileURLWithPath: oracleDir)
            .appendingPathComponent("seq_\(String(format: "%04d", seq))_debug.bin")
        return try readDebug(from: url)
    }

    static func readInput(oracleDir: String, seq: Int) throws -> CgmInput {
        let url = URL(fileURLWithPath: oracleDir)
            .appendingPathComponent("seq_\(String(format: "%04d", seq))_input.bin")
        return try readInput(from: url)
    }

    // MARK: - output_t: 155 bytes, packed
    // Layout from calibration.h (packed):
    //   uint16_t seq_number_original;      // 0
    //   uint16_t seq_number_final;         // 2
    //   uint32_t measurement_time_standard;// 4
    //   uint16_t workout[30];              // 8  (60 bytes)
    //   double result_glucose;             // 68
    //   double trendrate;                  // 76
    //   uint8_t current_stage;             // 84
    //   uint8_t smooth_fixed_flag[6];      // 85
    //   uint16_t smooth_seq[6];            // 91 (12 bytes)
    //   double smooth_result_glucose[6];   // 103 (48 bytes)
    //   uint16_t errcode;                  // 151
    //   uint8_t cal_available_flag;        // 153
    //   uint8_t data_type;                 // 154
    //   TOTAL = 155

    static func readOutput(from url: URL) throws -> AlgorithmOutput {
        let data = try loadData(from: url, expectedSize: outputSize)
        let out = AlgorithmOutput()

        out.seqNumberOriginal = Int(readUInt16LE(data, at: 0))               // 0
        out.seqNumberFinal = Int(readUInt16LE(data, at: 2))                  // 2
        out.measurementTimeStandard = Int64(readUInt32LE(data, at: 4))       // 4
        for i in 0..<30 {                                                    // 8
            out.workout[i] = Int(readUInt16LE(data, at: 8 + i * 2))
        }
        out.resultGlucose = readDoubleLE(data, at: 68)                       // 68
        out.trendrate = readDoubleLE(data, at: 76)                           // 76
        out.currentStage = Int(readUInt8(data, at: 84))                      // 84
        for i in 0..<6 {                                                     // 85
            out.smoothFixedFlag[i] = Int(readUInt8(data, at: 85 + i))
        }
        for i in 0..<6 {                                                     // 91
            out.smoothSeq[i] = Int(readUInt16LE(data, at: 91 + i * 2))
        }
        for i in 0..<6 {                                                     // 103
            out.smoothResultGlucose[i] = readDoubleLE(data, at: 103 + i * 8)
        }
        out.errcode = Int(readUInt16LE(data, at: 151))                       // 151
        out.calAvailableFlag = Int(readUInt8(data, at: 153))                 // 153
        out.dataType = Int(readUInt8(data, at: 154))                         // 154

        return out
    }

    // MARK: - debug_t: 1579 bytes, packed
    // Field offsets verified against compare_oracle.c

    static func readDebug(from url: URL) throws -> DebugOutput {
        let data = try loadData(from: url, expectedSize: debugSize)
        let d = DebugOutput()

        d.seqNumberOriginal = Int(readUInt16LE(data, at: 0))                 // 0
        d.seqNumberFinal = Int(readUInt16LE(data, at: 2))                    // 2
        d.measurementTimeStandard = Int64(readUInt32LE(data, at: 4))         // 4
        d.dataType = Int(readUInt8(data, at: 8))                             // 8
        d.stage = Int(readUInt8(data, at: 9))                                // 9
        d.temperature = readDoubleLE(data, at: 10)                           // 10
        for i in 0..<30 {                                                    // 18
            d.workout[i] = Int(readUInt16LE(data, at: 18 + i * 2))
        }
        for i in 0..<30 {                                                    // 78
            d.tranInA[i] = readDoubleLE(data, at: 78 + i * 8)
        }
        for i in 0..<5 {                                                     // 318
            d.tranInA1min[i] = readDoubleLE(data, at: 318 + i * 8)
        }
        d.tranInA5min = readDoubleLE(data, at: 358)                          // 358
        d.ycept = readDoubleLE(data, at: 366)                                // 366
        d.correctedReCurrent = readDoubleLE(data, at: 374)                   // 374
        d.diabetesMeanX = readDoubleLE(data, at: 382)                        // 382
        d.diabetesM2 = readDoubleLE(data, at: 390)                           // 390
        d.diabetesTAR = readDoubleLE(data, at: 398)                          // 398
        d.diabetesTBR = readDoubleLE(data, at: 406)                          // 406
        d.diabetesCV = readDoubleLE(data, at: 414)                           // 414
        d.levelDiabetes = Int(readUInt8(data, at: 422))                      // 422
        d.outIir = readDoubleLE(data, at: 423)                               // 423
        d.outDrift = readDoubleLE(data, at: 431)                             // 431
        d.currBaseline = readDoubleLE(data, at: 439)                         // 439
        d.initstableDiffDc = readDoubleLE(data, at: 447)                     // 447
        d.initstableInitcnt = Int(readUInt16LE(data, at: 455))               // 455
        d.tempLocalMean = readDoubleLE(data, at: 457)                        // 457
        d.slopeRatioTemp = readDoubleLE(data, at: 465)                       // 465
        d.initCg = readDoubleLE(data, at: 473)                               // 473
        d.outRescale = readDoubleLE(data, at: 481)                           // 481
        d.opcalAd = readDoubleLE(data, at: 489)                              // 489
        d.stateInitKalman = Int(readUInt8(data, at: 497))                    // 497

        // smooth_seq[6]: uint16_t at 498
        for i in 0..<6 {
            d.smoothSeq[i] = Int(readUInt16LE(data, at: 498 + i * 2))
        }
        // smooth_sig[6]: double at 510
        for i in 0..<6 {
            d.smoothSig[i] = readDoubleLE(data, at: 510 + i * 8)
        }
        // smooth_frep[6]: uint8_t at 558
        for i in 0..<6 {
            d.smoothFrep[i] = Int(readUInt8(data, at: 558 + i))
        }

        d.calState = Int(readUInt8(data, at: 564))                           // 564
        d.stateReturnOpcal = Int(readInt8(data, at: 565))                    // 565 (int8_t = signed)
        d.validBgTime = Int64(readUInt32LE(data, at: 566))                   // 566
        d.validBgValue = readDoubleLE(data, at: 570)                         // 570
        d.callogGroup = Int(readUInt8(data, at: 578))                        // 578
        d.callogBgTime = Int64(readUInt32LE(data, at: 579))                  // 579
        d.callogBgSeq = readDoubleLE(data, at: 583)                          // 583
        d.callogBgUser = readDoubleLE(data, at: 591)                         // 591
        d.callogBgValid = Int(readInt8(data, at: 599))                       // 599 (int8_t)
        d.callogBgCal = readDoubleLE(data, at: 600)                          // 600
        d.callogCgSeq1m = readDoubleLE(data, at: 608)                        // 608
        d.callogCgIdx = Int(readUInt16LE(data, at: 616))                     // 616
        d.callogCgCal = readDoubleLE(data, at: 618)                          // 618
        d.callogCslopePrev = readDoubleLE(data, at: 626)                     // 626
        d.callogCyceptPrev = readDoubleLE(data, at: 634)                     // 634
        d.callogCslopeNew = readDoubleLE(data, at: 642)                      // 642
        d.callogCyceptNew = readDoubleLE(data, at: 650)                      // 650
        d.callogInlierFlg = Int(readUInt8(data, at: 658))                    // 658

        // cal_slope[7]: double at 659
        for i in 0..<7 {
            d.calSlope[i] = readDoubleLE(data, at: 659 + i * 8)
        }
        // cal_ycept[7]: double at 715
        for i in 0..<7 {
            d.calYcept[i] = readDoubleLE(data, at: 715 + i * 8)
        }
        // cal_input[7]: double at 771
        for i in 0..<7 {
            d.calInput[i] = readDoubleLE(data, at: 771 + i * 8)
        }
        // cal_output[7]: double at 827
        for i in 0..<7 {
            d.calOutput[i] = readDoubleLE(data, at: 827 + i * 8)
        }

        d.initstableWeightUsercal = readDoubleLE(data, at: 883)              // 883
        d.initstableWeightNocal = readDoubleLE(data, at: 891)                // 891
        d.initstableFixusercal = readDoubleLE(data, at: 899)                 // 899
        d.nOpcalState = Int(readInt8(data, at: 907))                         // 907 (int8_t)
        d.initstableInitEndPoint = Int(readUInt16LE(data, at: 908))          // 908

        // out_weight_sd[6]: double at 910
        for i in 0..<6 {
            d.outWeightSd[i] = readDoubleLE(data, at: 910 + i * 8)
        }
        d.outWeightAd = readDoubleLE(data, at: 958)                         // 958
        d.shiftoutAd = readDoubleLE(data, at: 966)                          // 966

        d.errorCode1 = Int(readUInt8(data, at: 974))                        // 974
        d.errorCode2 = Int(readUInt8(data, at: 975))                        // 975
        d.errorCode4 = Int(readUInt8(data, at: 976))                        // 976
        d.errorCode8 = Int(readUInt8(data, at: 977))                        // 977
        d.errorCode16 = Int(readUInt8(data, at: 978))                       // 978
        d.errorCode32 = Int(readUInt8(data, at: 979))                       // 979

        d.trendrate = readDoubleLE(data, at: 980)                           // 980
        d.calAvailableFlag = Int(readUInt8(data, at: 988))                  // 988

        // err1 fields
        d.err1ISseDMean = readDoubleLE(data, at: 989)                       // 989
        d.err1ThSseDMean1 = readDoubleLE(data, at: 997)                     // 997
        d.err1ThSseDMean2 = readDoubleLE(data, at: 1005)                    // 1005
        d.err1ThSseDMean = readDoubleLE(data, at: 1013)                     // 1013
        d.err1IsContactBad = Int(readUInt8(data, at: 1021))                 // 1021
        d.err1CurrentAvgDiff = readDoubleLE(data, at: 1022)                 // 1022
        d.err1ThDiff1 = readDoubleLE(data, at: 1030)                        // 1030
        d.err1ThDiff2 = readDoubleLE(data, at: 1038)                        // 1038
        d.err1ThDiff = readDoubleLE(data, at: 1046)                         // 1046
        d.err1Isfirst0 = Int(readUInt8(data, at: 1054))                     // 1054
        d.err1Isfirst1 = Int(readUInt8(data, at: 1055))                     // 1055
        d.err1Isfirst2 = Int(readUInt8(data, at: 1056))                     // 1056
        d.err1N = Int(readUInt16LE(data, at: 1057))                         // 1057
        d.err1RandomNoiseTempBreak = Int(readUInt8(data, at: 1059))         // 1059
        d.err1Result = Int(readUInt8(data, at: 1060))                       // 1060

        d.err1LengthT2Max = Int(readUInt8(data, at: 1061))                  // 1061
        d.err1LengthT3Max = Int(readUInt8(data, at: 1062))                  // 1062
        d.err1LengthT1Trio = Int(readUInt8(data, at: 1063))                 // 1063
        d.err1LengthT2Trio = Int(readUInt8(data, at: 1064))                 // 1064
        d.err1LengthT3Trio = Int(readUInt8(data, at: 1065))                 // 1065
        d.err1LengthT6Trio = Int(readUInt8(data, at: 1066))                 // 1066
        d.err1LengthT7Trio = Int(readUInt8(data, at: 1067))                 // 1067
        d.err1LengthT8Trio = Int(readUInt8(data, at: 1068))                 // 1068
        d.err1LengthT9Trio = Int(readUInt8(data, at: 1069))                 // 1069
        d.err1LengthT10Trio = Int(readUInt8(data, at: 1070))                // 1070

        d.err1ResultTD = Int(readUInt8(data, at: 1071))                     // 1071
        for i in 0..<2 {                                                     // 1072
            d.err1ResultConditionTD[i] = Int(readUInt8(data, at: 1072 + i))
        }
        d.err1TDCount = Int(readUInt16LE(data, at: 1074))                   // 1074
        d.err1TDTemporaryBreakFlag = Int(readUInt8(data, at: 1076))         // 1076
        for i in 0..<3 {                                                     // 1077
            d.err1TDTimeTrio[i] = Int64(readUInt32LE(data, at: 1077 + i * 4))
        }
        for i in 0..<3 {                                                     // 1089
            d.err1TDValueTrio[i] = readDoubleLE(data, at: 1089 + i * 8)
        }

        // err2 fields                                                        // 1113
        d.err2DelayRevisedValue = readDoubleLE(data, at: 1113)               // 1113
        d.err2DelayRoc = readDoubleLE(data, at: 1121)                        // 1121
        d.err2DelaySlopeSharp = readDoubleLE(data, at: 1129)                 // 1129
        d.err2DelayRocCummax = readDoubleLE(data, at: 1137)                  // 1137
        d.err2DelayRocTrimmedMean = readDoubleLE(data, at: 1145)             // 1145
        d.err2DelaySlopeCummax = readDoubleLE(data, at: 1153)                // 1153
        d.err2DelaySlopeTrimmedMean = readDoubleLE(data, at: 1161)           // 1161
        d.err2DelayGluCummax = readDoubleLE(data, at: 1169)                  // 1169
        d.err2DelayGluTrimmedMean = readDoubleLE(data, at: 1177)             // 1177
        for i in 0..<3 {
            d.err2DelayPreCondi[i] = Int(readUInt8(data, at: 1185 + i))      // 1185
        }
        for i in 0..<3 {
            d.err2DelayCondi[i] = Int(readUInt8(data, at: 1188 + i))         // 1188
        }
        d.err2DelayFlag = Int(readUInt8(data, at: 1191))                     // 1191
        d.err2Cummax = readDoubleLE(data, at: 1192)                          // 1192
        for i in 0..<2 {
            d.err2CrtCurrent[i] = Int(readUInt8(data, at: 1200 + i))         // 1200
        }
        for i in 0..<2 {
            d.err2CrtGlu[i] = Int(readUInt8(data, at: 1202 + i))             // 1202
        }
        d.err2CrtCv = readDoubleLE(data, at: 1204)                          // 1204
        for i in 0..<2 {
            d.err2Condi[i] = Int(readUInt8(data, at: 1212 + i))              // 1212
        }

        // err4 fields
        d.err4Min = readDoubleLE(data, at: 1214)                            // 1214
        d.err4Range = readDoubleLE(data, at: 1222)                          // 1222
        d.err4MinDiff = readDoubleLE(data, at: 1230)                        // 1230
        for i in 0..<5 {
            d.err4Condi[i] = Int(readUInt8(data, at: 1238 + i))              // 1238
        }
        for i in 0..<5 {
            d.err4DelayCondi[i] = Int(readUInt8(data, at: 1243 + i))         // 1243
        }
        d.err4DelayFlag = Int(readUInt8(data, at: 1248))                    // 1248

        // err8 fields
        for i in 0..<2 {
            d.err8Condi[i] = Int(readUInt8(data, at: 1249 + i))              // 1249
        }

        // err16 fields
        d.err16CalConsDUsercalAfter = readDoubleLE(data, at: 1251)          // 1251
        d.err16CalDayDTemp = readDoubleLE(data, at: 1259)                   // 1259
        d.err16CalDayDRef = readDoubleLE(data, at: 1267)                    // 1267
        d.err16CalDayNRef = readDoubleLE(data, at: 1275)                    // 1275
        d.err16CgmPlasma = readDoubleLE(data, at: 1283)                     // 1283
        d.err16CgmIsfSmooth = readDoubleLE(data, at: 1291)                  // 1291
        d.err16CgmIsfRocValue = readDoubleLE(data, at: 1299)                // 1299
        d.err16CgmIsfRocSteady = readDoubleLE(data, at: 1307)               // 1307
        d.err16CgmIsfRocMinTemp = readDoubleLE(data, at: 1315)              // 1315
        d.err16CgmIsfRocMin = readDoubleLE(data, at: 1323)                  // 1323
        d.err16CgmIsfRocDiff = readDoubleLE(data, at: 1331)                 // 1331
        d.err16CgmIsfRocRatio = readDoubleLE(data, at: 1339)                // 1339
        d.err16CgmIsfTrendMinValue = readDoubleLE(data, at: 1347)           // 1347
        d.err16CgmIsfTrendMinSlope1 = readDoubleLE(data, at: 1355)          // 1355
        d.err16CgmIsfTrendMinSlope2 = readDoubleLE(data, at: 1363)          // 1363
        d.err16CgmIsfTrendMinRsq1 = readDoubleLE(data, at: 1371)            // 1371
        d.err16CgmIsfTrendMinRsq2 = readDoubleLE(data, at: 1379)            // 1379
        d.err16CgmIsfTrendMinDiff = readDoubleLE(data, at: 1387)            // 1387
        d.err16CgmIsfTrendMinMaxTemp = readDoubleLE(data, at: 1395)         // 1395
        d.err16CgmIsfTrendMinMax = readDoubleLE(data, at: 1403)             // 1403
        d.err16CgmIsfTrendMinRatio = readDoubleLE(data, at: 1411)           // 1411
        d.err16CgmIsfTrendModeValue = readDoubleLE(data, at: 1419)          // 1419
        d.err16CgmIsfTrendModeProportion = readDoubleLE(data, at: 1427)     // 1427
        d.err16CgmIsfTrendModeDiff = readDoubleLE(data, at: 1435)           // 1435
        d.err16CgmIsfTrendModeMaxTemp = readDoubleLE(data, at: 1443)        // 1443
        d.err16CgmIsfTrendModeMax = readDoubleLE(data, at: 1451)            // 1451
        d.err16CgmIsfTrendModeRatio = readDoubleLE(data, at: 1459)          // 1459
        d.err16CgmIsfTrendMeanValue = readDoubleLE(data, at: 1467)          // 1467
        d.err16CgmIsfTrendMeanSlope = readDoubleLE(data, at: 1475)          // 1475
        d.err16CgmIsfTrendMeanRsq = readDoubleLE(data, at: 1483)            // 1483
        d.err16CgmIsfTrendMeanDiff = readDoubleLE(data, at: 1491)           // 1491
        d.err16CgmIsfTrendMeanMaxTemp = readDoubleLE(data, at: 1499)        // 1499
        d.err16CgmIsfTrendMeanMax = readDoubleLE(data, at: 1507)            // 1507
        d.err16CgmIsfTrendMeanRatio = readDoubleLE(data, at: 1515)          // 1515
        d.err16CgmIsfTrendMeanDiffEarly = readDoubleLE(data, at: 1523)      // 1523
        d.err16CgmIsfTrendMeanMaxTempEarly = readDoubleLE(data, at: 1531)   // 1531
        d.err16CgmIsfTrendMeanMaxEarly = readDoubleLE(data, at: 1539)       // 1539
        d.err16CgmIsfTrendMeanRatioEarly = readDoubleLE(data, at: 1547)     // 1547
        for i in 0..<7 {
            d.err16Condi[i] = Int(readUInt8(data, at: 1555 + i))            // 1555
        }

        // err128 fields
        d.err128Flag = Int(readUInt8(data, at: 1562))                       // 1562
        d.err128RevisedValue = readDoubleLE(data, at: 1563)                 // 1563
        d.err128Normal = readDoubleLE(data, at: 1571)                       // 1571

        // Verify we consumed exactly debugSize bytes
        // Last field: err128Normal at 1571, 8 bytes -> end = 1579 = debugSize
        let endOffset = 1571 + 8
        if endOffset != debugSize {
            throw OracleError.positionMismatch(expected: debugSize, actual: endOffset)
        }

        return d
    }

    // MARK: - cgm_input_t: 74 bytes, packed
    // Layout:
    //   uint16_t seq_number;               // 0
    //   uint32_t measurement_time_standard; // 2
    //   uint16_t workout[30];              // 6 (60 bytes)
    //   double temperature;                // 66
    //   TOTAL = 74

    static func readInput(from url: URL) throws -> CgmInput {
        let data = try loadData(from: url, expectedSize: inputSize)
        let input = CgmInput()

        input.seqNumber = Int(readUInt16LE(data, at: 0))                    // 0
        input.measurementTimeStandard = Int64(readUInt32LE(data, at: 2))    // 2
        for i in 0..<30 {                                                   // 6
            input.workout[i] = Int(readUInt16LE(data, at: 6 + i * 2))
        }
        input.temperature = readDoubleLE(data, at: 66)                      // 66

        return input
    }

    // MARK: - Raw byte access for direct offset-based comparison

    /// Returns the raw bytes of an output binary file for direct field comparison.
    /// Useful when you need to compare at specific byte offsets (like compare_oracle.c does).
    static func readOutputRaw(oracleDir: String, seq: Int) throws -> Data {
        let url = URL(fileURLWithPath: oracleDir)
            .appendingPathComponent("seq_\(String(format: "%04d", seq))_output.bin")
        let data = try Data(contentsOf: url)
        if data.count != outputSize {
            throw OracleError.sizeMismatch(expected: outputSize, actual: data.count, path: url.path)
        }
        return data
    }

    /// Returns the raw bytes of a debug binary file for direct field comparison.
    static func readDebugRaw(oracleDir: String, seq: Int) throws -> Data {
        let url = URL(fileURLWithPath: oracleDir)
            .appendingPathComponent("seq_\(String(format: "%04d", seq))_debug.bin")
        let data = try Data(contentsOf: url)
        if data.count != debugSize {
            throw OracleError.sizeMismatch(expected: debugSize, actual: data.count, path: url.path)
        }
        return data
    }

    /// Extracts a double from raw oracle bytes at the given offset.
    static func extractDouble(_ raw: Data, at offset: Int) -> Double {
        readDoubleLE(raw, at: offset)
    }

    /// Extracts a uint16 from raw oracle bytes at the given offset.
    static func extractUint16(_ raw: Data, at offset: Int) -> Int {
        Int(readUInt16LE(raw, at: offset))
    }

    /// Extracts a uint32 from raw oracle bytes at the given offset.
    static func extractUint32(_ raw: Data, at offset: Int) -> Int64 {
        Int64(readUInt32LE(raw, at: offset))
    }

    /// Extracts a uint8 from raw oracle bytes at the given offset.
    static func extractUint8(_ raw: Data, at offset: Int) -> Int {
        Int(readUInt8(raw, at: offset))
    }

    /// Extracts a int8 from raw oracle bytes at the given offset.
    static func extractInt8(_ raw: Data, at offset: Int) -> Int {
        Int(readInt8(raw, at: offset))
    }
}
