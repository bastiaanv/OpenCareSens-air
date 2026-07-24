//
//  SensorConfig.swift
//  OpenCareSensAir
//
//  Factory calibration parameters for a CareSens Air CGM sensor.
//

import Foundation

// MARK: - DeviceInfo

/// Factory calibration parameters from sensor BLE advertisement (446 bytes packed in C).
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
        self.driftCoefficient = Array(repeating: Array(repeating: 0, count: 3), count: 3)
        self.iRefX100 = 0
        self.coefLength = 0
        self.divPoint = 0
        self.iirFlag = 0
        self.iirStDX10 = 0
        self.correct1Flag = 0
        self.correct1Coeff = Array(repeating: 0, count: 4)
        self.kalmanT90 = 0
        self.kalmanDeltaT = 0
        self.kalmanQX100 = Array(repeating: Array(repeating: 0, count: 3), count: 3)
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
        self.shiftCoeff = Array(repeating: 0, count: 4)
        self.shiftM2X100 = Array(repeating: 0, count: 3)
        self.wSgX100 = Array(repeating: 0, count: 7)
        self.calTrendRate = 0
        self.calNoise = 0
        self.errcodeVersion = 0
        self.err1Seq = Array(repeating: 0, count: 3)
        self.err1ContactBad = 0
        self.err1ThDiff = 0
        self.err1ThSseDmean = Array(repeating: 0, count: 3)
        self.err1ThN1 = Array(repeating: 0, count: 4)
        self.err1ThN2 = Array(repeating: Array(repeating: 0, count: 2), count: 2)
        self.err1NConsecutive = 0
        self.err1ISseDmeanNow = Array(repeating: 0, count: 2)
        self.err1CountSseDmean = 0
        self.err1NLast = 0
        self.err1Multi = Array(repeating: 0, count: 2)
        self.err1CurrentAvgDiff = 0
        self.err2StartSeq = 0
        self.err2Seq = Array(repeating: 0, count: 3)
        self.err2Glu = 0
        self.err2Cv = Array(repeating: 0, count: 3)
        self.err2Cummax = 0
        self.err2Multi = 0
        self.err2Ycept = 0
        self.err2Alpha = 0
        self.err345Seq1 = Array(repeating: 0, count: 2)
        self.err345Seq2 = 0
        self.err345Seq3 = Array(repeating: 0, count: 3)
        self.err345Seq4 = Array(repeating: 0, count: 5)
        self.err345Seq5 = Array(repeating: 0, count: 3)
        self.err345Raw = Array(repeating: 0, count: 4)
        self.err345Filtered = Array(repeating: 0, count: 2)
        self.err345Min = Array(repeating: 0, count: 2)
        self.err345Range = 0
        self.err345NRange = 0
        self.err345Md = 0
        self.err345NMd = 0
        self.err6CalNPts = 0
        self.err6CalBasicPrct = 0
        self.err6CalBasicSeq = 0
        self.err6CalOriginSlope = 0
        self.err6CalInVitro = Array(repeating: 0, count: 2)
        self.err6CgmRpd = 0
        self.err6CgmSlp = 0
        self.err6CgmLow3dSeq = 0
        self.err6CgmLow3dP = 0
        self.err6CgmLow1dSeq = 0
        self.err6CgmLow1dP = 0
        self.err6CgmPrct = Array(repeating: 0, count: 3)
        self.err6CgmDay = Array(repeating: 0, count: 2)
        self.err6CgmBleBad = Array(repeating: 0, count: 2)
        self.err6CgmPoly2 = 0
        self.err32Dt = Array(repeating: 0, count: 2)
        self.err32N = Array(repeating: 0, count: 2)
        self.vref = 0
        self.eapp = 0
        self.sensorStartTime = 0
    }
}

// MARK: - SensorConfig

/// Factory calibration parameters for a CareSens Air CGM sensor.
///
/// These values originate from the sensor's BLE advertisement data and
/// encode the factory calibration performed during manufacturing. They are
/// immutable once constructed.
///
/// Use the `Builder` for construction:
/// ```
/// let config = SensorConfig.Builder()
///     .eapp(0.10067)
///     .vref(1.2)
///     .slope100(2.5)
///     .sensorStartTime(Int64(Date.timeIntervalSinceReferenceDate * 1000))
///     .basicWarmup(5)
///     .err345Seq2(5)
///     .build()
/// ```
public struct SensorConfig: Codable {
    
    public let deviceInfo: DeviceInfo
    
    private init(deviceInfo: DeviceInfo) {
        self.deviceInfo = deviceInfo
    }
    
    // ======================================================================
    // Primary getters — the values most integrators need
    // ======================================================================
    
    /// Electrochemical apparent potential (V). Determines lot type.
    public var eapp: Float {
        return deviceInfo.eapp
    }
    
    /// Reference voltage (V).
    public var vref: Float {
        return deviceInfo.vref
    }
    
    /// Slope calibration factor (x100).
    public var slope100: Float {
        return deviceInfo.slope100
    }
    
    /// Slope calibration factor.
    public var slope: Float {
        return deviceInfo.slope
    }
    
