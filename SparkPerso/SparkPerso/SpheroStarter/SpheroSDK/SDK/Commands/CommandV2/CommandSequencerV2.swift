//
//  CommandSequencerV2.swift
//  PlaygroundContent
//
//  Created by Jeff Payan on 2017-06-23.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation


extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

private struct UnpackedData {
    let payload: Data
    let deviceId: UInt8
    let commandId: UInt8
}

fileprivate protocol CommandResponseParser {
    func parseData(_ data: Data) -> CommandResponseV2?
    func unpackData(_ data: Data) -> UnpackedData?
}

extension CommandResponseParser {
    func parseData(_ data: Data) -> CommandResponseV2? {
        guard let unpackedData = unpackData(data) else {
            return nil
        }
        
        let payload = unpackedData.payload
        let deviceId = unpackedData.deviceId
        let commandId = unpackedData.commandId
        
        switch deviceId {
        case DeviceId.sensor.rawValue:
            switch commandId {
            case SensorCommandIds.sensorMask.rawValue:
                return SensorMaskCommandResponse()
            case SensorCommandIds.extendedSensorMask.rawValue:
                return SensorExtendedMaskCommandResponse()
            case SensorCommandIds.sensorResponse.rawValue:
                return SensorDataCommandResponseV2(data: Data(payload))
                
            case SensorCommandIds.collisionDetectedAsync.rawValue:
                return CollisionDataCommandResponseV2(data: [UInt8](payload))
                
            default:
                break
            }
            
        case DeviceId.systemInfo.rawValue:
            switch commandId {
            case SystemInfoCommandIds.mainApplicationVersion.rawValue:
                return VersionsCommandResponseV2(Data(payload))
            default:
                break
            }
            
        case DeviceId.powerInfo.rawValue:
            switch commandId {
            case PowerCommandIds.wake.rawValue:
                return WakeCommandResponse()
                
            case PowerCommandIds.batteryVoltage.rawValue:
                return BatteryVoltageResponse(Data(payload))
                
            case PowerCommandIds.sleep.rawValue:
                return DidSleepResponseV2()
                
            case PowerCommandIds.willSleepNotify.rawValue:
                return PreSleepWarningResponse()
            default:
                break
            }
            
        case DeviceId.animatronics.rawValue:
            switch commandId {
            case AnimatronicsCommandIds.shoulderActionComplete.rawValue:
                return ShouldActionCompleteResponse(Data(payload))
                
            default:
                break
            }
            
        default:
            break
        }
        
        return nil
    }
    
    func unpackData(_ data: Data) -> UnpackedData? {
        guard data.count >= 6 else {
            return nil
        }
        
        let flags = CommandV2Flags(rawValue: data[1])
        
        var index = 2
        if (flags.contains(.commandHasTargetId)) {
            index += 1
        }
        
        if (flags.contains(.commandHasSourceId)) {
            index += 1
        }
        
        guard (index + 3) <= (data.count - 2) else {
            return nil
        }
        
        let deviceId = data[index]
        index += 1
        let commandId = data[index]
        index += 1
        
        // This is for the sequence number, which we don't use
        _ = data[index]
        index += 1
        
        if (flags.contains(.isResponse)) {
            let responseCode = data[index]
            index += 1
            guard responseCode == 0x00 else {
                print("response had an error, error code: \(responseCode)");
                return nil
            }
            
        }
        
        // Chop off End Of Packet and Checksum
        let payload = data[index..<data.count-2]
        
        return UnpackedData(payload: payload, deviceId: deviceId, commandId: commandId)
    }
}

private struct CommandV2ResponseParser: CommandResponseParser { }

public class CommandSequencerV2 {
    private enum ParsingState {
        case waitingForStartOfPacket
        case waitingForEndOfPacket
    }
    
    private var parsingState = ParsingState.waitingForStartOfPacket
    private var isEscaped = false
    private var currentData = [UInt8]()
    private var skippedData = false
    private var checksum: UInt8 = 0
    
    public typealias ParserCallback = ((_ sequencer: CommandSequencerV2, _ response: CommandResponseV2?) -> Void)
    
    fileprivate var commandSequenceNumber = UInt8(0)
    fileprivate func getNextSequenceNumber() -> UInt8 {
        let returnVal = commandSequenceNumber
        commandSequenceNumber = commandSequenceNumber &+ 1
        return returnVal
    }
    
    private var parserCallback: ParserCallback?
    fileprivate var parser: CommandResponseParser = CommandV2ResponseParser()
    
    public func parseResponseFromToy(_ data: Data, callback: ParserCallback?) {
        parserCallback = callback
        for byte in [UInt8](data) {
            processByte(byte: byte)
        }
    }
    
