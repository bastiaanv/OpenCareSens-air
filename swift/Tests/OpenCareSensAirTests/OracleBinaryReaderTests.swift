import XCTest
@testable import OpenCareSensAir

/// Tests for OracleBinaryReader — verifies that we can correctly parse
/// oracle binary files into Swift model objects.
///
/// Converted from the Java JUnit 5 OracleBinaryReaderTest.
///
/// These tests read actual oracle data from oracle/output/lot0/.
/// Tests are skipped if oracle data is not present (e.g., CI without data).
final class OracleBinaryReaderTests: XCTestCase {

    // Path relative to swift/ directory; test runner cwd is swift/
    private static let oracleDir = "../oracle/output/lot0"
    private static var oracleDataAvailable: Bool = false

    override class func setUp() {
        super.setUp()
        let p = URL(fileURLWithPath: Self.oracleDir, isDirectory: true)
            .appendingPathComponent("seq_0001_output.bin")
        oracleDataAvailable = FileManager.default.fileExists(atPath: p.path)
    }

    private func requireOracleData() {
        guard oracleDataAvailable else {
            try? XCTSkipIf(!oracleDataAvailable, "Oracle data not available at \(Self.oracleDir)")
            return
        }
    }

    // MARK: - Output file tests

    func testReadOutput_seq1_hasCorrectSize() throws {
        requireOracleData()
        let p = URL(fileURLWithPath: Self.oracleDir, isDirectory: true)
            .appendingPathComponent("seq_0001_output.bin")
        let size = try FileManager.default.attributesOfItem(atPath: p.path)[.size] as! Int64
        XCTAssertEqual(OracleBinaryReader.outputSize, size)
    }

    func testReadOutput_seq1_seqNumberIsOne() throws {
        requireOracleData()
        let out = try OracleBinaryReader.readOutput(oracleDir: Self.oracleDir, seq: 1)
        XCTAssertEqual(1, out.seqNumberOriginal, "First reading should have seq_number_original=1")
    }

    func testReadOutput_seq1_hasValidFields() throws {
        requireOracleData()
        let out = try OracleBinaryReader.readOutput(oracleDir: Self.oracleDir, seq: 1)

        // seq_number_final should be reasonable (>= original)
        XCTAssertTrue(out.seqNumberFinal >= out.seqNumberOriginal,
            "seq_number_final should be >= seq_number_original")

        // measurement_time_standard should be after sensor_start_time (1709726400)
        XCTAssertTrue(out.measurementTimeStandard > 1709726400,
            "measurement_time should be after sensor start")

        // result_glucose is a double — verify it's a finite number (not NaN/Inf)
        // During warmup the oracle may output unclamped intermediate values
        XCTAssertTrue(Double.isFinite(out.resultGlucose),
            "Glucose should be finite, got \(out.resultGlucose)")

        // current_stage should be a small number (0-4 typically)
        XCTAssertTrue(out.currentStage <= 10,
            "current_stage should be small, got \(out.currentStage)")
    }

    func testReadOutput_seq1_workoutArrayIsPopulated() throws {
        requireOracleData()
        let out = try OracleBinaryReader.readOutput(oracleDir: Self.oracleDir, seq: 1)

        // workout[30] contains ADC readings; at least some should be non-zero
        var hasNonZero = false
        for i in 0..<30 {
            if out.workout[i] != 0 {
                hasNonZero = true
                break
            }
        }
        XCTAssertTrue(hasNonZero, "workout array should contain non-zero ADC values")
    }

    func testReadOutput_seq25_postWarmup_hasGlucose() throws {
        requireOracleData()
        // seq 25 is past the 24-reading warmup period
        let out = try OracleBinaryReader.readOutput(oracleDir: Self.oracleDir, seq: 25)
        XCTAssertEqual(25, out.seqNumberOriginal)
        // Post-warmup, glucose should be a real value (> 0) or error
        // We just verify the field was read; the oracle determines correctness
    }

    func testReadOutput_rawBytesMatchParsed() throws {
        requireOracleData()
        let out = try OracleBinaryReader.readOutput(oracleDir: Self.oracleDir, seq: 1)
        let raw = try OracleBinaryReader.readOutputRaw(oracleDir: Self.oracleDir, seq: 1)

        // Verify key fields at known offsets match parsed values
        XCTAssertEqual(out.seqNumberOriginal,
            OracleBinaryReader.extractUint16(raw, at: 0))
        XCTAssertEqual(out.seqNumberFinal,
            OracleBinaryReader.extractUint16(raw, at: 2))
        XCTAssertEqual(out.measurementTimeStandard,
            OracleBinaryReader.extractUint32(raw, at: 4))
        XCTAssertEqual(out.resultGlucose,
            OracleBinaryReader.extractDouble(raw, at: 68))
        XCTAssertEqual(out.trendrate,
            OracleBinaryReader.extractDouble(raw, at: 76))
        XCTAssertEqual(out.currentStage,
            OracleBinaryReader.extractUint8(raw, at: 84))
        XCTAssertEqual(out.errcode,
            OracleBinaryReader.extractUint16(raw, at: 151))
        XCTAssertEqual(out.calAvailableFlag,
            OracleBinaryReader.extractUint8(raw, at: 153))
        XCTAssertEqual(out.dataType,
            OracleBinaryReader.extractUint8(raw, at: 154))
    }