    /// Y-intercept from factory calibration.
    public var ycept: Float {
        return deviceInfo.ycept
    }
    
    /// Sensor lot identifier.
    public var lot: String {
        return deviceInfo.lot
    }
    
    /// Unique sensor identifier.
    public var sensorId: String {
        return deviceInfo.sensorId
    }
    
    /// Sensor start time (Unix seconds).
    public var sensorStartTime: Int64 {
        return deviceInfo.sensorStartTime
    }
    
    /// Number of warmup readings before glucose is reliable.
    public var basicWarmup: Int {
        return deviceInfo.basicWarmup
    }
    
    /// Sequence number threshold for warmup/steady-state transition.
    public var err345Seq2: Int {
        return deviceInfo.err345Seq2
    }
    
    // ======================================================================
    // Package-private access to the internal DeviceInfo
    // ======================================================================
    
    func toDeviceInfo() -> DeviceInfo {
        return deviceInfo
    }
}

// MARK: - Builder

/// Builder for constructing a `SensorConfig` from individual fields.
///
/// At minimum, `eapp`, `vref`, and `slope100` must be set. All other fields have safe defaults.
public final class Builder {
    
    private var di: DeviceInfo
    
    public init() {
        self.di = DeviceInfo()
    }
    
    // MARK: - Required Fields
    
    /// Electrochemical apparent potential (V). Required.
    public func eapp(_ eapp: Float) -> Self {
        di.eapp = eapp
        return self
    }
    
    /// Reference voltage (V). Required.
    public func vref(_ vref: Float) -> Self {
        di.vref = vref
        return self
    }
    
    /// Slope calibration factor (x100). Required.
    public func slope100(_ slope100: Float) -> Self {
        di.slope100 = slope100
        return self
    }
    
    // MARK: - Optional Float Fields
    
    /// Slope calibration factor.
    public func slope(_ slope: Float) -> Self {
        di.slope = slope
        return self
    }
    
    /// Y-intercept from factory calibration.
    public func ycept(_ ycept: Float) -> Self {
        di.ycept = ycept
        return self
    }
    
    /// R-squared from factory calibration.
    public func r2(_ r2: Float) -> Self {
        di.r2 = r2
        return self
    }
    
    /// T90 response time (minutes).
    public func t90(_ t90: Float) -> Self {
        di.t90 = t90
        return self
    }
    
    /// Slope ratio.
    public func slopeRatio(_ slopeRatio: Float) -> Self {
        di.slopeRatio = slopeRatio
        return self
    }
    
    /// Sensor expiry date string.
    public func expiryDate(_ expiryDate: String) -> Self {
        di.expiryDate = expiryDate
        return self
    }
    
    /// Sensor version.
    public func sensorVersion(_ sensorVersion: Int) -> Self {
        di.sensorVersion = sensorVersion
        return self
    }
    
    /// Maximum glucose value (mg/dL).
    public func maximumValue(_ maximumValue: Float) -> Self {
        di.maximumValue = maximumValue
        return self
    }
    
    /// Minimum glucose value (mg/dL).
    public func minimumValue(_ minimumValue: Float) -> Self {
        di.minimumValue = minimumValue
        return self
    }
    
    /// Basic Y-intercept.
    public func basicYcept(_ basicYcept: Float) -> Self {
        di.basicYcept = basicYcept
        return self
    }
    
    /// IIR filter flag (0=disabled, 1=enabled).
    public func iirFlag(_ iirFlag: Int) -> Self {
        di.iirFlag = iirFlag
        return self
    }
    
    /// Error 2 glucose threshold.
    public func err2Glu(_ err2Glu: Float) -> Self {
        di.err2Glu = err2Glu
        return self
    }
    
    /// Error 3/4/5 sequence thresholds (array of 5).
    public func err345Seq4(_ err345Seq4: [Int]) -> Self {
        for i in 0..<Swift.min(err345Seq4.count, 5) {
            di.err345Seq4[i] = err345Seq4[i]
        }
        return self
    }
    
    /// Error 32 delta-time thresholds.
    public func err32Dt(_ err32Dt: [Int]) -> Self {
        for i in 0..<Swift.min(err32Dt.count, 2) {
            di.err32Dt[i] = err32Dt[i]
        }
        return self
    }
    
    /// Error 32 count thresholds.
    public func err32N(_ err32N: [Int]) -> Self {
        for i in 0..<Swift.min(err32N.count, 2) {
            di.err32N[i] = err32N[i]
        }
        return self
    }
    
    /// Kalman delta-T.
    public func kalmanDeltaT(_ kalmanDeltaT: Int) -> Self {
        di.kalmanDeltaT = kalmanDeltaT
        return self
    }
    
    /// Savitzky-Golay filter weights (7 elements, x100).
    public func wSgX100(_ wSgX100: [Int]) -> Self {
        for i in 0..<Swift.min(wSgX100.count, 7) {
            di.wSgX100[i] = wSgX100[i]
        }
        return self
    }
    
    /// Error detection sequence thresholds.
    public func err1Seq(_ err1Seq: [Int]) -> Self {
        for i in 0..<Swift.min(err1Seq.count, 3) {
            di.err1Seq[i] = err1Seq[i]
        }
        return self
    }
    