    private func processByte(byte: UInt8) {
        var byteCopy = byte
        if currentData.count == 0 {
            if byte != APIV2Constants.startOfPacket {
                skippedData = true
                print("current data was empty but first byte was not SOP")
                return
            }
        }
        
        switch byte {
        case APIV2Constants.startOfPacket:
            if parsingState != .waitingForStartOfPacket {
                print("got SOP but parser state was not waiting for it")
                reset()
                return
            }
            
            if skippedData {
                skippedData = false
                print("skipped data, not sure what this means")
            }
            
            parsingState = .waitingForEndOfPacket
            checksum = 0
            currentData.append(byteCopy)
            return
            
        case APIV2Constants.endOfPacket:
            currentData.append(byteCopy)

            if parsingState != .waitingForEndOfPacket || currentData.count < 7 {
                print("got EOP but parser state was not waiting for it")
                reset()
                return
            }
            
            if checksum != 0xFF {
                reset()
                return
            }
            
            let data = Data(bytes: currentData)
            reset()
            
            let response = parser.parseData(data)
            parserCallback?(self, response)
            
            return
            
        case APIV2Constants.escape:
            if isEscaped {
                print("got an escape while already escaped. panic!")
                reset()
                return
            }
            
            isEscaped = true
            return
            
        case APIV2Constants.escapedStartOfPacket:
            fallthrough
            
        case APIV2Constants.escapedEndOfPacket:
            fallthrough
            
        case APIV2Constants.escapedEscape:
            if isEscaped {
                byteCopy = byte | APIV2Constants.escapeMask
                isEscaped = false
            }
            break
            
        default:
            break
        }
        
        if isEscaped {
            print("escaped when I shouldnt be!")
            reset()
            return
        }
        
        currentData.append(byteCopy)
        checksum =  checksum &+ byteCopy
    }
    
    
    private func reset() {
        parsingState = .waitingForStartOfPacket
        isEscaped = false
        currentData.removeAll()
    }
    
    public func data(from command: CommandV2) -> Data {
        var bytes = [UInt8]()
        bytes.append(APIV2Constants.startOfPacket)
        
        var checksum: UInt8 = 0x00
        encodeBytes(&bytes, byte: command.commandFlags.rawValue)
        checksum += command.commandFlags.rawValue
        
        encodeBytes(&bytes, byte: command.deviceId)
        checksum += command.deviceId
        
        encodeBytes(&bytes, byte: command.commandId)
        checksum += command.commandId
        
        let sequenceNumber = getNextSequenceNumber()
        encodeBytes(&bytes, byte: sequenceNumber)
        checksum = checksum &+ sequenceNumber
        
        if let commandPayload = command.payload {
            let dataBytes = [UInt8](commandPayload)
            for byte in dataBytes {
                encodeBytes(&bytes, byte: byte)
                checksum = checksum &+ byte
            }
        }
        
        checksum = ~checksum
        encodeBytes(&bytes, byte: checksum)
        bytes.append(APIV2Constants.endOfPacket)
        
        return Data(bytes)
    }
}

public protocol CommandResponseV2 {}

public struct CommandV2Flags: OptionSet {
    public let rawValue: UInt8
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    static let isResponse = CommandV2Flags(rawValue: 1 << 0)
    static let requestsResponse = CommandV2Flags(rawValue: 1 << 1)
    static let requestsOnlyErrorResponse = CommandV2Flags(rawValue: 1 << 2)
    static let resetsInactivityTimeout = CommandV2Flags(rawValue: 1 << 3)
    static let commandHasTargetId = CommandV2Flags(rawValue: 1 << 4)
    static let commandHasSourceId = CommandV2Flags(rawValue: 1 << 5)
    
    static let defaultFlags: CommandV2Flags = [.requestsResponse, .resetsInactivityTimeout]
}

public struct APIV2Constants {
    static let escape: UInt8 = 0xAB
    static let startOfPacket: UInt8 = 0x8D
    static let endOfPacket: UInt8 = 0xD8
    
    static let escapeMask: UInt8 = 0x88
    static let escapedEscape = APIV2Constants.escape & ~APIV2Constants.escapeMask
    static let escapedStartOfPacket = APIV2Constants.startOfPacket & ~APIV2Constants.escapeMask
    static let escapedEndOfPacket = APIV2Constants.endOfPacket & ~APIV2Constants.escapeMask
}

extension CommandSequencerV2 {
    public func encodeBytes(_ data: inout [UInt8], byte: UInt8) {
        switch byte {
        case APIV2Constants.startOfPacket:
            data.append(APIV2Constants.escape)
            data.append(APIV2Constants.escapedStartOfPacket)
            
        case APIV2Constants.endOfPacket:
            data.append(APIV2Constants.escape)
            data.append(APIV2Constants.escapedEndOfPacket)
            
        case APIV2Constants.escape:
            data.append(APIV2Constants.escape)
            data.append(APIV2Constants.escapedEscape)
            
        default:
            data.append(byte)
        }
    }
}

public class CommandSequencerV21: CommandSequencerV2 {
    override public func data(from command: CommandV2) -> Data {
        var bytes = [UInt8]()
        
        bytes.append(APIV2Constants.startOfPacket)
        
        var checksum: UInt8 = 0x00

        var flags = command.commandFlags;
        if (command.targetId != nil) {
            flags.insert(.commandHasTargetId)
        }
        
        encodeBytes(&bytes, byte: flags.rawValue)
        checksum += flags.rawValue
        
        if let targetId = command.targetId, flags.contains(.commandHasTargetId) {
            encodeBytes(&bytes, byte: targetId)
            checksum += targetId
        }
        
        encodeBytes(&bytes, byte: command.deviceId)
        checksum += command.deviceId
        
        encodeBytes(&bytes, byte: command.commandId)
        checksum += command.commandId
        
        let sequenceNumber = getNextSequenceNumber()
        encodeBytes(&bytes, byte: sequenceNumber)
        checksum = checksum &+ sequenceNumber
        
        if let commandPayload = command.payload {
            let dataBytes = [UInt8](commandPayload)
            for byte in dataBytes {
                encodeBytes(&bytes, byte: byte)
                checksum = checksum &+ byte
            }
        }
        
        checksum = ~checksum
        encodeBytes(&bytes, byte: checksum)
        bytes.append(APIV2Constants.endOfPacket)
        
        return Data(bytes)
    }
}
