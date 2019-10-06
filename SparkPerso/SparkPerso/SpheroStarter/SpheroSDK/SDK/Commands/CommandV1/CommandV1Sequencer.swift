//
//  CommandResponseParser.swift
//  SpheroSDK
//
//  Created by Jeff Payan on 2017-03-17.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation

public enum ToyAsyncResponseCode: UInt8 {
    case sensorDataStreaming = 0x03
    case configBlockContents = 0x04
    case preSleepWarning = 0x05
    case didSleep = 0x14
    case collisionDetected = 0x07
}

public protocol CommandResponseV1 {}

public protocol AsyncCommandResponse: CommandResponseV1 {}
public protocol DeviceCommandResponse: CommandResponseV1 {}

private protocol ResponseParser {
    func parseData(_ data: Data, responseId: UInt8, deviceId: CommandDeviceId) -> CommandResponseV1?
}

private struct AsyncCommandResponseParser: ResponseParser {
    func parseData(_ data: Data, responseId: UInt8, deviceId: CommandDeviceId = .spheroCommandDeviceId) -> CommandResponseV1? {
        var choppedData = data
        //remove checksum
        choppedData.removeLast()
        
        if let responseCode = ToyAsyncResponseCode(rawValue: responseId) {
            switch responseCode {
            case .sensorDataStreaming:
                return SensorDataCommandResponse(data: choppedData)
            case .collisionDetected:
                return CollisionDataCommandResponseV1(data: Array(choppedData))
            case .preSleepWarning:
                return SleepWarningResponse()
            case .didSleep:
                return DidSleepResponse()

            default:
                return nil
            }
        }
        
        return nil
    }
}

private struct DeviceCommandResponseParser: ResponseParser {
    func parseData(_ data: Data, responseId: UInt8, deviceId: CommandDeviceId) -> CommandResponseV1? {
        var choppedData = data
        //remove checksum
        choppedData.removeLast()
        
        switch deviceId {
        case .coreCommandDeviceId:
            if let commandId = CoreCommandId(rawValue: responseId) {
                switch commandId {
                case .ping:
                    return PingCommandResponse()
                    
                case .versioning:
                    return VersionsCommandResponse(data)
                
                case .powerState:
                    return PowerStateResponse(data)
                    
                default:
                    break
                }
            }
            
        case .spheroCommandDeviceId:
            //we dont have any of these yet
            break
        }
        
        return nil
    }
}

public enum CommandResponseType:UInt8 {
    case DeviceResponse = 0xFF
    case AsyncResponse = 0xFE
}

public final class CommandSequencerV1 {
    private enum ParsingState {
        case waitingForStartOfPacket
        case waitingForFlags
        case waitingForResponseStatus
        case waitingForSequenceNumber
        case waitingForResponseLength
        case waitingForAsyncResponseId
        case waitingForAsyncLengthBigByte
        case waitingForAsyncResponseLittleByte
        case waitingForEndOfPacket
    }
    
    private struct CurrentResponse {
        var payload: [UInt8] = []
        var length: UInt16 = 0
        var flags: CommandResponseType = .DeviceResponse
        var responseStatus: UInt8?
        var sequenceNumber: UInt8?
        var responseId: UInt8?
    }
    
    typealias ParserCallback = ((_ sequencer: CommandSequencerV1, _ response: CommandResponseV1?) -> Void)?
    
    fileprivate var commandSequenceNumber: UInt8 = 0
    fileprivate func getNextSequenceNumber() -> UInt8 {
        commandSequenceNumber = commandSequenceNumber &+ 1
        return commandSequenceNumber
    }
    
    fileprivate var commandSequence: [UInt8 : CommandV1] = [:]
    
    private var parser: ResponseParser?
    private var parsingState = ParsingState.waitingForStartOfPacket
    private var response = CurrentResponse()
    
    func parseResponseFromToy(_ data: Data, callback: ParserCallback) {
        for byte in [UInt8](data) {
            switch parsingState {
            case .waitingForStartOfPacket:
                if byte == 0xff {
                    parsingState = .waitingForFlags
                }
                
            case .waitingForFlags:
                if byte == CommandResponseType.DeviceResponse.rawValue {
                    parsingState = .waitingForResponseStatus
                    response.flags = .DeviceResponse
                } else if byte == CommandResponseType.AsyncResponse.rawValue {
                    parsingState = .waitingForAsyncResponseId
                    response.flags = .AsyncResponse
                }
                
            case .waitingForResponseStatus:
                response.responseStatus = byte
                parsingState = .waitingForSequenceNumber
                
            case .waitingForSequenceNumber:
                response.sequenceNumber = byte
                parsingState = .waitingForResponseLength
                
            case .waitingForResponseLength:
                response.length = UInt16(byte)
                parsingState = .waitingForEndOfPacket
                
            case .waitingForAsyncResponseId:
                response.responseId = byte
                parsingState = .waitingForAsyncLengthBigByte
                
            case .waitingForAsyncLengthBigByte:
                response.length = UInt16(byte) << 8
                parsingState = .waitingForAsyncResponseLittleByte
                
            case .waitingForAsyncResponseLittleByte:
                response.length = response.length | UInt16(byte)
                parsingState = .waitingForEndOfPacket
                
            case .waitingForEndOfPacket:
                response.payload.append(byte)
                if response.payload.count >= Int(response.length) {
                    let data = Data(bytes: response.payload)

                    switch response.flags {
                    case .AsyncResponse:
                        let asyncCommandParser = AsyncCommandResponseParser()
                        if let responseId = response.responseId {

                            let commandResponse = asyncCommandParser.parseData(data, responseId: responseId)
                            callback?(self, commandResponse)
                            parsingState = .waitingForStartOfPacket
                            response = CurrentResponse()
                        }
                        
                    case .DeviceResponse:
                        if let sequenceNumber = response.sequenceNumber, let currentCommand = commandSequence[sequenceNumber] {

                            let deviceParser = DeviceCommandResponseParser()
                            let commandResponse = deviceParser.parseData(data, responseId: currentCommand.commandId, deviceId: currentCommand.deviceId)
                            
                            callback?(self, commandResponse)
                            parsingState = .waitingForStartOfPacket
                            response = CurrentResponse()
                        }
                    }
                }
            }
        }
    }
}

extension CommandSequencerV1 {
    public func data(from command: CommandV1) -> Data {
        let payloadLength = command.payload?.count ?? 0
        let sequenceNumber = getNextSequenceNumber()
        var zero: UInt8 = 0
        var data = Data(bytes: &zero, count: 6)
        
        data[0] = 0b11111111
        data[1] = command.sop2
        data[2] = command.deviceId.rawValue
        data[3] = command.commandId
        data[4] = sequenceNumber
        data[5] = UInt8(payloadLength + 1)
        
        if let payload = command.payload {
            data.append(payload)
        }
        
        let checksumTarget = data[2 ..< data.count]
        
        var checksum: UInt8 = 0
        for byte in checksumTarget {
            checksum = checksum &+ byte
        }
        checksum = ~checksum
        
        data.append(Data(bytes: [checksum]))
        
        if command.answer {
            commandSequence[sequenceNumber] = command
        }
        
        return data
    }
}