    /// Error detection multiplier.
    public func err1Multi(_ err1Multi: [Int]) -> Self {
        for i in 0..<Swift.min(err1Multi.count, 2) {
            di.err1Multi[i] = err1Multi[i]
        }
        return self
    }
    
    /// Error 2 sequence thresholds.
    public func err2Seq(_ err2Seq: [Int]) -> Self {
        for i in 0..<Swift.min(err2Seq.count, 3) {
            di.err2Seq[i] = err2Seq[i]
        }
        return self
    }
    
    /// Error 3/4/5 sequence thresholds (array of 5).
    public func err345Seq4Full(_ err345Seq4: [Int]) -> Self {
        for i in 0..<Swift.min(err345Seq4.count, 5) {
            di.err345Seq4[i] = err345Seq4[i]
        }
        return self
    }
    
    // MARK: - Optional Int Fields
    
    /// Sensor lot identifier.
    public func lot(_ lot: String) -> Self {
        di.lot = lot
        return self
    }
    
    /// Unique sensor identifier.
    public func sensorId(_ sensorId: String) -> Self {
        di.sensorId = sensorId
        return self
    }
    
    /// Sensor start time (Unix seconds).
    public func sensorStartTime(_ sensorStartTime: Int64) -> Self {
        di.sensorStartTime = sensorStartTime
        return self
    }
    
    /// Number of warmup readings.
    public func basicWarmup(_ basicWarmup: Int) -> Self {
        di.basicWarmup = basicWarmup
        return self
    }
    
    /// Warmup/steady-state transition sequence number.
    public func err345Seq2(_ err345Seq2: Int) -> Self {
        di.err345Seq2 = err345Seq2
        return self
    }
    
    /// Error 2 start sequence.
    public func err2StartSeq(_ err2StartSeq: Int) -> Self {
        di.err2StartSeq = err2StartSeq
        return self
    }
    
    /// Error 2 cummax.
    public func err2Cummax(_ err2Cummax: Int) -> Self {
        di.err2Cummax = err2Cummax
        return self
    }
    
    /// Error 2 multi.
    public func err2Multi(_ err2Multi: Int) -> Self {
        di.err2Multi = err2Multi
        return self
    }
    
    /// Error 2 ycept.
    public func err2Ycept(_ err2Ycept: Float) -> Self {
        di.err2Ycept = err2Ycept
        return self
    }
    
    /// Error 2 alpha.
    public func err2Alpha(_ err2Alpha: Float) -> Self {
        di.err2Alpha = err2Alpha
        return self
    }
    
    /// Error 345 seq1.
    public func err345Seq1(_ err345Seq1: [Int]) -> Self {
        for i in 0..<Swift.min(err345Seq1.count, 2) {
            di.err345Seq1[i] = err345Seq1[i]
        }
        return self
    }
    
    /// Error 345 seq3.
    public func err345Seq3(_ err345Seq3: [Int]) -> Self {
        for i in 0..<Swift.min(err345Seq3.count, 3) {
            di.err345Seq3[i] = err345Seq3[i]
        }
        return self
    }
    
    /// Error 345 seq5.
    public func err345Seq5(_ err345Seq5: [Int]) -> Self {
        for i in 0..<Swift.min(err345Seq5.count, 3) {
            di.err345Seq5[i] = err345Seq5[i]
        }
        return self
    }
    
    /// Error 345 raw.
    public func err345Raw(_ err345Raw: [Float]) -> Self {
        for i in 0..<Swift.min(err345Raw.count, 4) {
            di.err345Raw[i] = err345Raw[i]
        }
        return self
    }
    
    /// Error 345 filtered.
    public func err345Filtered(_ err345Filtered: [Float]) -> Self {
        for i in 0..<Swift.min(err345Filtered.count, 2) {
            di.err345Filtered[i] = err345Filtered[i]
        }
        return self
    }
    
    /// Error 345 min.
    public func err345Min(_ err345Min: [Float]) -> Self {
        for i in 0..<Swift.min(err345Min.count, 2) {
            di.err345Min[i] = err345Min[i]
        }
        return self
    }
    
    /// Error 345 range.
    public func err345Range(_ err345Range: Float) -> Self {
        di.err345Range = err345Range
        return self
    }
    
    /// Error 345 nrange.
    public func err345NRange(_ err345NRange: Int) -> Self {
        di.err345NRange = err345NRange
        return self
    }
    
    /// Error 345 md.
    public func err345Md(_ err345Md: Float) -> Self {
        di.err345Md = err345Md
        return self
    }
    
    /// Error 345 nmd.
    public func err345NMd(_ err345NMd: Int) -> Self {
        di.err345NMd = err345NMd
        return self
    }
    
    /// Error 6 cal npts.
    public func err6CalNPts(_ err6CalNPts: Int) -> Self {
        di.err6CalNPts = err6CalNPts
        return self
    }
    
    /// Error 6 cal basic prct.
    public func err6CalBasicPrct(_ err6CalBasicPrct: Float) -> Self {
        di.err6CalBasicPrct = err6CalBasicPrct
        return self
    }
    
