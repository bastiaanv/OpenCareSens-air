// SensorConfig.swift
// Factory calibration parameters for a CareSens Air CGM sensor.
//
// These values originate from the sensor's BLE advertisement data and
// encode the factory calibration performed during manufacturing. They are
// immutable once constructed.
//
// Use the Builder for construction:
//
//   let config = SensorConfig.Builder()
//       .eapp(0.10067)
//       .vref(1.2)
//       .slope100(2.5)
//       .sensorStartTime(Int64(Date().timeIntervalSince1970))
//       .basicWarmup(5)
//       .err345Seq2(5)
//       .build()

/// Factory calibration parameters for a CareSens Air CGM sensor.
public struct SensorConfig {

    internal let deviceInfo: DeviceInfo

    private init(deviceInfo: DeviceInfo) {
        self.deviceInfo = deviceInfo
    }

    // ======================================================================
    // Primary getters — the values most integrators need
    // ======================================================================

    /// Electrochemical apparent potential (V). Determines lot type.
    public var eapp: Float { deviceInfo.eapp }

    /// Reference voltage (V).
    public var vref: Float { deviceInfo.vref }

    /// Slope calibration factor (x100).
    public var slope100: Float { deviceInfo.slope100 }

    /// Slope calibration factor.
    public var slope: Float { deviceInfo.slope }

    /// Y-intercept from factory calibration.
    public var ycept: Float { deviceInfo.ycept }

    /// Sensor lot identifier.
    public var lot: String { deviceInfo.lot }

    /// Unique sensor identifier.
    public var sensorId: String { deviceInfo.sensorId }

    /// Sensor start time (Unix seconds).
    public var sensorStartTime: Int64 { deviceInfo.sensorStartTime }

    /// Number of warmup readings before glucose is reliable.
    public var basicWarmup: Int { deviceInfo.basicWarmup }

    /// Sequence number threshold for warmup/steady-state transition.
    public var err345Seq2: Int { deviceInfo.err345Seq2 }

    // ======================================================================
    // Internal access to the DeviceInfo
    // ======================================================================

    internal func toDeviceInfo() -> DeviceInfo {
        return deviceInfo
    }

    // ======================================================================
    // Builder
    // ======================================================================

    /// Builder for constructing a `SensorConfig` from individual fields.
    ///
    /// At minimum, `eapp`, `vref`, and `slope100` must be set.
    /// All other fields have safe defaults.
    public struct Builder {
        private let di = DeviceInfo()

        public init() {}

        // ------------------------------------------------------------------
        // Scalar setters
        // ------------------------------------------------------------------

        /// Electrochemical apparent potential (V). Required.
        @discardableResult
        public func eapp(_ eapp: Float) -> Builder {
            di.eapp = eapp
            return self
        }

        /// Reference voltage (V). Required.
        @discardableResult
        public func vref(_ vref: Float) -> Builder {
            di.vref = vref
            return self
        }

        /// Slope calibration factor (x100). Required.
        @discardableResult
        public func slope100(_ slope100: Float) -> Builder {
            di.slope100 = slope100
            return self
        }

        /// Slope calibration factor.
        @discardableResult
        public func slope(_ slope: Float) -> Builder {
            di.slope = slope
            return self
        }

        /// Y-intercept from factory calibration.
        @discardableResult
        public func ycept(_ ycept: Float) -> Builder {
            di.ycept = ycept
            return self
        }

        /// R-squared from factory calibration.
        @discardableResult
        public func r2(_ r2: Float) -> Builder {
            di.r2 = r2
            return self
        }

        /// T90 response time (minutes).
        @discardableResult
        public func t90(_ t90: Float) -> Builder {
            di.t90 = t90
            return self
        }

        /// Slope ratio.
        @discardableResult
        public func slopeRatio(_ slopeRatio: Float) -> Builder {
            di.slopeRatio = slopeRatio
            return self
        }