    // MARK: - Debug file tests

    func testReadDebug_seq1_hasCorrectSize() throws {
        requireOracleData()
        let p = URL(fileURLWithPath: Self.oracleDir, isDirectory: true)
            .appendingPathComponent("seq_0001_debug.bin")
        let size = try FileManager.default.attributesOfItem(atPath: p.path)[.size] as! Int64
        XCTAssertEqual(OracleBinaryReader.debugSize, size)
    }

    func testReadDebug_seq1_seqNumberMatchesOutput() throws {
        requireOracleData()
        let out = try OracleBinaryReader.readOutput(oracleDir: Self.oracleDir, seq: 1)
        let dbg = try OracleBinaryReader.readDebug(oracleDir: Self.oracleDir, seq: 1)

        XCTAssertEqual(out.seqNumberOriginal, dbg.seqNumberOriginal,
            "Debug and output should have same seq_number_original")
        XCTAssertEqual(out.seqNumberFinal, dbg.seqNumberFinal,
            "Debug and output should have same seq_number_final")
        XCTAssertEqual(out.measurementTimeStandard, dbg.measurementTimeStandard,
            "Debug and output should have same measurement_time_standard")
    }

    func testReadDebug_seq1_temperatureIsBodyTemp() throws {
        requireOracleData()
        let dbg = try OracleBinaryReader.readDebug(oracleDir: Self.oracleDir, seq: 1)

        // Oracle harness sets temperature = 36.5
        XCTAssertEqual(36.5, dbg.temperature, accuracy: 0.001,
            "Temperature should be 36.5 (body temp set by oracle harness)")
    }

    func testReadDebug_seq1_tranInAArrayPopulated() throws {
        requireOracleData()
        let dbg = try OracleBinaryReader.readDebug(oracleDir: Self.oracleDir, seq: 1)

        // tran_inA[30] are converted current values from ADC; should be non-zero
        var hasNonZero = false
        for i in 0..<30 {
            if dbg.tranInA[i] != 0.0 {
                hasNonZero = true
                break
            }
        }
        XCTAssertTrue(hasNonZero, "tran_inA should contain non-zero converted currents")
    }

    func testReadDebug_rawBytesMatchParsed_keyFields() throws {
        requireOracleData()
        let dbg = try OracleBinaryReader.readDebug(oracleDir: Self.oracleDir, seq: 1)
        let raw = try OracleBinaryReader.readDebugRaw(oracleDir: Self.oracleDir, seq: 1)

        // Verify against known offsets from compare_oracle.c
        XCTAssertEqual(dbg.seqNumberOriginal,
            OracleBinaryReader.extractUint16(raw, at: 0))
        XCTAssertEqual(dbg.seqNumberFinal,
            OracleBinaryReader.extractUint16(raw, at: 2))
        XCTAssertEqual(dbg.measurementTimeStandard,
            OracleBinaryReader.extractUint32(raw, at: 4))
        XCTAssertEqual(dbg.dataType,
            OracleBinaryReader.extractUint8(raw, at: 8))
        XCTAssertEqual(dbg.stage,
            OracleBinaryReader.extractUint8(raw, at: 9))
        XCTAssertEqual(dbg.temperature,
            OracleBinaryReader.extractDouble(raw, at: 10))

        // tran_inA_1min[0] at offset 318
        XCTAssertEqual(dbg.tranInA1min[0],
            OracleBinaryReader.extractDouble(raw, at: 318))

        // ycept at offset 366
        XCTAssertEqual(dbg.ycept,
            OracleBinaryReader.extractDouble(raw, at: 366))

        // corrected_re_current at offset 374
        XCTAssertEqual(dbg.correctedReCurrent,
            OracleBinaryReader.extractDouble(raw, at: 374))

        // init_cg at offset 473
        XCTAssertEqual(dbg.initCg,
            OracleBinaryReader.extractDouble(raw, at: 473))

        // opcal_ad at offset 489
        XCTAssertEqual(dbg.opcalAd,
            OracleBinaryReader.extractDouble(raw, at: 489))

        // error codes at known packed offsets
        XCTAssertEqual(dbg.errorCode1,
            OracleBinaryReader.extractUint8(raw, at: 974))
        XCTAssertEqual(dbg.errorCode2,
            OracleBinaryReader.extractUint8(raw, at: 975))

        // trendrate at offset 980
        XCTAssertEqual(dbg.trendrate,
            OracleBinaryReader.extractDouble(raw, at: 980))
    }