    /// Error 6 cal basic seq.
    public func err6CalBasicSeq(_ err6CalBasicSeq: Int) -> Self {
        di.err6CalBasicSeq = err6CalBasicSeq
        return self
    }
    
    /// Error 6 cal origin slope.
    public func err6CalOriginSlope(_ err6CalOriginSlope: Float) -> Self {
        di.err6CalOriginSlope = err6CalOriginSlope
        return self
    }
    
    /// Error 6 cal in vitro.
    public func err6CalInVitro(_ err6CalInVitro: [Float]) -> Self {
        for i in 0..<Swift.min(err6CalInVitro.count, 2) {
            di.err6CalInVitro[i] = err6CalInVitro[i]
        }
        return self
    }
    
    /// Error 6 cgm rpd.
    public func err6CgmRpd(_ err6CgmRpd: Float) -> Self {
        di.err6CgmRpd = err6CgmRpd
        return self
    }
    
    /// Error 6 cgm slp.
    public func err6CgmSlp(_ err6CgmSlp: Float) -> Self {
        di.err6CgmSlp = err6CgmSlp
        return self
    }
    
    /// Error 6 cgm low 3d seq.
    public func err6CgmLow3dSeq(_ err6CgmLow3dSeq: Int) -> Self {
        di.err6CgmLow3dSeq = err6CgmLow3dSeq
        return self
    }
    
    /// Error 6 cgm low 3d p.
    public func err6CgmLow3dP(_ err6CgmLow3dP: Float) -> Self {
        di.err6CgmLow3dP = err6CgmLow3dP
        return self
    }
    
    /// Error 6 cgm low 1d seq.
    public func err6CgmLow1dSeq(_ err6CgmLow1dSeq: Int) -> Self {
        di.err6CgmLow1dSeq = err6CgmLow1dSeq
        return self
    }
    
    /// Error 6 cgm low 1d p.
    public func err6CgmLow1dP(_ err6CgmLow1dP: Float) -> Self {
        di.err6CgmLow1dP = err6CgmLow1dP
        return self
    }
    
    /// Error 6 cgm prct.
    public func err6CgmPrct(_ err6CgmPrct: [Int]) -> Self {
        for i in 0..<Swift.min(err6CgmPrct.count, 3) {
            di.err6CgmPrct[i] = err6CgmPrct[i]
        }
        return self
    }
    
    /// Error 6 cgm day.
    public func err6CgmDay(_ err6CgmDay: [Int]) -> Self {
        for i in 0..<Swift.min(err6CgmDay.count, 2) {
            di.err6CgmDay[i] = err6CgmDay[i]
        }
        return self
    }
    
    /// Error 6 cgm ble bad.
    public func err6CgmBleBad(_ err6CgmBleBad: [Int]) -> Self {
        for i in 0..<Swift.min(err6CgmBleBad.count, 2) {
            di.err6CgmBleBad[i] = err6CgmBleBad[i]
        }
        return self
    }
    
    /// Error 6 cgm poly2.
    public func err6CgmPoly2(_ err6CgmPoly2: Float) -> Self {
        di.err6CgmPoly2 = err6CgmPoly2
        return self
    }
    
    /// Error 1 seq.
    public func err1Seq(_ err1Seq: [Int]) -> Self {
        for i in 0..<Swift.min(err1Seq.count, 3) {
            di.err1Seq[i] = err1Seq[i]
        }
        return self
    }
    
    /// Error 1 contact bad.
    public func err1ContactBad(_ err1ContactBad: Float) -> Self {
        di.err1ContactBad = err1ContactBad
        return self
    }
    
    /// Error 1 th diff.
    public func err1ThDiff(_ err1ThDiff: Float) -> Self {
        di.err1ThDiff = err1ThDiff
        return self
    }
    
    /// Error 1 th sse dmean.
    public func err1ThSseDmean(_ err1ThSseDmean: [Float]) -> Self {
        for i in 0..<Swift.min(err1ThSseDmean.count, 3) {
            di.err1ThSseDmean[i] = err1ThSseDmean[i]
        }
        return self
    }
    
    /// Error 1 th n1.
    public func err1ThN1(_ err1ThN1: [Int]) -> Self {
        for i in 0..<Swift.min(err1ThN1.count, 4) {
            di.err1ThN1[i] = err1ThN1[i]
        }
        return self
    }
    
    /// Error 1 th n2.
    public func err1ThN2(_ err1ThN2: [[Int]]) -> Self {
        for i in 0..<Swift.min(err1ThN2.count, 2) {
            for j in 0..<Swift.min(err1ThN2[i].count, 2) {
                di.err1ThN2[i][j] = err1ThN2[i][j]
            }
        }
        return self
    }
    
    /// Error 1 n consecutive.
    public func err1NConsecutive(_ err1NConsecutive: Int) -> Self {
        di.err1NConsecutive = err1NConsecutive
        return self
    }
    
