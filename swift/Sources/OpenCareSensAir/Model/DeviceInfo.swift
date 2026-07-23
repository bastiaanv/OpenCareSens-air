// DeviceInfo.swift
// Factory calibration parameters from sensor BLE advertisement (446 bytes packed in C).
// Maps to air1_opcal4_device_info_t.

/// Factory calibration parameters from sensor BLE advertisement.
public final class DeviceInfo {
    public var sensorVersion: Int = 0
    public var ycept: Float = 0.0
    public var slope100: Float = 0.0
    public var slope: Float = 0.0
    public var r2: Float = 0.0
    public var t90: Float = 0.0
    public var slopeRatio: Float = 0.0
    public var lot: String = ""
    public var sensorId: String = ""
    public var expiryDate: String = ""
    public var stabilizationInterval: Int = 0
    public var cgmDataInterval: Int = 0
    public var bleAdvInterval: Int = 0
    public var bleAdvDuration: Int = 0
    public var age: Int = 0
    public var allowedList: Int = 0
    public var maximumValue: Float = 0.0
    public var minimumValue: Float = 0.0
    public var cLibraryVersion: Int = 0
    public var parameterVersion: Int = 0
    public var basicWarmup: Int = 0
    public var basicYcept: Float = 0.0
    public var contactWinLen: Int = 0
    public var contactCond1X10: Int = 0
    public var contactCond2X10: Int = 0
    public var contactCond3X10: Int = 0
    public var fillFlag: Int = 0
    public var driftCorrectionOn: Int = 0
    public var driftCoefficient: [[Float]]
    public var iRefX100: Int = 0
    public var coefLength: Int = 0
    public var divPoint: Int = 0
    public var iirFlag: Int = 0
    public var iirStDX10: Int = 0
    public var correct1Flag: Int = 0
    public var correct1Coeff: [Float]
    public var kalmanT90: Int = 0
    public var kalmanDeltaT: Int = 0
    public var kalmanQX100: [[Int]]
    public var kalmanRX100: Int = 0
    public var bgCalRatio: Float = 0.0
    public var bgCalTimeFactor: Int = 0
    public var slopeFactorX10: Int = 0
    public var slopeInterUpX10: Int = 0
    public var slopeInterDownX10: Int = 0
    public var slopeMultiVX10: Int = 0
    public var slopeIirThr: Int = 0
    public var slopeNegInterThr1X10: Int = 0
    public var slopeNegInterThr2X10: Int = 0
    public var slopeBgCalThrDown: Int = 0
    public var slopeBgCalThrUp: Int = 0
    public var slopeMaxSlopeX100: Int = 0
    public var slopeMinSlopeX100: Int = 0
    public var slopeDcalRate: Float = 0.0
    public var slopeDcalTargetLength: Int = 0
    public var slopeDcalWindow: Int = 0
    public var slopeDcalFactoryCalUse: Int = 0
    public var shiftMSel: Int = 0
    public var shiftCoeff: [Float]
    public var shiftM2X100: [Int]
    public var wSgX100: [Int]
    public var calTrendRate: Int = 0
    public var calNoise: Float = 0.0
    public var errcodeVersion: Int = 0
    public var err1Seq: [Int]
    public var err1ContactBad: Float = 0.0
    public var err1ThDiff: Float = 0.0
    public var err1ThSseDmean: [Float]
    public var err1ThN1: [Int]
    public var err1ThN2: [[Int]]
    public var err1NConsecutive: Int = 0
    public var err1ISseDmeanNow: [Float]
    public var err1CountSseDmean: Int = 0
    public var err1NLast: Int = 0
    public var err1Multi: [Int]
    public var err1CurrentAvgDiff: Float = 0.0
    public var err2StartSeq: Int = 0
    public var err2Seq: [Int]
    public var err2Glu: Float = 0.0
    public var err2Cv: [Float]
    public var err2Cummax: Int = 0
    public var err2Multi: Int = 0
    public var err2Ycept: Float = 0.0
    public var err2Alpha: Float = 0.0
    public var err345Seq1: [Int]
    public var err345Seq2: Int = 0
    public var err345Seq3: [Int]
    public var err345Seq4: [Int]
    public var err345Seq5: [Int]
    public var err345Raw: [Float]
    public var err345Filtered: [Float]
    public var err345Min: [Float]
    public var err345Range: Float = 0.0
    public var err345NRange: Int = 0
    public var err345Md: Float = 0.0
    public var err345NMd: Int = 0
    public var err6CalNPts: Int = 0
    public var err6CalBasicPrct: Float = 0.0
    public var err6CalBasicSeq: Int = 0
    public var err6CalOriginSlope: Float = 0.0
    public var err6CalInVitro: [Float]
    public var err6CgmRpd: Float = 0.0
    public var err6CgmSlp: Float = 0.0
    public var err6CgmLow3dSeq: Int = 0
    public var err6CgmLow3dP: Float = 0.0
    public var err6CgmLow1dSeq: Int = 0
    public var err6CgmLow1dP: Float = 0.0
    public var err6CgmPrct: [Int]
    public var err6CgmDay: [Int]
    public var err6CgmBleBad: [Int]
    public var err6CgmPoly2: Float = 0.0
    public var err32Dt: [Int]
    public var err32N: [Int]
    public var vref: Float = 0.0
    public var eapp: Float = 0.0
    public var sensorStartTime: Int64 = 0

    public init() {
        driftCoefficient = Array(repeating: Array(repeating: 0.0, count: 3), count: 3)
        correct1Coeff = Array(repeating: 0.0, count: 4)
        kalmanQX100 = Array(repeating: Array(repeating: 0, count: 3), count: 3)
        shiftCoeff = Array(repeating: 0.0, count: 4)
        shiftM2X100 = Array(repeating: 0, count: 3)
        wSgX100 = Array(repeating: 0, count: 7)
        err1Seq = Array(repeating: 0, count: 3)
        err1ThSseDmean = Array(repeating: 0.0, count: 3)
        err1ThN1 = Array(repeating: 0, count: 4)
        err1ThN2 = Array(repeating: Array(repeating: 0, count: 2), count: 2)
        err1ISseDmeanNow = Array(repeating: 0.0, count: 2)
        err1Multi = Array(repeating: 0, count: 2)
        err2Seq = Array(repeating: 0, count: 3)
        err2Cv = Array(repeating: 0.0, count: 3)
        err345Seq1 = Array(repeating: 0, count: 2)
        err345Seq3 = Array(repeating: 0, count: 3)
        err345Seq4 = Array(repeating: 0, count: 5)
        err345Seq5 = Array(repeating: 0, count: 3)
        err345Raw = Array(repeating: 0.0, count: 4)
        err345Filtered = Array(repeating: 0.0, count: 2)
        err345Min = Array(repeating: 0.0, count: 2)
        err6CalInVitro = Array(repeating: 0.0, count: 2)
        err6CgmPrct = Array(repeating: 0, count: 3)
        err6CgmDay = Array(repeating: 0, count: 2)
        err6CgmBleBad = Array(repeating: 0, count: 2)
        err32Dt = Array(repeating: 0, count: 2)
        err32N = Array(repeating: 0, count: 2)
    }
}