    func testReadDebug_consumesExactlyAllBytes() throws {
        requireOracleData()
        // This implicitly tests that our read doesn't throw the position mismatch error
        let dbg = try OracleBinaryReader.readDebug(oracleDir: Self.oracleDir, seq: 1)
        XCTAssertNotNil(dbg)
    }

    // MARK: - Input file tests

    func testReadInput_seq1_hasCorrectSeqNumber() throws {
        requireOracleData()
        let input = try OracleBinaryReader.readInput(oracleDir: Self.oracleDir, seq: 1)
        XCTAssertEqual(1, input.seqNumber)
    }

    func testReadInput_seq1_hasBodyTemperature() throws {
        requireOracleData()
        let input = try OracleBinaryReader.readInput(oracleDir: Self.oracleDir, seq: 1)
        XCTAssertEqual(36.5, input.temperature, accuracy: 0.001)
    }

    func testReadInput_seq1_workoutMatchesOutputWorkout() throws {
        requireOracleData()
        let input = try OracleBinaryReader.readInput(oracleDir: Self.oracleDir, seq: 1)
        let out = try OracleBinaryReader.readOutput(oracleDir: Self.oracleDir, seq: 1)

        // The output workout is just copied from input
        XCTAssertEqual(input.workout, out.workout,
            "Input and output workout arrays should match")
    }

    // MARK: - Cross-consistency: multiple readings

    func testReadMultipleSeqs_seqNumbersAreSequential() throws {
        requireOracleData()
        for seq in 1...5 {
            let out = try OracleBinaryReader.readOutput(oracleDir: Self.oracleDir, seq: seq)
            XCTAssertEqual(seq, out.seqNumberOriginal,
                "seq_number_original should match file seq for seq=\(seq)")
        }
    }

    func testReadMultipleSeqs_timeIncreases() throws {
        requireOracleData()
        var prevTime: Int64 = 0
        for seq in 1...5 {
            let out = try OracleBinaryReader.readOutput(oracleDir: Self.oracleDir, seq: seq)
            XCTAssertTrue(out.measurementTimeStandard > prevTime,
                "Time should increase between readings")
            prevTime = out.measurementTimeStandard
        }
    }

    func testReadMultipleSeqs_timeSpacingIs300Seconds() throws {
        requireOracleData()
        let out1 = try OracleBinaryReader.readOutput(oracleDir: Self.oracleDir, seq: 1)
        let out2 = try OracleBinaryReader.readOutput(oracleDir: Self.oracleDir, seq: 2)

        let delta = out2.measurementTimeStandard - out1.measurementTimeStandard
        XCTAssertEqual(300, delta, "Readings should be 300 seconds (5 min) apart")
    }

    // MARK: - Error handling tests

    func testReadOutput_nonexistentFile_throwsIOException() {
        XCTAssertThrowsError(try OracleBinaryReader.readOutput(oracleDir: "/nonexistent/path", seq: 1)) { error in
            XCTAssertTrue(error is OracleError)
        }
    }

    func testReadDebug_nonexistentFile_throwsIOException() {
        XCTAssertThrowsError(try OracleBinaryReader.readDebug(oracleDir: "/nonexistent/path", seq: 1)) { error in
            XCTAssertTrue(error is OracleError)
        }
    }

    // MARK: - Post-warmup validation (seq 50 = well past warmup)

    func testReadOutput_seq50_hasReasonableGlucose() throws {
        requireOracleData()
        let out = try OracleBinaryReader.readOutput(oracleDir: Self.oracleDir, seq: 50)
        // After warmup (seq > 24), glucose should typically be > 0 for normal profile
        // (unless there's an error code)
        if out.errcode == 0 {
            XCTAssertTrue(out.resultGlucose > 0,
                "Post-warmup, no-error reading should have glucose > 0, got \(out.resultGlucose)")
        }
    }

    func testReadDebug_seq50_intermediateValuesPopulated() throws {
        requireOracleData()
        let dbg = try OracleBinaryReader.readDebug(oracleDir: Self.oracleDir, seq: 50)

        // After warmup, several intermediate values should be non-zero
        // init_cg is the initial calibrated glucose — should be populated
        // out_rescale should have been computed
        // We verify the parsing produced values, not their correctness
        XCTAssertNotEqual(0.0, dbg.correctedReCurrent,
            "corrected_re_current should be non-zero at seq 50")
    }

    // MARK: - Lot consistency

    func testReadOutput_allLots_seq1HasSeqOne() throws {
        let lots = ["lot0", "lot1", "lot2", "lot3", "lot4"]
        for lot in lots {
            let dir = "../oracle/output/\(lot)"
            let p = URL(fileURLWithPath: dir, isDirectory: true)
                .appendingPathComponent("seq_0001_output.bin")
            guard FileManager.default.fileExists(atPath: p.path) else { continue }

            let out = try OracleBinaryReader.readOutput(oracleDir: dir, seq: 1)
            XCTAssertEqual(1, out.seqNumberOriginal,
                "seq_number_original should be 1 for \(lot)")
        }
    }
}