    /// Error 1 isse dmean now.
    public func err1ISseDmeanNow(_ err1ISseDmeanNow: [Float]) -> Self {
        for i in 0..<Swift.min(err1ISseDmeanNow.count, 2) {
            di.err1ISseDmeanNow[i] = err1ISseDmeanNow[i]
        }
        return self
    }
    
    /// Error 1 count sse dmean.
    public func err1CountSseDmean(_ err1CountSseDmean: Int) -> Self {
        di.err1CountSseDmean = err1CountSseDmean
        return self
    }
    
    /// Error 1 n last.
    public func err1NLast(_ err1NLast: Int) -> Self {
        di.err1NLast = err1NLast
        return self
    }
    
    /// Error 1 current avg diff.
    public func err1CurrentAvgDiff(_ err1CurrentAvgDiff: Float) -> Self {
        di.err1CurrentAvgDiff = err1CurrentAvgDiff
        return self
    }
    
    /// Error 2 cv.
    public func err2Cv(_ err2Cv: [Float]) -> Self {
        for i in 0..<Swift.min(err2Cv.count, 3) {
            di.err2Cv[i] = err2Cv[i]
        }
        return self
    }
    
    /// Error 345 seq1.
    public func err345Seq1(_ err345Seq1: [Int]) -> Self {
        for i in 0..<Swift.min(err345Seq1.count, 2) {
            di.err345Seq1[i] = err345Seq1[i]
        }
        return self
    }
    
    /// Error 32 dt.
    public func err32Dt(_ err32Dt: [Int]) -> Self {
        for i in 0..<Swift.min(err32Dt.count, 2) {
            di.err32Dt[i] = err32Dt[i]
        }
        return self
    }
    
    /// Error 32 n.
    public func err32N(_ err32N: [Int]) -> Self {
        for i in 0..<Swift.min(err32N.count, 2) {
            di.err32N[i] = err32N[i]
        }
        return self
    }
    
    // MARK: - Device Info Fields
    
    /// Stabilization interval.
    public func stabilizationInterval(_ stabilizationInterval: Int) -> Self {
        di.stabilizationInterval = stabilizationInterval
        return self
    }
    
    /// CGM data interval.
    public func cgmDataInterval(_ cgmDataInterval: Int) -> Self {
        di.cgmDataInterval = cgmDataInterval
        return self
    }
    
    /// BLE adv interval.
    public func bleAdvInterval(_ bleAdvInterval: Int) -> Self {
        di.bleAdvInterval = bleAdvInterval
        return self
    }
    
    /// BLE adv duration.
    public func bleAdvDuration(_ bleAdvDuration: Int) -> Self {
        di.bleAdvDuration = bleAdvDuration
        return self
    }
    
    /// Age.
    public func age(_ age: Int) -> Self {
        di.age = age
        return self
    }
    
    /// Allowed list.
    public func allowedList(_ allowedList: Int) -> Self {
        di.allowedList = allowedList
        return self
    }
    
    /// C library version.
    public func cLibraryVersion(_ cLibraryVersion: Int) -> Self {
        di.cLibraryVersion = cLibraryVersion
        return self
    }
    
    /// Parameter version.
    public func parameterVersion(_ parameterVersion: Int) -> Self {
        di.parameterVersion = parameterVersion
        return self
    }
    
    /// Contact win len.
    public func contactWinLen(_ contactWinLen: Int) -> Self {
        di.contactWinLen = contactWinLen
        return self
    }
    
    /// Contact cond 1 x10.
    public func contactCond1X10(_ contactCond1X10: Int) -> Self {
        di.contactCond1X10 = contactCond1X10
        return self
    }
    
    /// Contact cond 2 x10.
    public func contactCond2X10(_ contactCond2X10: Int) -> Self {
        di.contactCond2X10 = contactCond2X10
        return self
    }
    
    /// Contact cond 3 x10.
    public func contactCond3X10(_ contactCond3X10: Int) -> Self {
        di.contactCond3X10 = contactCond3X10
        return self
    }
    
    /// Fill flag.
    public func fillFlag(_ fillFlag: Int) -> Self {
        di.fillFlag = fillFlag
        return self
    }
    
    /// Drift correction on.
    public func driftCorrectionOn(_ driftCorrectionOn: Int) -> Self {
        di.driftCorrectionOn = driftCorrectionOn
        return self
    }
    
    /// Drift coefficient.
    public func driftCoefficient(_ driftCoefficient: [[Float]]) -> Self {
        for i in 0..<Swift.min(driftCoefficient.count, 3) {
            for j in 0..<Swift.min(driftCoefficient[i].count, 3) {
                di.driftCoefficient[i][j] = driftCoefficient[i][j]
            }
        }
        return self
    }
    
    /// I ref x100.
    public func iRefX100(_ iRefX100: Int) -> Self {
        di.iRefX100 = iRefX100
        return self
    }
    
    /// Coef length.
    public func coefLength(_ coefLength: Int) -> Self {
        di.coefLength = coefLength
        return self
    }
    
    /// Div point.
    public func divPoint(_ divPoint: Int) -> Self {
        di.divPoint = divPoint
        return self
    }
    
    /// IIR st dx10.
    public func iirStDX10(_ iirStDX10: Int) -> Self {
        di.iirStDX10 = iirStDX10
        return self
    }
    
