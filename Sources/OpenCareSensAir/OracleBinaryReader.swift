// MARK: - Oracle Binary Reader Constants

public enum OracleBinaryReader {
    
    public static let outputSize: Int32 = 155
    public static let debugSize: Int32 = 1579
    public static let inputSize: Int32 = 74
    public static let argsSize: Int32 = 117312
    
    // MARK: - File Loading
    
    /// Private helper to load a binary file and set up little-endian ByteBuffer.
    private static func loadFile(_ path: URL, expectedSize: Int32) throws -> Data {
        let data = try Data(contentsOf: path)
        guard data.count == Int(expectedSize) else {
            throw NSError(domain: "OracleBinaryReader", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Expected \(expectedSize) bytes but got \(data.count) for \(path.path)"
            ])
        }
        return data
    }
    
    // MARK: - Convenience Methods
    
    /// Read output binary from oracle directory by sequence number.
    /// - Parameters:
    ///   - oracleDir: directory containing oracle files
    ///   - seq: sequence number
    /// - Returns: AlgorithmOutput
    /// - Throws: IOException if file not found or invalid
    public static func readOutput(_ oracleDir: String, seq: Int32) throws -> AlgorithmOutput {
        let path = URL(fileURLWithPath: oracleDir, isDirectory: true)
        let filename = String(format: "seq_%04d_output.bin", seq)
        let url = path.appendingPathComponent(filename)
        return try readOutput(url)
    }
    
    /// Read debug binary from oracle directory by sequence number.
    /// - Parameters:
    ///   - oracleDir: directory containing oracle files
    ///   - seq: sequence number
    /// - Returns: DebugOutput
    /// - Throws: IOException if file not found or invalid
    public static func readDebug(_ oracleDir: String, seq: Int32) throws -> DebugOutput {
        let path = URL(fileURLWithPath: oracleDir, isDirectory: true)
        let filename = String(format: "seq_%04d_debug.bin", seq)
        let url = path.appendingPathComponent(filename)
        return try readDebug(url)
    }
    
    /// Read input binary from oracle directory by sequence number.
    /// - Parameters:
    ///   - oracleDir: directory containing oracle files
    ///   - seq: sequence number
    /// - Returns: CgmInput
    /// - Throws: IOException if file not found or invalid
    public static func readInput(_ oracleDir: String, seq: Int32) throws -> CgmInput {
        let path = URL(fileURLWithPath: oracleDir, isDirectory: true)
        let filename = String(format: "seq_%04d_input.bin", seq)
        let url = path.appendingPathComponent(filename)
        return try readInput(url)
    }
    
    // MARK: - output_t: 155 bytes, packed
    
    /// Read output binary file and parse into AlgorithmOutput.
    /// - Parameter url: URL to output binary file
    /// - Returns: AlgorithmOutput
    /// - Throws: IOException if file invalid
    public static func readOutput(_ url: URL) throws -> AlgorithmOutput {
        let data = try loadFile(url, expectedSize: outputSize)
        
        let output = AlgorithmOutput()
        
        // seq_number_original: uint16_t at offset 0
        output.seqNumberOriginal = extractUint16(data, offset: 0)
        
        // seq_number_final: uint16_t at offset 2
        output.seqNumberFinal = extractUint16(data, offset: 2)
        
        // measurement_time_standard: uint32_t at offset 4
        output.measurementTimeStandard = extractUint32(data, offset: 4)
        
        // workout[30]: uint16_t at offset 8 (60 bytes)
        for i in 0..<30 {
            output.workout[i] = extractUint16(data, offset: 8 + i*2)
        }
        
        // result_glucose: double at offset 68
        output.resultGlucose = extractDouble(data, offset: 68)
        
        // trendrate: double at offset 76
        output.trendrate = extractDouble(data, offset: 76)
        
        // current_stage: uint8_t at offset 84
        output.currentStage = extractUint8(data, offset: 84)
        
        // smooth_fixed_flag[6]: uint8_t at offset 85
        for i in 0..<6 {
            output.smoothFixedFlag[i] = extractUint8(data, offset: 85 + i)
        }
        
        // smooth_seq[6]: uint16_t at offset 91 (12 bytes)
        for i in 0..<6 {
            output.smoothSeq[i] = extractUint16(data, offset: 91 + i*2)
        }
        
        // smooth_result_glucose[6]: double at offset 103 (48 bytes)
        for i in 0..<6 {
            output.smoothResultGlucose[i] = extractDouble(data, offset: 103 + i*8)
        }
        
        // errcode: uint16_t at offset 151
        output.errcode = extractUint16(data, offset: 151)
        
        // cal_available_flag: uint8_t at offset 153
        output.calAvailableFlag = extractUint8(data, offset: 153)
        
        // data_type: uint8_t at offset 154
        output.dataType = extractUint8(data, offset: 154)
        
        return output
    }
    
    // MARK: - debug_t: 1579 bytes, packed
    
    /// Read debug binary file and parse into DebugOutput.
    /// - Parameter url: URL to debug binary file
    /// - Returns: DebugOutput
    /// - Throws: IOException if file invalid
    public static func readDebug(_ url: URL) throws -> DebugOutput {
        let data = try loadFile(url, expectedSize: debugSize)
        
        let debug = DebugOutput()
        
        // seq_number_original: uint16_t at offset 0
        debug.seqNumberOriginal = extractUint16(data, offset: 0)
        
        // seq_number_final: uint16_t at offset 2
        debug.seqNumberFinal = extractUint16(data, offset: 2)
        
        // measurement_time_standard: uint32_t at offset 4
        debug.measurementTimeStandard = extractUint32(data, offset: 4)
        
        // data_type: uint8_t at offset 8
        debug.dataType = extractUint8(data, offset: 8)
        
        // stage: uint8_t at offset 9
        debug.stage = extractUint8(data, offset: 9)
        
        // temperature: double at offset 10
        debug.temperature = extractDouble(data, offset: 10)
        
        // workout[30]: uint16_t at offset 18
        for i in 0..<30 {
            debug.workout[i] = extractUint16(data, offset: 18 + i*2)
        }
        
        // tranInA[30]: double at offset 78
        for i in 0..<30 {
            debug.tranInA[i] = extractDouble(data, offset: 78 + i*8)
        }
        
        // tranInA1min[5]: double at offset 318
        for i in 0..<5 {
            debug.tranInA1min[i] = extractDouble(data, offset: 318 + i*8)
        }
        
        // tranInA5min: double at offset 358
        debug.tranInA5min = extractDouble(data, offset: 358)
        
        // ycept: double at offset 366
        debug.ycept = extractDouble(data, offset: 366)
        
        // correctedReCurrent: double at offset 374
        debug.correctedReCurrent = extractDouble(data, offset: 374)
        
        // diabetesMeanX: double at offset 382
        debug.diabetesMeanX = extractDouble(data, offset: 382)
        
        // diabetesM2: double at offset 390
        debug.diabetesM2 = extractDouble(data, offset: 390)
        
        // diabetesTAR: double at offset 398
        debug.diabetesTAR = extractDouble(data, offset: 398)
        
        // diabetesTBR: double at offset 406
        debug.diabetesTBR = extractDouble(data, offset: 406)
        
        // diabetesCV: double at offset 414
        debug.diabetesCV = extractDouble(data, offset: 414)
        
        // levelDiabetes: uint8_t at offset 422
        debug.levelDiabetes = extractUint8(data, offset: 422)
        
        // outIir: double at offset 423
        debug.outIir = extractDouble(data, offset: 423)
        
        // outDrift: double at offset 431
        debug.outDrift = extractDouble(data, offset: 431)
        
        // currBaseline: double at offset 439
        debug.currBaseline = extractDouble(data, offset: 439)
        
        // initstableDiffDc: double at offset 447
        debug.initstableDiffDc = extractDouble(data, offset: 447)
        
        // initstableInitcnt: uint16_t at offset 455
        debug.initstableInitcnt = extractUint16(data, offset: 455)
        
        // tempLocalMean: double at offset 457
        debug.tempLocalMean = extractDouble(data, offset: 457)
        
        // slopeRatioTemp: double at offset 465
        debug.slopeRatioTemp = extractDouble(data, offset: 465)
        
        // initCg: double at offset 473
        debug.initCg = extractDouble(data, offset: 473)
        
        // outRescale: double at offset 481
        debug.outRescale = extractDouble(data, offset: 481)
        
        // opcalAd: double at offset 489
        debug.opcalAd = extractDouble(data, offset: 489)
        
        // stateInitKalman: uint8_t at offset 497
        debug.stateInitKalman = extractUint8(data, offset: 497)
        
        // smooth_seq[6]: uint16_t at offset 498
        for i in 0..<6 {
            debug.smoothSeq[i] = extractUint16(data, offset: 498 + i*2)
        }
        
        // smooth_sig[6]: double at offset 510
        for i in 0..<6 {
            debug.smoothSig[i] = extractDouble(data, offset: 510 + i*8)
        }
        
        // smooth_frep[6]: uint8_t at offset 558
        for i in 0..<6 {
            debug.smoothFrep[i] = extractUint8(data, offset: 558 + i)
        }
        
        // calState: uint8_t at offset 564
        debug.calState = extractUint8(data, offset: 564)
        
        // stateReturnOpcal: int8_t at offset 565 (signed)
        debug.stateReturnOpcal = extractInt8(data, offset: 565)
        
        // validBgTime: uint32_t at offset 566
        debug.validBgTime = extractUint32(data, offset: 566)
        
        // validBgValue: double at offset 570
        debug.validBgValue = extractDouble(data, offset: 570)
        
        // callogGroup: uint8_t at offset 578
        debug.callogGroup = extractUint8(data, offset: 578)
        
        // callogBgTime: uint32_t at offset 579
        debug.callogBgTime = extractUint32(data, offset: 579)
        
        // callogBgSeq: double at offset 583
        debug.callogBgSeq = extractDouble(data, offset: 583)
        
        // callogBgUser: double at offset 591
        debug.callogBgUser = extractDouble(data, offset: 591)
        
        // callogBgValid: int8_t at offset 599 (signed)
        debug.callogBgValid = extractInt8(data, offset: 599)
        
        // callogBgCal: double at offset 600
        debug.callogBgCal = extractDouble(data, offset: 600)
        
        // callogCgSeq1m: double at offset 608
        debug.callogCgSeq1m = extractDouble(data, offset: 608)
        
        // callogCgIdx: uint16_t at offset 616
        debug.callogCgIdx = extractUint16(data, offset: 616)
        
        // callogCgCal: double at offset 618
        debug.callogCgCal = extractDouble(data, offset: 618)
        
        // callogCslopePrev: double at offset 626
        debug.callogCslopePrev = extractDouble(data, offset: 626)
        
        // callogCyceptPrev: double at offset 634
        debug.callogCyceptPrev = extractDouble(data, offset: 634)
        
        // callogCslopeNew: double at offset 642
        debug.callogCslopeNew = extractDouble(data, offset: 642)
        
        // callogCyceptNew: double at offset 650
        debug.callogCyceptNew = extractDouble(data, offset: 650)
        
        // callogInlierFlg: uint8_t at offset 658
        debug.callogInlierFlg = extractUint8(data, offset: 658)
        
        // cal_slope[7]: double at offset 659
        for i in 0..<7 {
            debug.calSlope[i] = extractDouble(data, offset: 659 + i*8)
        }
        
        // cal_ycept[7]: double at offset 715
        for i in 0..<7 {
            debug.calYcept[i] = extractDouble(data, offset: 715 + i*8)
        }
        
        // cal_input[7]: double at offset 771
        for i in 0..<7 {
            debug.calInput[i] = extractDouble(data, offset: 771 + i*8)
        }
        
        // cal_output[7]: double at offset 827
        for i in 0..<7 {
            debug.calOutput[i] = extractDouble(data, offset: 827 + i*8)
        }
        
        // initstableWeightUsercal: double at offset 883
        debug.initstableWeightUsercal = extractDouble(data, offset: 883)
        
        // initstableWeightNocal: double at offset 891
        debug.initstableWeightNocal = extractDouble(data, offset: 891)
        
        // initstableFixusercal: double at offset 899
        debug.initstableFixusercal = extractDouble(data, offset: 899)
        
        // nOpcalState: int8_t at offset 907 (signed)
        debug.nOpcalState = extractInt8(data, offset: 907)
        
        // initstableInitEndPoint: uint16_t at offset 908
        debug.initstableInitEndPoint = extractUint16(data, offset: 908)
        
        // out_weight_sd[6]: double at offset 910
        for i in 0..<6 {
            debug.outWeightSd[i] = extractDouble(data, offset: 910 + i*8)
        }
        
        // outWeightAd: double at offset 958
        debug.outWeightAd = extractDouble(data, offset: 958)
        
        // shiftoutAd: double at offset 966
        debug.shiftoutAd = extractDouble(data, offset: 966)
        
        // errorCode1: uint8_t at offset 974
        debug.errorCode1 = extractUint8(data, offset: 974)
        
        // errorCode2: uint8_t at offset 975
        debug.errorCode2 = extractUint8(data, offset: 975)
        
        // errorCode4: uint8_t at offset 976
        debug.errorCode4 = extractUint8(data, offset: 976)
        
        // errorCode8: uint8_t at offset 977
        debug.errorCode8 = extractUint8(data, offset: 977)
        
        // errorCode16: uint8_t at offset 978
        debug.errorCode16 = extractUint8(data, offset: 978)
        
        // errorCode32: uint8_t at offset 979
        debug.errorCode32 = extractUint8(data, offset: 979)
        
        // trendrate: double at offset 980
        debug.trendrate = extractDouble(data, offset: 980)
        
        // calAvailableFlag: uint8_t at offset 988
        debug.calAvailableFlag = extractUint8(data, offset: 988)
        
        // err1ISseDMean: double at offset 989
        debug.err1ISseDMean = extractDouble(data, offset: 989)
        
        // err1ThSseDMean1: double at offset 997
        debug.err1ThSseDMean1 = extractDouble(data, offset: 997)
        
        // err1ThSseDMean2: double at offset 1005
        debug.err1ThSseDMean2 = extractDouble(data, offset: 1005)
        
        // err1ThSseDMean: double at offset 1013
        debug.err1ThSseDMean = extractDouble(data, offset: 1013)
        
        // err1IsContactBad: uint8_t at offset 1021
        debug.err1IsContactBad = extractUint8(data, offset: 1021)
        
        // err1CurrentAvgDiff: double at offset 1022
        debug.err1CurrentAvgDiff = extractDouble(data, offset: 1022)
        
        // err1ThDiff1: double at offset 1030
        debug.err1ThDiff1 = extractDouble(data, offset: 1030)
        
        // err1ThDiff2: double at offset 1038
        debug.err1ThDiff2 = extractDouble(data, offset: 1038)
        
        // err1ThDiff: double at offset 1046
        debug.err1ThDiff = extractDouble(data, offset: 1046)
        
        // err1Isfirst0: uint8_t at offset 1054
        debug.err1Isfirst0 = extractUint8(data, offset: 1054)
        
        // err1Isfirst1: uint8_t at offset 1055
        debug.err1Isfirst1 = extractUint8(data, offset: 1055)
        
        // err1Isfirst2: uint8_t at offset 1056
        debug.err1Isfirst2 = extractUint8(data, offset: 1056)
        
        // err1N: uint16_t at offset 1057
        debug.err1N = extractUint16(data, offset: 1057)
        
        // err1RandomNoiseTempBreak: uint8_t at offset 1059
        debug.err1RandomNoiseTempBreak = extractUint8(data, offset: 1059)
        
        // err1Result: uint8_t at offset 1060
        debug.err1Result = extractUint8(data, offset: 1060)
        
        // err1LengthT2Max: uint8_t at offset 1061
        debug.err1LengthT2Max = extractUint8(data, offset: 1061)
        
        // err1LengthT3Max: uint8_t at offset 1062
        debug.err1LengthT3Max = extractUint8(data, offset: 1062)
        
        // err1LengthT1Trio: uint8_t at offset 1063
        debug.err1LengthT1Trio = extractUint8(data, offset: 1063)
        
        // err1LengthT2Trio: uint8_t at offset 1064
        debug.err1LengthT2Trio = extractUint8(data, offset: 1064)
        
        // err1LengthT3Trio: uint8_t at offset 1065
        debug.err1LengthT3Trio = extractUint8(data, offset: 1065)
        
        // err1LengthT6Trio: uint8_t at offset 1066
        debug.err1LengthT6Trio = extractUint8(data, offset: 1066)
        
        // err1LengthT7Trio: uint8_t at offset 1067
        debug.err1LengthT7Trio = extractUint8(data, offset: 1067)
        
        // err1LengthT8Trio: uint8_t at offset 1068
        debug.err1LengthT8Trio = extractUint8(data, offset: 1068)
        
        // err1LengthT9Trio: uint8_t at offset 1069
        debug.err1LengthT9Trio = extractUint8(data, offset: 1069)
        
        // err1LengthT10Trio: uint8_t at offset 1070
        debug.err1LengthT10Trio = extractUint8(data, offset: 1070)
        
        // err1ResultTD: uint8_t at offset 1071
        debug.err1ResultTD = extractUint8(data, offset: 1071)
        
        // err1ResultConditionTD[2]: uint8_t at offset 1072
        debug.err1ResultConditionTD[0] = extractUint8(data, offset: 1072)
        debug.err1ResultConditionTD[1] = extractUint8(data, offset: 1073)
        
        // err1TDCount: uint16_t at offset 1074
        debug.err1TDCount = extractUint16(data, offset: 1074)
        
        // err1TDTemporaryBreakFlag: uint8_t at offset 1076
        debug.err1TDTemporaryBreakFlag = extractUint8(data, offset: 1076)
        
        // err1TDTimeTrio[3]: uint32_t at offset 1077
        debug.err1TDTimeTrio[0] = extractUint32(data, offset: 1077)
        debug.err1TDTimeTrio[1] = extractUint32(data, offset: 1081)
        debug.err1TDTimeTrio[2] = extractUint32(data, offset: 1085)
        
        // err1TDValueTrio[3]: double at offset 1089
        debug.err1TDValueTrio[0] = extractDouble(data, offset: 1089)
        debug.err1TDValueTrio[1] = extractDouble(data, offset: 1097)
        debug.err1TDValueTrio[2] = extractDouble(data, offset: 1105)
        
        // err2DelayRevisedValue: double at offset 1113
        debug.err2DelayRevisedValue = extractDouble(data, offset: 1113)
        
        // err2DelayRoc: double at offset 1121
        debug.err2DelayRoc = extractDouble(data, offset: 1121)
        
        // err2DelaySlopeSharp: double at offset 1129
        debug.err2DelaySlopeSharp = extractDouble(data, offset: 1129)
        
        // err2DelayRocCummax: double at offset 1137
        debug.err2DelayRocCummax = extractDouble(data, offset: 1137)
        
        // err2DelayRocTrimmedMean: double at offset 1145
        debug.err2DelayRocTrimmedMean = extractDouble(data, offset: 1145)
        
        // err2DelaySlopeCummax: double at offset 1153
        debug.err2DelaySlopeCummax = extractDouble(data, offset: 1153)
        
        // err2DelaySlopeTrimmedMean: double at offset 1161
        debug.err2DelaySlopeTrimmedMean = extractDouble(data, offset: 1161)
        
        // err2DelayGluCummax: double at offset 1169
        debug.err2DelayGluCummax = extractDouble(data, offset: 1169)
        
        // err2DelayGluTrimmedMean: double at offset 1177
        debug.err2DelayGluTrimmedMean = extractDouble(data, offset: 1177)
        
        // err2DelayPreCondi[3]: uint8_t at offset 1185
        debug.err2DelayPreCondi[0] = extractUint8(data, offset: 1185)
        debug.err2DelayPreCondi[1] = extractUint8(data, offset: 1186)
        debug.err2DelayPreCondi[2] = extractUint8(data, offset: 1187)
        
        // err2DelayCondi[3]: uint8_t at offset 1188
        debug.err2DelayCondi[0] = extractUint8(data, offset: 1188)
        debug.err2DelayCondi[1] = extractUint8(data, offset: 1189)
        debug.err2DelayCondi[2] = extractUint8(data, offset: 1190)
        
        // err2DelayFlag: uint8_t at offset 1191
        debug.err2DelayFlag = extractUint8(data, offset: 1191)
        
        // err2Cummax: double at offset 1192
        debug.err2Cummax = extractDouble(data, offset: 1192)
        
        // err2CrtCurrent[2]: uint8_t at offset 1200
        debug.err2CrtCurrent[0] = extractUint8(data, offset: 1200)
        debug.err2CrtCurrent[1] = extractUint8(data, offset: 1201)
        
        // err2CrtGlu[2]: uint8_t at offset 1202
        debug.err2CrtGlu[0] = extractUint8(data, offset: 1202)
        debug.err2CrtGlu[1] = extractUint8(data, offset: 1203)
        
        // err2CrtCv: double at offset 1204
        debug.err2CrtCv = extractDouble(data, offset: 1204)
        
        // err2Condi[2]: uint8_t at offset 1212
        debug.err2Condi[0] = extractUint8(data, offset: 1212)
        debug.err2Condi[1] = extractUint8(data, offset: 1213)
        
        // err4Min: double at offset 1214
        debug.err4Min = extractDouble(data, offset: 1214)
        
        // err4Range: double at offset 1222
        debug.err4Range = extractDouble(data, offset: 1222)
        
        // err4MinDiff: double at offset 1230
        debug.err4MinDiff = extractDouble(data, offset: 1230)
        
        // err4Condi[5]: uint8_t at offset 1238
        debug.err4Condi[0] = extractUint8(data, offset: 1238)
        debug.err4Condi[1] = extractUint8(data, offset: 1239)
        debug.err4Condi[2] = extractUint8(data, offset: 1240)
        debug.err4Condi[3] = extractUint8(data, offset: 1241)
        debug.err4Condi[4] = extractUint8(data, offset: 1242)
        
        // err4DelayCondi[5]: uint8_t at offset 1243
        debug.err4DelayCondi[0] = extractUint8(data, offset: 1243)
        debug.err4DelayCondi[1] = extractUint8(data, offset: 1244)
        debug.err4DelayCondi[2] = extractUint8(data, offset: 1245)
        debug.err4DelayCondi[3] = extractUint8(data, offset: 1246)
        debug.err4DelayCondi[4] = extractUint8(data, offset: 1247)
        
        // err4DelayFlag: uint8_t at offset 1248
        debug.err4DelayFlag = extractUint8(data, offset: 1248)
        
        // err8Condi[2]: uint8_t at offset 1249
        debug.err8Condi[0] = extractUint8(data, offset: 1249)
        debug.err8Condi[1] = extractUint8(data, offset: 1250)
        
        // err16CalConsDUsercalAfter: double at offset 1251
        debug.err16CalConsDUsercalAfter = extractDouble(data, offset: 1251)
        
        // err16CalDayDTemp: double at offset 1259
        debug.err16CalDayDTemp = extractDouble(data, offset: 1259)
        
        // err16CalDayDRef: double at offset 1267
        debug.err16CalDayDRef = extractDouble(data, offset: 1267)
        
        // err16CalDayNRef: double at offset 1275
        debug.err16CalDayNRef = extractDouble(data, offset: 1275)
        
        // err16CgmPlasma: double at offset 1283
        debug.err16CgmPlasma = extractDouble(data, offset: 1283)
        
        // err16CgmIsfSmooth: double at offset 1291
        debug.err16CgmIsfSmooth = extractDouble(data, offset: 1291)
        
        // err16CgmIsfRocValue: double at offset 1299
        debug.err16CgmIsfRocValue = extractDouble(data, offset: 1299)
        
        // err16CgmIsfRocSteady: double at offset 1307
        debug.err16CgmIsfRocSteady = extractDouble(data, offset: 1307)
        
        // err16CgmIsfRocMinTemp: double at offset 1315
        debug.err16CgmIsfRocMinTemp = extractDouble(data, offset: 1315)
        
        // err16CgmIsfRocMin: double at offset 1323
        debug.err16CgmIsfRocMin = extractDouble(data, offset: 1323)
        
        // err16CgmIsfRocDiff: double at offset 1331
        debug.err16CgmIsfRocDiff = extractDouble(data, offset: 1331)
        
        // err16CgmIsfRocRatio: double at offset 1339
        debug.err16CgmIsfRocRatio = extractDouble(data, offset: 1339)
        
        // err16CgmIsfTrendMinValue: double at offset 1347
        debug.err16CgmIsfTrendMinValue = extractDouble(data, offset: 1347)
        
        // err16CgmIsfTrendMinSlope1: double at offset 1355
        debug.err16CgmIsfTrendMinSlope1 = extractDouble(data, offset: 1355)
        
        // err16CgmIsfTrendMinSlope2: double at offset 1363
        debug.err16CgmIsfTrendMinSlope2 = extractDouble(data, offset: 1363)
        
        // err16CgmIsfTrendMinRsq1: double at offset 1371
        debug.err16CgmIsfTrendMinRsq1 = extractDouble(data, offset: 1371)
        
        // err16CgmIsfTrendMinRsq2: double at offset 1379
        debug.err16CgmIsfTrendMinRsq2 = extractDouble(data, offset: 1379)
        
        // err16CgmIsfTrendMinDiff: double at offset 1387
        debug.err16CgmIsfTrendMinDiff = extractDouble(data, offset: 1387)
        
        // err16CgmIsfTrendMinMaxTemp: double at offset 1395
        debug.err16CgmIsfTrendMinMaxTemp = extractDouble(data, offset: 1395)
        
        // err16CgmIsfTrendMinMax: double at offset 1403
        debug.err16CgmIsfTrendMinMax = extractDouble(data, offset: 1403)
        
        // err16CgmIsfTrendMinRatio: double at offset 1411
        debug.err16CgmIsfTrendMinRatio = extractDouble(data, offset: 1411)
        
        // err16CgmIsfTrendModeValue: double at offset 1419
        debug.err16CgmIsfTrendModeValue = extractDouble(data, offset: 1419)
        
        // err16CgmIsfTrendModeProportion: double at offset 1427
        debug.err16CgmIsfTrendModeProportion = extractDouble(data, offset: 1427)
        
        // err16CgmIsfTrendModeDiff: double at offset 1435
        debug.err16CgmIsfTrendModeDiff = extractDouble(data, offset: 1435)
        
        // err16CgmIsfTrendModeMaxTemp: double at offset 1443
        debug.err16CgmIsfTrendModeMaxTemp = extractDouble(data, offset: 1443)
        
        // err16CgmIsfTrendModeMax: double at offset 1451
        debug.err16CgmIsfTrendModeMax = extractDouble(data, offset: 1451)
        
        // err16CgmIsfTrendModeRatio: double at offset 1459
        debug.err16CgmIsfTrendModeRatio = extractDouble(data, offset: 1459)
        
        // err16CgmIsfTrendMeanValue: double at offset 1467
        debug.err16CgmIsfTrendMeanValue = extractDouble(data, offset: 1467)
        
        // err16CgmIsfTrendMeanSlope: double at offset 1475
        debug.err16CgmIsfTrendMeanSlope = extractDouble(data, offset: 1475)
        
        // err16CgmIsfTrendMeanRsq: double at offset 1483
        debug.err16CgmIsfTrendMeanRsq = extractDouble(data, offset: 1483)
        
        // err16CgmIsfTrendMeanDiff: double at offset 1491
        debug.err16CgmIsfTrendMeanDiff = extractDouble(data, offset: 1491)
        
        // err16CgmIsfTrendMeanMaxTemp: double at offset 1499
        debug.err16CgmIsfTrendMeanMaxTemp = extractDouble(data, offset: 1499)
        
        // err16CgmIsfTrendMeanMax: double at offset 1507
        debug.err16CgmIsfTrendMeanMax = extractDouble(data, offset: 1507)
        
        // err16CgmIsfTrendMeanRatio: double at offset 1515
        debug.err16CgmIsfTrendMeanRatio = extractDouble(data, offset: 1515)
        
        // err16CgmIsfTrendMeanDiffEarly: double at offset 1523
        debug.err16CgmIsfTrendMeanDiffEarly = extractDouble(data, offset: 1523)
        
        // err16CgmIsfTrendMeanMaxTempEarly: double at offset 1531
        debug.err16CgmIsfTrendMeanMaxTempEarly = extractDouble(data, offset: 1531)
        
        // err16CgmIsfTrendMeanMaxEarly: double at offset 1539
        debug.err16CgmIsfTrendMeanMaxEarly = extractDouble(data, offset: 1539)
        
        // err16CgmIsfTrendMeanRatioEarly: double at offset 1547
        debug.err16CgmIsfTrendMeanRatioEarly = extractDouble(data, offset: 1547)
        
        // err16Condi[7]: uint8_t at offset 1548
        debug.err16Condi[0] = extractUint8(data, offset: 1548)
        debug.err16Condi[1] = extractUint8(data, offset: 1549)
        debug.err16Condi[2] = extractUint8(data, offset: 1550)
        debug.err16Condi[3] = extractUint8(data, offset: 1551)
        debug.err16Condi[4] = extractUint8(data, offset: 1552)
        debug.err16Condi[5] = extractUint8(data, offset: 1553)
        debug.err16Condi[6] = extractUint8(data, offset: 1554)
        
        // err128Flag: uint8_t at offset 1555
        debug.err128Flag = extractUint8(data, offset: 1555)
        
        // err128RevisedValue: double at offset 1556
        debug.err128RevisedValue = extractDouble(data, offset: 1556)
        
        // err128Normal: double at offset 1564
        debug.err128Normal = extractDouble(data, offset: 1564)
        
        // Verify we consumed exactly DEBUG_SIZE bytes
        guard data.count == Int(debugSize) else {
            throw NSError(domain: "OracleBinaryReader", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Debug binary read position mismatch: expected \(Int(debugSize)) but got \(data.count)"
            ])
        }
        
        return debug
    }
    
    // MARK: - cgm_input_t: 74 bytes, packed
    
    /// Read input binary file and parse into CgmInput.
    /// - Parameter url: URL to input binary file
    /// - Returns: CgmInput
    /// - Throws: IOException if file invalid
    public static func readInput(_ url: URL) throws -> CgmInput {
        let data = try loadFile(url, expectedSize: inputSize)
        
        let input = CgmInput()
        
        // seq_number: uint16_t at offset 0
        input.seqNumber = extractUint16(data, offset: 0)
        
        // measurement_time_standard: uint32_t at offset 2
        input.measurementTimeStandard = extractUint32(data, offset: 2)
        
        // workout[30]: uint16_t at offset 6 (60 bytes)
        for i in 0..<30 {
            input.workout[i] = extractUint16(data, offset: 6 + i*2)
        }
        
        // temperature: double at offset 66
        input.temperature = extractDouble(data, offset: 66)
        
        return input
    }
    
    // MARK: - Raw Byte Access
    
    /// Returns the raw bytes of an output binary file for direct field comparison.
    /// - Parameters:
    ///   - oracleDir: directory containing oracle files
    ///   - seq: sequence number
    /// - Returns: raw bytes of output binary
    /// - Throws: IOException if file invalid
    public static func readOutputRaw(_ oracleDir: String, seq: Int32) throws -> Data {
        let path = URL(fileURLWithPath: oracleDir, isDirectory: true)
        let filename = String(format: "seq_%04d_output.bin", seq)
        let url = path.appendingPathComponent(filename)
        
        let data = try Data(contentsOf: url)
        guard data.count == Int(outputSize) else {
            throw NSError(domain: "OracleBinaryReader", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Expected \(Int(outputSize)) bytes but got \(data.count) for output binary"
            ])
        }
        return data
    }
    
    /// Returns the raw bytes of a debug binary file for direct field comparison.
    /// - Parameters:
    ///   - oracleDir: directory containing oracle files
    ///   - seq: sequence number
    /// - Returns: raw bytes of debug binary
    /// - Throws: IOException if file invalid
    public static func readDebugRaw(_ oracleDir: String, seq: Int32) throws -> Data {
        let path = URL(fileURLWithPath: oracleDir, isDirectory: true)
        let filename = String(format: "seq_%04d_debug.bin", seq)
        let url = path.appendingPathComponent(filename)
        
        let data = try Data(contentsOf: url)
        guard data.count == Int(debugSize) else {
            throw NSError(domain: "OracleBinaryReader", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "Expected \(Int(debugSize)) bytes but got \(data.count) for debug binary"
            ])
        }
        return data
    }
    
    /// Extracts a double from raw oracle bytes at the given offset.
    /// - Parameters:
    ///   - raw: raw byte array
    ///   - offset: byte offset
    /// - Returns: double value
    public static func extractDouble(_ raw: Data, offset: Int) -> Double {
        guard offset + 8 <= raw.count else {
            fatalError("Offset \(offset) + 8 exceeds data length \(raw.count)")
        }
        var buffer = [UInt8](repeating: 0, count: 8)
        raw.copyBytes(to: &buffer, count: 8, at: offset)
        
        return Double(bitPattern: UInt64(buffer[0]) | UInt64(buffer[1]) << 8 | UInt64(buffer[2]) << 16 | UInt64(buffer[3]) << 24 | UInt64(buffer[4]) << 32 | UInt64(buffer[5]) << 40 | UInt64(buffer[6]) << 48 | UInt64(buffer[7]) << 56)
    }
    
    /// Extracts a uint16 from raw oracle bytes at the given offset.
    /// - Parameters:
    ///   - raw: raw byte array
    ///   - offset: byte offset
    /// - Returns: unsigned 16-bit integer
    public static func extractUint16(_ raw: Data, offset: Int) -> Int {
        guard offset + 2 <= raw.count else {
            fatalError("Offset \(offset) + 2 exceeds data length \(raw.count)")
        }
        return Int(raw[offset]) | (Int(raw[offset + 1]) << 8)
    }
    
    /// Extracts a uint32 from raw oracle bytes at the given offset.
    /// - Parameters:
    ///   - raw: raw byte array
    ///   - offset: byte offset
    /// - Returns: unsigned 32-bit integer
    public static func extractUint32(_ raw: Data, offset: Int) -> Int64 {
        guard offset + 4 <= raw.count else {
            fatalError("Offset \(offset) + 4 exceeds data length \(raw.count)")
        }
        return Int64(raw[offset]) | Int64(raw[offset + 1]) << 8 | Int64(raw[offset + 2]) << 16 | Int64(raw[offset + 3]) << 24
    }
    
    /// Extracts a uint8 from raw oracle bytes at the given offset.
    /// - Parameters:
    ///   - raw: raw byte array
    ///   - offset: byte offset
    /// - Returns: unsigned 8-bit integer
    public static func extractUint8(_ raw: Data, offset: Int) -> Int {
        guard offset < raw.count else {
            fatalError("Offset \(offset) exceeds data length \(raw.count)")
        }
        return Int(raw[offset])
    }
    
    /// Extracts a int8 from raw oracle bytes at the given offset.
    /// - Parameters:
    ///   - raw: raw byte array
    ///   - offset: byte offset
    /// - Returns: signed 8-bit integer
    public static func extractInt8(_ raw: Data, offset: Int) -> Int8 {
        guard offset < raw.count else {
            fatalError("Offset \(offset) exceeds data length \(raw.count)")
        }
        return Int8(raw[offset])
    }
}
