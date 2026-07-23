// BlePacketParser.swift
// Parses raw CareSens Air BLE C5 characteristic notifications into structured readings.

import Foundation

/// Parses raw CareSens Air BLE C5 characteristic notifications into structured readings.
public enum BlePacketParser {

    /// Expected size of a complete BLE C5 notification packet.
    public static let packetSize = 84

    /// Parse a CareSens Air BLE C5 notification into components.
    public static func parse(_ bleData: [UInt8]) -> ParsedReading {
        guard bleData.count >= packetSize else {
            fatalError("bleData must be at least \(packetSize) bytes, got \(bleData.count)")
        }

        let data = Data(bleData)

        // Offsets 0-3: reg0, reg1, deviceErrorCode, r_count
        let deviceErrorCode = Int(Int8(bitPattern: bleData[2]))

        // Offset 4: a_count (uint32, skip)
        // Offset 8: misc (uint32, skip)

        // Offset 12: sequenceNumber (uint32)
        let sequenceNumber = data.readUInt32LE(at: 12)

        // Offset 16: time (uint32 Unix seconds)
        let timestamp = UInt64(data.readUInt32LE(at: 16))

        // Offset 20: battery (uint16)
        let battery = Int(data.readUInt16LE(at: 20))

        // Offset 22: temperature (uint16, raw units of 0.01 degrees Celsius)
        let rawTemperature = Int(data.readUInt16LE(at: 22))
        let temperature = Double(rawTemperature) / 100.0

        // Offset 24: glucose_array[30] (uint16 each, ADC samples)
        var adcSamples = [Int](repeating: 0, count: 30)
        for i in 0..<30 {
            adcSamples[i] = Int(data.readUInt16LE(at: 24 + i * 2))
        }

        return ParsedReading(
            sequenceNumber: Int(sequenceNumber),
            timestamp: Int64(timestamp),
            adcSamples: adcSamples,
            temperature: temperature,
            battery: battery,
            deviceErrorCode: deviceErrorCode
        )
    }

    /// A parsed BLE reading with all fields extracted and ready for processing.
    public struct ParsedReading {
        public let sequenceNumber: Int
        public let timestamp: Int64
        public let adcSamples: [Int]
        public let temperature: Double
        public let battery: Int
        public let deviceErrorCode: Int

        public init(sequenceNumber: Int, timestamp: Int64, adcSamples: [Int],
                    temperature: Double, battery: Int, deviceErrorCode: Int) {
            self.sequenceNumber = sequenceNumber
            self.timestamp = timestamp
            self.adcSamples = adcSamples
            self.temperature = temperature
            self.battery = battery
            self.deviceErrorCode = deviceErrorCode
        }

        public var description: String {
            String(format: "ParsedReading{seq=%d, time=%lld, temp=%.2f°C, battery=%d, deviceError=%d, adcSamples[0]=%d}",
                   sequenceNumber, timestamp, temperature, battery, deviceErrorCode, adcSamples[0])
        }
    }
}

// MARK: - Data Little-Endian Helpers

private extension Data {
    func readUInt16LE(at offset: Int) -> UInt16 {
        UInt16(self[offset]) | (UInt16(self[offset + 1]) << 8)
    }

    func readUInt32LE(at offset: Int) -> UInt32 {
        UInt32(self[offset]) | (UInt32(self[offset + 1]) << 8) |
        (UInt32(self[offset + 2]) << 16) | (UInt32(self[offset + 3]) << 24)
    }
}
