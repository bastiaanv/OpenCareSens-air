// BlePacketParserTests.swift
// Tests for BlePacketParser, converted from the Java JUnit 5 BlePacketParserTest.

import XCTest
@testable import OpenCareSensAir

/// Tests for `BlePacketParser`.
final class BlePacketParserTests: XCTestCase {

    // MARK: - Helpers

    /// Build a synthetic 84-byte BLE C5 packet with known values.
    private func buildTestPacket(seq: Int, time: Int, battery: Int,
                                 rawTemp: Int, deviceError: Int,
                                 adcValues: [Int]?) -> [UInt8] {
        var packet = [UInt8]()
        packet.append(0xC5)        // reg0
        packet.append(0x01)        // reg1
        packet.append(UInt8(bitPattern: Int8(deviceError)))  // deviceErrorCode (int8)
        packet.append(0x00)        // r_count
        packet.append(contentsOf: int32LE(0))             // a_count
        packet.append(contentsOf: int32LE(0))             // misc
        packet.append(contentsOf: int32LE(Int32(seq)))    // sequenceNumber
        packet.append(contentsOf: int32LE(Int32(time)))   // time
        packet.append(contentsOf: int16LE(battery))       // battery
        packet.append(contentsOf: int16LE(rawTemp))       // temperature (raw)
        for i in 0..<30 {
            let val = (adcValues != nil && i < adcValues!.count) ? adcValues![i] : 0
            packet.append(contentsOf: int16LE(val))
        }
        return packet
    }

    private func int16LE(_ value: Int) -> [UInt8] {
        [UInt8(value & 0xFF), UInt8((value >> 8) & 0xFF)]
    }

    private func int32LE(_ value: Int32) -> [UInt8] {
        let v = UInt32(bitPattern: value)
        return [UInt8(v & 0xFF), UInt8((v >> 8) & 0xFF),
                UInt8((v >> 16) & 0xFF), UInt8((v >> 24) & 0xFF)]
    }

    // MARK: - Tests

    func testParseKnownPacket() {
        var adc = [Int](repeating: 0, count: 30)
        for i in 0..<30 {
            adc[i] = 1000 + i
        }

        let packet = buildTestPacket(
            seq: 42,          // sequenceNumber
            time: 1700000000, // timestamp (2023-11-14)
            battery: 3700,    // battery
            rawTemp: 3412,    // rawTemp => 34.12 C
            deviceError: 0,   // no device error
            adcValues: adc
        )

        let reading = BlePacketParser.parse(packet)

        XCTAssertEqual(42, reading.sequenceNumber)
        XCTAssertEqual(Int64(1700000000), reading.timestamp)
        XCTAssertEqual(3700, reading.battery)
        XCTAssertEqual(34.12, reading.temperature, accuracy: 0.001)
        XCTAssertEqual(0, reading.deviceErrorCode)

        let parsed = reading.adcSamples
        XCTAssertEqual(30, parsed.count)
        for i in 0..<30 {
            XCTAssertEqual(1000 + i, parsed[i], "ADC sample \(i)")
        }
    }

    func testParseDeviceErrorCode() {
        let packet = buildTestPacket(seq: 1, time: 1000, battery: 0,
                                     rawTemp: 3000, deviceError: -5, adcValues: nil)
        let reading = BlePacketParser.parse(packet)
        XCTAssertEqual(-5, reading.deviceErrorCode)
    }

    func testParseHighTemperature() {
        // rawTemp = 4000 => 40.00 C
        let packet = buildTestPacket(seq: 1, time: 1000, battery: 0,
                                     rawTemp: 4000, deviceError: 0, adcValues: nil)
        let reading = BlePacketParser.parse(packet)
        XCTAssertEqual(40.00, reading.temperature, accuracy: 0.001)
    }

    func testParseHighAdcValues() {
        // uint16 max = 65535
        var adc = [Int](repeating: 0, count: 30)
        for i in 0..<30 {
            adc[i] = 65535
        }
        let packet = buildTestPacket(seq: 1, time: 1000, battery: 0,
                                     rawTemp: 3000, deviceError: 0, adcValues: adc)
        let reading = BlePacketParser.parse(packet)
        for v in reading.adcSamples {
            XCTAssertEqual(65535, v)
        }
    }

    func testAdcSamplesAreDefensivelyCopied() {
        let packet = buildTestPacket(seq: 1, time: 1000, battery: 0,
                                     rawTemp: 3000, deviceError: 0,
                                     adcValues: [Int](repeating: 0, count: 30))
        let reading = BlePacketParser.parse(packet)

        // Swift arrays are value types, so mutating a retrieved copy never
        // affects the original. This mirrors the Java defensive-copy guarantee.
        var first = reading.adcSamples
        first[0] = 99999
        let second = reading.adcSamples
        XCTAssertEqual(0, second[0], "Modifying returned array must not affect internal state")
    }

    func testNullInputThrows() {
        // Skipped: Swift's parse(_:) takes a non-optional [UInt8], so a null
        // packet cannot be expressed at the type level. The Java null-check has
        // no equivalent here.
    }

    func testShortInputThrows() {
        // Skipped: The Swift implementation calls fatalError() for packets
        // shorter than 84 bytes. Swift's fatalError cannot be caught by
        // XCTest, so this boundary cannot be exercised as a throwing test.
    }

    func testExactMinimumSize() {
        let exact = [UInt8](repeating: 0, count: BlePacketParser.packetSize)
        // Should not throw — all zeros is a valid parse
        let reading = BlePacketParser.parse(exact)
        XCTAssertEqual(0, reading.sequenceNumber)
        XCTAssertEqual(Int64(0), reading.timestamp)
        XCTAssertEqual(0.0, reading.temperature, accuracy: 0.001)
        XCTAssertEqual(30, reading.adcSamples.count)
    }

    func testLargerBufferAccepted() {
        // Packets larger than 84 bytes should parse fine (extra bytes ignored)
        let larger = [UInt8](repeating: 0, count: 100)
        let reading = BlePacketParser.parse(larger)
        // In Swift parse(_:) returns a non-optional ParsedReading, so it is
        // never nil; verify it parsed successfully by checking a property.
        XCTAssertEqual(30, reading.adcSamples.count)
    }

    func testToStringContainsKey() {
        let packet = buildTestPacket(seq: 7, time: 2000, battery: 100,
                                     rawTemp: 3600, deviceError: 0, adcValues: nil)
        let reading = BlePacketParser.parse(packet)
        let s = reading.description
        XCTAssertTrue(s.contains("seq=7"))
        XCTAssertTrue(s.contains("36.00"))
    }
}