    /// Correct 1 flag.
    public func correct1Flag(_ correct1Flag: Int) -> Self {
        di.correct1Flag = correct1Flag
        return self
    }
    
    /// Correct 1 coeff.
    public func correct1Coeff(_ correct1Coeff: [Float]) -> Self {
        for i in 0..<Swift.min(correct1Coeff.count, 4) {
            di.correct1Coeff[i] = correct1Coeff[i]
        }
        return self
    }
    
    /// Kalman T90.
    public func kalmanT90(_ kalmanT90: Int) -> Self {
        di.kalmanT90 = kalmanT90
        return self
    }
    
    /// Kalman QX100.
    public func kalmanQX100(_ kalmanQX100: [[Int]]) -> Self {
        for i in 0..<Swift.min(kalmanQX100.count, 3) {
            for j in 0..<Swift.min(kalmanQX100[i].count, 3) {
                di.kalmanQX100[i][j] = kalmanQX100[i][j]
            }
        }
        return self
    }
    
    /// Kalman RX100.
    public func kalmanRX100(_ kalmanRX100: Int) -> Self {
        di.kalmanRX100 = kalmanRX100
        return self
    }
    
    /// BG cal ratio.
    public func bgCalRatio(_ bgCalRatio: Float) -> Self {
        di.bgCalRatio = bgCalRatio
        return self
    }
    
    /// BG cal time factor.
    public func bgCalTimeFactor(_ bgCalTimeFactor: Int) -> Self {
        di.bgCalTimeFactor = bgCalTimeFactor
        return self
    }
    
    /// Slope factor x10.
    public func slopeFactorX10(_ slopeFactorX10: Int) -> Self {
        di.slopeFactorX10 = slopeFactorX10
        return self
    }
    
    /// Slope inter up x10.
    public func slopeInterUpX10(_ slopeInterUpX10: Int) -> Self {
        di.slopeInterUpX10 = slopeInterUpX10
        return self
    }
    
    /// Slope inter down x10.
    public func slopeInterDownX10(_ slopeInterDownX10: Int) -> Self {
        di.slopeInterDownX10 = slopeInterDownX10
        return self
    }
    
    /// Slope multi VX10.
    public func slopeMultiVX10(_ slopeMultiVX10: Int) -> Self {
        di.slopeMultiVX10 = slopeMultiVX10
        return self
    }
    
    /// Slope iir thr.
    public func slopeIirThr(_ slopeIirThr: Int) -> Self {
        di.slopeIirThr = slopeIirThr
        return self
    }
    
    /// Slope neg inter thr1 x10.
    public func slopeNegInterThr1X10(_ slopeNegInterThr1X10: Int) -> Self {
        di.slopeNegInterThr1X10 = slopeNegInterThr1X10
        return self
    }
    
    /// Slope neg inter thr2 x10.
    public func slopeNegInterThr2X10(_ slopeNegInterThr2X10: Int) -> Self {
        di.slopeNegInterThr2X10 = slopeNegInterThr2X10
        return self
    }
    
    /// Slope bg cal thr down.
    public func slopeBgCalThrDown(_ slopeBgCalThrDown: Int) -> Self {
        di.slopeBgCalThrDown = slopeBgCalThrDown
        return self
    }
    
    /// Slope bg cal thr up.
    public func slopeBgCalThrUp(_ slopeBgCalThrUp: Int) -> Self {
        di.slopeBgCalThrUp = slopeBgCalThrUp
        return self
    }
    
    /// Slope max slope x100.
    public func slopeMaxSlopeX100(_ slopeMaxSlopeX100: Int) -> Self {
        di.slopeMaxSlopeX100 = slopeMaxSlopeX100
        return self
    }
    
    /// Slope min slope x100.
    public func slopeMinSlopeX100(_ slopeMinSlopeX100: Int) -> Self {
        di.slopeMinSlopeX100 = slopeMinSlopeX100
        return self
    }
    
    /// Slope dcal rate.
    public func slopeDcalRate(_ slopeDcalRate: Float) -> Self {
        di.slopeDcalRate = slopeDcalRate
        return self
    }
    
    /// Slope dcal target length.
    public func slopeDcalTargetLength(_ slopeDcalTargetLength: Int) -> Self {
        di.slopeDcalTargetLength = slopeDcalTargetLength
        return self
    }
    
    /// Slope dcal window.
    public func slopeDcalWindow(_ slopeDcalWindow: Int) -> Self {
        di.slopeDcalWindow = slopeDcalWindow
        return self
    }
    
    /// Slope dcal factory cal use.
    public func slopeDcalFactoryCalUse(_ slopeDcalFactoryCalUse: Int) -> Self {
        di.slopeDcalFactoryCalUse = slopeDcalFactoryCalUse
        return self
    }
    
    /// Shift msel.
    public func shiftMSel(_ shiftMSel: Int) -> Self {
        di.shiftMSel = shiftMSel
        return self
    }
    