        /// Sensor lot identifier.
        @discardableResult
        public func lot(_ lot: String) -> Builder {
            di.lot = lot
            return self
        }

        /// Unique sensor identifier.
        @discardableResult
        public func sensorId(_ sensorId: String) -> Builder {
            di.sensorId = sensorId
            return self
        }

        /// Sensor expiry date string.
        @discardableResult
        public func expiryDate(_ expiryDate: String) -> Builder {
            di.expiryDate = expiryDate
            return self
        }

        /// Sensor start time (Unix seconds).
        @discardableResult
        public func sensorStartTime(_ sensorStartTime: Int64) -> Builder {
            di.sensorStartTime = sensorStartTime
            return self
        }

        /// Sensor version.
        @discardableResult
        public func sensorVersion(_ sensorVersion: Int) -> Builder {
            di.sensorVersion = sensorVersion
            return self
        }

        /// Number of warmup readings.
        @discardableResult
        public func basicWarmup(_ basicWarmup: Int) -> Builder {
            di.basicWarmup = basicWarmup
            return self
        }

        /// Warmup/steady-state transition sequence number.
        @discardableResult
        public func err345Seq2(_ err345Seq2: Int) -> Builder {
            di.err345Seq2 = err345Seq2
            return self
        }

        /// IIR filter flag (0=disabled, 1=enabled).
        @discardableResult
        public func iirFlag(_ iirFlag: Int) -> Builder {
            di.iirFlag = iirFlag
            return self
        }

        /// Maximum glucose value (mg/dL).
        @discardableResult
        public func maximumValue(_ maximumValue: Float) -> Builder {
            di.maximumValue = maximumValue
            return self
        }

        /// Minimum glucose value (mg/dL).
        @discardableResult
        public func minimumValue(_ minimumValue: Float) -> Builder {
            di.minimumValue = minimumValue
            return self
        }

        // ------------------------------------------------------------------
        // Array setters
        // ------------------------------------------------------------------

        /// Savitzky-Golay filter weights (7 elements, x100).
        @discardableResult
        public func wSgX100(_ wSgX100: [Int]) -> Builder {
            let count = min(wSgX100.count, 7)
            for i in 0..<count {
                di.wSgX100[i] = wSgX100[i]
            }
            return self
        }

        /// Error detection sequence thresholds.
        @discardableResult
        public func err1Seq(_ err1Seq: [Int]) -> Builder {
            let count = min(err1Seq.count, 3)
            for i in 0..<count {
                di.err1Seq[i] = err1Seq[i]
            }
            return self
        }

        /// Error detection multiplier.
        @discardableResult
        public func err1Multi(_ err1Multi: [Int]) -> Builder {
            let count = min(err1Multi.count, 2)
            for i in 0..<count {
                di.err1Multi[i] = err1Multi[i]
            }
            return self
        }

        /// Error 2 start sequence.
        @discardableResult
        public func err2StartSeq(_ err2StartSeq: Int) -> Builder {
            di.err2StartSeq = err2StartSeq
            return self
        }

        /// Error 2 sequence thresholds.
        @discardableResult
        public func err2Seq(_ err2Seq: [Int]) -> Builder {
            let count = min(err2Seq.count, 3)
            for i in 0..<count {
                di.err2Seq[i] = err2Seq[i]
            }
            return self
        }

        /// Error 2 cummax.
        @discardableResult
        public func err2Cummax(_ err2Cummax: Int) -> Builder {
            di.err2Cummax = err2Cummax
            return self
        }

        /// Error 2 glucose threshold.
        @discardableResult
        public func err2Glu(_ err2Glu: Float) -> Builder {
            di.err2Glu = err2Glu
            return self
        }

        /// Error 3/4/5 sequence thresholds (array of 5).
        @discardableResult
        public func err345Seq4(_ err345Seq4: [Int]) -> Builder {
            let count = min(err345Seq4.count, 5)
            for i in 0..<count {
                di.err345Seq4[i] = err345Seq4[i]
            }
            return self
        }