    /// Shift coeff.
    public func shiftCoeff(_ shiftCoeff: [Float]) -> Self {
        for i in 0..<Swift.min(shiftCoeff.count, 4) {
            di.shiftCoeff[i] = shiftCoeff[i]
        }
        return self
    }
    
    /// Shift M2X100.
    public func shiftM2X100(_ shiftM2X100: [Int]) -> Self {
        for i in 0..<Swift.min(shiftM2X100.count, 3) {
            di.shiftM2X100[i] = shiftM2X100[i]
        }
        return self
    }
    
    /// Cal trend rate.
    public func calTrendRate(_ calTrendRate: Int) -> Self {
        di.calTrendRate = calTrendRate
        return self
    }
    
    /// Cal noise.
    public func calNoise(_ calNoise: Float) -> Self {
        di.calNoise = calNoise
        return self
    }
    
    /// Error code version.
    public func errcodeVersion(_ errcodeVersion: Int) -> Self {
        di.errcodeVersion = errcodeVersion
        return self
    }
    
    // MARK: - From DeviceInfo
    
    /// Set the full internal `DeviceInfo` directly.
    /// Use this when you have a pre-populated DeviceInfo (e.g., parsed from
    /// binary advertisement data).
    public func fromDeviceInfo(_ source: DeviceInfo) -> Self {
        copyDeviceInfo(source, di)
        return self
    }
    
    // MARK: - Build
    
    /// Build an immutable `SensorConfig`.
    ///
    /// - Throws: `SensorConfigError` if required fields are missing
    public func build() throws -> SensorConfig {
        precondition(di.vref != 0, "SensorConfig requires vref to be set")
        precondition(di.slope100 != 0, "SensorConfig requires slope100 to be set")
        
        let copy = DeviceInfo()
        copyDeviceInfo(di, copy)
        
        return SensorConfig(deviceInfo: copy)
    }
    
    // MARK: - Internal
    