        /// Error 32 delta-time thresholds.
        @discardableResult
        public func err32Dt(_ err32Dt: [Int]) -> Builder {
            let count = min(err32Dt.count, 2)
            for i in 0..<count {
                di.err32Dt[i] = err32Dt[i]
            }
            return self
        }

        /// Error 32 count thresholds.
        @discardableResult
        public func err32N(_ err32N: [Int]) -> Builder {
            let count = min(err32N.count, 2)
            for i in 0..<count {
                di.err32N[i] = err32N[i]
            }
            return self
        }

        /// Error 1 last-N window.
        @discardableResult
        public func err1NLast(_ err1NLast: Int) -> Builder {
            di.err1NLast = err1NLast
            return self
        }

        /// Kalman delta-T.
        @discardableResult
        public func kalmanDeltaT(_ kalmanDeltaT: Int) -> Builder {
            di.kalmanDeltaT = kalmanDeltaT
            return self
        }

        /// Basic Y-intercept.
        @discardableResult
        public func basicYcept(_ basicYcept: Float) -> Builder {
            di.basicYcept = basicYcept
            return self
        }

        // ------------------------------------------------------------------
        // Bulk setter
        // ------------------------------------------------------------------

        /// Set the full internal `DeviceInfo` directly.
        ///
        /// Use this when you have a pre-populated DeviceInfo (e.g., parsed
        /// from binary advertisement data).
        @discardableResult
        public func fromDeviceInfo(_ source: DeviceInfo) -> Builder {
            SensorConfig.copyDeviceInfo(source, di)
            return self
        }

        // ------------------------------------------------------------------
        // Build
        // ------------------------------------------------------------------

        /// Build an immutable `SensorConfig`.
        ///
        /// - Precondition: `vref` and `slope100` must be non-zero.
        public func build() -> SensorConfig {
            precondition(di.vref != 0.0, "SensorConfig requires vref to be set")
            precondition(di.slope100 != 0.0, "SensorConfig requires slope100 to be set")

            // Deep-copy to prevent mutation of builder from corrupting the SensorConfig
            let copy = DeviceInfo()
            SensorConfig.copyDeviceInfo(di, copy)
            return SensorConfig(deviceInfo: copy)
        }
    }

    // ======================================================================
    // Deep copy helper
    // ======================================================================

    /// Deep-copy all fields from `src` to `dst`.
    ///
    /// Scalar fields are assigned directly. Array and 2D-array fields are
    /// copied element-by-element to avoid sharing mutable storage between
    /// the source and the destination.
    internal static func copyDeviceInfo(_ src: DeviceInfo, _ dst: DeviceInfo) {
        // --- Scalars ---
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

        // driftCoefficient: 3x3
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

        // correct1Coeff: 4
        for i in 0..<4 {
            dst.correct1Coeff[i] = src.correct1Coeff[i]
        }

        dst.kalmanT90 = src.kalmanT90
        dst.kalmanDeltaT = src.kalmanDeltaT

        // kalmanQX100: 3x3
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

        // shiftCoeff: 4
        for i in 0..<4 {
            dst.shiftCoeff[i] = src.shiftCoeff[i]
        }

        // shiftM2X100: 3
        for i in 0..<3 {
            dst.shiftM2X100[i] = src.shiftM2X100[i]
        }

        // wSgX100: 7
        for i in 0..<7 {
            dst.wSgX100[i] = src.wSgX100[i]
        }

        dst.calTrendRate = src.calTrendRate
        dst.calNoise = src.calNoise
        dst.errcodeVersion = src.errcodeVersion

        // err1Seq: 3
        for i in 0..<3 {
            dst.err1Seq[i] = src.err1Seq[i]
        }

        dst.err1ContactBad = src.err1ContactBad
        dst.err1ThDiff = src.err1ThDiff

        // err1ThSseDmean: 3
        for i in 0..<3 {
            dst.err1ThSseDmean[i] = src.err1ThSseDmean[i]
        }

        // err1ThN1: 4
        for i in 0..<4 {
            dst.err1ThN1[i] = src.err1ThN1[i]
        }

        // err1ThN2: 2x2
        for i in 0..<2 {
            for j in 0..<2 {
                dst.err1ThN2[i][j] = src.err1ThN2[i][j]
            }
        }

        dst.err1NConsecutive = src.err1NConsecutive

        // err1ISseDmeanNow: 2
        for i in 0..<2 {
            dst.err1ISseDmeanNow[i] = src.err1ISseDmeanNow[i]
        }

        dst.err1CountSseDmean = src.err1CountSseDmean
        dst.err1NLast = src.err1NLast

        // err1Multi: 2
        for i in 0..<2 {
            dst.err1Multi[i] = src.err1Multi[i]
        }

        dst.err1CurrentAvgDiff = src.err1CurrentAvgDiff
        dst.err2StartSeq = src.err2StartSeq

        // err2Seq: 3
        for i in 0..<3 {
            dst.err2Seq[i] = src.err2Seq[i]
        }

        dst.err2Glu = src.err2Glu

        // err2Cv: 3
        for i in 0..<3 {
            dst.err2Cv[i] = src.err2Cv[i]
        }

        dst.err2Cummax = src.err2Cummax
        dst.err2Multi = src.err2Multi
        dst.err2Ycept = src.err2Ycept
        dst.err2Alpha = src.err2Alpha

        // err345Seq1: 2
        for i in 0..<2 {
            dst.err345Seq1[i] = src.err345Seq1[i]
        }

        dst.err345Seq2 = src.err345Seq2

        // err345Seq3: 3
        for i in 0..<3 {
            dst.err345Seq3[i] = src.err345Seq3[i]
        }

        // err345Seq4: 5
        for i in 0..<5 {
            dst.err345Seq4[i] = src.err345Seq4[i]
        }

        // err345Seq5: 3
        for i in 0..<3 {
            dst.err345Seq5[i] = src.err345Seq5[i]
        }

        // err345Raw: 4
        for i in 0..<4 {
            dst.err345Raw[i] = src.err345Raw[i]
        }

        // err345Filtered: 2
        for i in 0..<2 {
            dst.err345Filtered[i] = src.err345Filtered[i]
        }

        // err345Min: 2
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

        // err6CalInVitro: 2
        for i in 0..<2 {
            dst.err6CalInVitro[i] = src.err6CalInVitro[i]
        }

        dst.err6CgmRpd = src.err6CgmRpd
        dst.err6CgmSlp = src.err6CgmSlp
        dst.err6CgmLow3dSeq = src.err6CgmLow3dSeq
        dst.err6CgmLow3dP = src.err6CgmLow3dP
        dst.err6CgmLow1dSeq = src.err6CgmLow1dSeq
        dst.err6CgmLow1dP = src.err6CgmLow1dP

        // err6CgmPrct: 3
        for i in 0..<3 {
            dst.err6CgmPrct[i] = src.err6CgmPrct[i]
        }

        // err6CgmDay: 2
        for i in 0..<2 {
            dst.err6CgmDay[i] = src.err6CgmDay[i]
        }

        // err6CgmBleBad: 2
        for i in 0..<2 {
            dst.err6CgmBleBad[i] = src.err6CgmBleBad[i]
        }

        dst.err6CgmPoly2 = src.err6CgmPoly2

        // err32Dt: 2
        for i in 0..<2 {
            dst.err32Dt[i] = src.err32Dt[i]
        }

        // err32N: 2
        for i in 0..<2 {
            dst.err32N[i] = src.err32N[i]
        }

        dst.vref = src.vref
        dst.eapp = src.eapp
        dst.sensorStartTime = src.sensorStartTime
    }
}