    private func copyDeviceInfo(_ src: DeviceInfo, _ dst: inout DeviceInfo) {
        dst.sensorVersion = src.sensorVersion
        dst.ycept = src.ycept
        dst.slope100 = src.slope100
        dst.slope = src.slope
        dst.r2 = src.r2
        dst.t90 = src.t90
        dst.slopeRatio = src.slopeRatio
        dst.lot = src.lot
        dst.sensorId = src.sensorId
        dst.expiryDate = src.expiryDate
        dst.stabilizationInterval = src.stabilizationInterval
        dst.cgmDataInterval = src.cgmDataInterval
        dst.bleAdvInterval = src.bleAdvInterval
        dst.bleAdvDuration = src.bleAdvDuration
        dst.age = src.age
        dst.allowedList = src.allowedList
        dst.maximumValue = src.maximumValue
        dst.minimumValue = src.minimumValue
        dst.cLibraryVersion = src.cLibraryVersion
        dst.parameterVersion = src.parameterVersion
        dst.basicWarmup = src.basicWarmup
        dst.basicYcept = src.basicYcept
        dst.contactWinLen = src.contactWinLen
        dst.contactCond1X10 = src.contactCond1X10
        dst.contactCond2X10 = src.contactCond2X10
        dst.contactCond3X10 = src.contactCond3X10
        dst.fillFlag = src.fillFlag
        dst.driftCorrectionOn = src.driftCorrectionOn
        for i in 0..<3 {
            for j in 0..<3 {
                dst.driftCoefficient[i][j] = src.driftCoefficient[i][j]
            }
        }
        dst.iRefX100 = src.iRefX100
        dst.coefLength = src.coefLength
        dst.divPoint = src.divPoint
        dst.iirFlag = src.iirFlag
        dst.iirStDX10 = src.iirStDX10
        dst.correct1Flag = src.correct1Flag
        for i in 0..<4 {
            dst.correct1Coeff[i] = src.correct1Coeff[i]
        }
        dst.kalmanT90 = src.kalmanT90
        dst.kalmanDeltaT = src.kalmanDeltaT
        for i in 0..<3 {
            for j in 0..<3 {
                dst.kalmanQX100[i][j] = src.kalmanQX100[i][j]
            }
        }
        dst.kalmanRX100 = src.kalmanRX100
        dst.bgCalRatio = src.bgCalRatio
        dst.bgCalTimeFactor = src.bgCalTimeFactor
        dst.slopeFactorX10 = src.slopeFactorX10
        dst.slopeInterUpX10 = src.slopeInterUpX10
        dst.slopeInterDownX10 = src.slopeInterDownX10
        dst.slopeMultiVX10 = src.slopeMultiVX10
        dst.slopeIirThr = src.slopeIirThr
        dst.slopeNegInterThr1X10 = src.slopeNegInterThr1X10
        dst.slopeNegInterThr2X10 = src.slopeNegInterThr2X10
        dst.slopeBgCalThrDown = src.slopeBgCalThrDown
        dst.slopeBgCalThrUp = src.slopeBgCalThrUp
        dst.slopeMaxSlopeX100 = src.slopeMaxSlopeX100
        dst.slopeMinSlopeX100 = src.slopeMinSlopeX100
        dst.slopeDcalRate = src.slopeDcalRate
        dst.slopeDcalTargetLength = src.slopeDcalTargetLength
        dst.slopeDcalWindow = src.slopeDcalWindow
        dst.slopeDcalFactoryCalUse = src.slopeDcalFactoryCalUse
        dst.shiftMSel = src.shiftMSel
        for i in 0..<4 {
            dst.shiftCoeff[i] = src.shiftCoeff[i]
        }
        for i in 0..<3 {
            dst.shiftM2X100[i] = src.shiftM2X100[i]
        }
        for i in 0..<7 {
            dst.wSgX100[i] = src.wSgX100[i]
        }
        dst.calTrendRate = src.calTrendRate
        dst.calNoise = src.calNoise
        dst.errcodeVersion = src.errcodeVersion
        for i in 0..<3 {
            dst.err1Seq[i] = src.err1Seq[i]
        }
        dst.err1ContactBad = src.err1ContactBad
        dst.err1ThDiff = src.err1ThDiff
        for i in 0..<3 {
            dst.err1ThSseDmean[i] = src.err1ThSseDmean[i]
        }
        for i in 0..<4 {
            dst.err1ThN1[i] = src.err1ThN1[i]
        }
        for i in 0..<2 {
            for j in 0..<2 {
                dst.err1ThN2[i][j] = src.err1ThN2[i][j]
            }
        }
        dst.err1NConsecutive = src.err1NConsecutive
        for i in 0..<2 {
            dst.err1ISseDmeanNow[i] = src.err1ISseDmeanNow[i]
        }
        dst.err1CountSseDmean = src.err1CountSseDmean
        dst.err1NLast = src.err1NLast
        for i in 0..<2 {
            dst.err1Multi[i] = src.err1Multi[i]
        }
        dst.err1CurrentAvgDiff = src.err1CurrentAvgDiff
        dst.err2StartSeq = src.err2StartSeq
        for i in 0..<3 {
            dst.err2Seq[i] = src.err2Seq[i]
        }
        dst.err2Glu = src.err2Glu
        for i in 0..<3 {
            dst.err2Cv[i] = src.err2Cv[i]
        }
        dst.err2Cummax = src.err2Cummax
        dst.err2Multi = src.err2Multi
        dst.err2Ycept = src.err2Ycept
        dst.err2Alpha = src.err2Alpha
        for i in 0..<2 {
            dst.err345Seq1[i] = src.err345Seq1[i]
        }
        dst.err345Seq2 = src.err345Seq2
        for i in 0..<3 {
            dst.err345Seq3[i] = src.err345Seq3[i]
        }
        for i in 0..<5 {
            dst.err345Seq4[i] = src.err345Seq4[i]
        }
        for i in 0..<3 {
            dst.err345Seq5[i] = src.err345Seq5[i]
        }
        for i in 0..<4 {
            dst.err345Raw[i] = src.err345Raw[i]
        }
        for i in 0..<2 {
            dst.err345Filtered[i] = src.err345Filtered[i]
        }
        for i in 0..<2 {
            dst.err345Min[i] = src.err345Min[i]
        }
        dst.err345Range = src.err345Range
        dst.err345NRange = src.err345NRange
        dst.err345Md = src.err345Md
        dst.err345NMd = src.err345NMd
        dst.err6CalNPts = src.err6CalNPts
        dst.err6CalBasicPrct = src.err6CalBasicPrct
        dst.err6CalBasicSeq = src.err6CalBasicSeq
        dst.err6CalOriginSlope = src.err6CalOriginSlope
        for i in 0..<2 {
            dst.err6CalInVitro[i] = src.err6CalInVitro[i]
        }
        dst.err6CgmRpd = src.err6CgmRpd
        dst.err6CgmSlp = src.err6CgmSlp
        dst.err6CgmLow3dSeq = src.err6CgmLow3dSeq
        dst.err6CgmLow3dP = src.err6CgmLow3dP
        dst.err6CgmLow1dSeq = src.err6CgmLow1dSeq
        dst.err6CgmLow1dP = src.err6CgmLow1dP
        for i in 0..<3 {
            dst.err6CgmPrct[i] = src.err6CgmPrct[i]
        }
        for i in 0..<2 {
            dst.err6CgmDay[i] = src.err6CgmDay[i]
        }
        for i in 0..<2 {
            dst.err6CgmBleBad[i] = src.err6CgmBleBad[i]
        }
        dst.err6CgmPoly2 = src.err6CgmPoly2
        for i in 0..<2 {
            dst.err32Dt[i] = src.err32Dt[i]
        }
        for i in 0..<2 {
            dst.err32N[i] = src.err32N[i]
        }
        dst.vref = src.vref
        dst.eapp = src.eapp
        dst.sensorStartTime = src.sensorStartTime
    }
}

// MARK: - Error

/// Errors that can occur when constructing a `SensorConfig`.
public enum SensorConfigError: LocalizedError {
    case missingVref
    case missingSlope100
    
    public var errorDescription: String? {
        switch self {
        case .missingVref:
            return "SensorConfig requires vref to be set"
        case .missingSlope100:
            return "SensorConfig requires slope100 to be set"
        }
    }
}
