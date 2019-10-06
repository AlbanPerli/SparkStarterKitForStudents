//
//  Command.swift
//  Sphero.playgroundbook
//
//  Copyright © 2016 Apple Inc. All rights reserved.
//

import Foundation
import UIKit

public protocol CommandV1 {
    var answer: Bool { get }
    var resetTimeout: Bool { get }
    var payload: Data? { get }
    var deviceId: CommandDeviceId { get }
    var commandId: UInt8 { get }
}

extension CommandV1 {
    public var answer: Bool {
        return true
    }
    
    public var resetTimeout: Bool {
        return true
    }
    
    public var sop2: UInt8 {
        var value: UInt8 = 0b11111100
        if answer {
            value |= 1 << 0
        }
        if resetTimeout {
            value |= 1 << 1
        }
        
        return value
    }
}

public enum CommandDeviceId: UInt8 {
    case coreCommandDeviceId = 0x00
    case spheroCommandDeviceId = 0x02
}

public protocol CoreCommandV1: CommandV1 { }

extension CoreCommandV1 {
    public var deviceId: CommandDeviceId {
        return CommandDeviceId.coreCommandDeviceId
    }
    
    static public func response(responseId:UInt8, sequenceNumber: UInt8 = 0) -> Data {
        var bytes: [UInt8] = [0xff, 0xff, 0x00, sequenceNumber, responseId]
        
        let checksumTarget = bytes[2 ..< bytes.count]
        var checksum: UInt8 = 0
        for byte in checksumTarget {
            checksum = checksum &+ byte
        }
        checksum = ~checksum
        bytes.append(checksum)
        
        return Data(bytes: bytes)
    }
}

public protocol SpheroCommandV1: CommandV1 {}

extension SpheroCommandV1 {
    public var deviceId: CommandDeviceId {
        return CommandDeviceId.spheroCommandDeviceId
    }
}

public struct PingCommand: CoreCommandV1 {
    public let commandId: UInt8 = CoreCommandId.ping.rawValue
    public let payload: Data? = nil
}

public struct PingCommandResponse: DeviceCommandResponse {}

public struct VersioningCommand: CoreCommandV1 {
    public let commandId: UInt8 = CoreCommandId.versioning.rawValue

    public var payload: Data? {
        return nil
    }
}

public struct GoToSleepCommand: CoreCommandV1 {
    public let commandId: UInt8 = CoreCommandId.goToSleep.rawValue
    
    public enum SleepType: UInt8 {
        case sleep = 0x00
        case sleepDeep = 0x01
        case sleepLowPower = 0x02
    }
    
    public let type: SleepType
    public init(type: SleepType) {
        self.type = type
    }
    
    public var payload: Data? {
        switch type {
        case .sleep:
            return Data(bytes: [0, 0, 0, 0, 0])
            
        default:
            fatalError("SleepType \(type) is not supported!")
        }
    }
}

public struct SleepWarningResponse: AsyncCommandResponse {}
public struct DidSleepResponse: AsyncCommandResponse {}

public struct PowerStateCommand: CoreCommandV1 {
    public var commandId: UInt8 = CoreCommandId.powerState.rawValue
    
    public var payload: Data? {
        return nil
    }
}

public struct UpdateHeadingCommand: SpheroCommandV1 {
    public let commandId: UInt8 = SpheroCommandId.setHeading.rawValue
    
    public let heading: UInt16
    public init(heading: UInt16) {
        self.heading = heading
    }
    
    public var queueable: Bool {
        return false
    }
    
    public var payload: Data? {
        let clampedHeading = (heading % 360)
        let headingLeft = UInt8((clampedHeading >> 8) & 0xff)
        let headingRight = UInt8(clampedHeading & 0xff)
        
        return Data(bytes: [headingLeft, headingRight])
    }
}

public struct SetMainLEDColor: SpheroCommandV1 {
    public let commandId: UInt8 = SpheroCommandId.rgbLedOutput.rawValue
    
    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8
    public var save: Bool
    
    public init(red: UInt8, green: UInt8, blue: UInt8, save: Bool = false) {
        self.red = red
        self.green = green
        self.blue = blue
        self.save = save
    }
    
    public init(color: UIColor, save: Bool = false) {
        var redComponent: CGFloat = 0
        var greenComponent: CGFloat = 0
        var blueComponent: CGFloat = 0
        
        if color.getRed(&redComponent, green: &greenComponent, blue: &blueComponent, alpha: nil) {
            self.red = UInt8(0xff * redComponent)
            self.green = UInt8(0xff * greenComponent)
            self.blue = UInt8(0xff * blueComponent)
        } else {
            fatalError("Passed in color cannot be converted to RGB space!")
        }
        self.save = save
    }
    
    public var payload: Data? {
        let data = Data(bytes: [red, green, blue, save ? 1 : 0])
        return data
    }
}

public struct SetBackLEDBrightness: SpheroCommandV1 {
    public let commandId: UInt8 = SpheroCommandId.backLedOutput.rawValue
    
    public let brightness: UInt8
    
    public init(brightness: UInt8) {
        self.brightness = brightness
    }
    
    public var payload: Data? {
        let data = Data(bytes: [brightness])
        return data
    }
}

public struct SetStabilization: SpheroCommandV1 {
    public enum State: UInt8 {
        case off = 0
        case on = 1
        case onNoReset = 2
    }
    
    public let commandId: UInt8 = SpheroCommandId.stabilization.rawValue
    
    public let state: State
    
    public init(state: State) {
        self.state = state
    }
    
    public var payload: Data? {
        let data = Data(bytes:[state.rawValue])
        return data
    }
}

public struct ConfigureCollisionDetection: SpheroCommandV1 {
    
    public let commandId: UInt8 = SpheroCommandId.configureCollisionDetection.rawValue
    
    public let configuration: CollisionConfiguration
    
    init(configuration: CollisionConfiguration) {
        self.configuration = configuration
    }
    
    public var payload: Data? {
        var scaledDeadZone = configuration.postTimeDeadZone * 100
        scaledDeadZone = max(0, scaledDeadZone)
        scaledDeadZone = min(255, scaledDeadZone)
        let deadZoneByte = UInt8(scaledDeadZone)
        
        let bytes = [
            configuration.detectionMethod.rawValue,
            configuration.xThreshold,
            configuration.xSpeedThreshold,
            configuration.yThreshold,
            configuration.ySpeedThreshold,
            deadZoneByte
        ]
        
        return Data(bytes: bytes)
    }
}

public struct RawMotor: SpheroCommandV1 {
    public let commandId: UInt8 = SpheroCommandId.rawMotorValues.rawValue
    
    public enum RawMotorMode: UInt8 {
        case off = 0
        case forward = 1
        case reverse = 2
    }
    
    public let leftMotorPower: UInt8
    public let rightMotorPower: UInt8
    public let leftMotorMode: RawMotorMode
    public let rightMotorMode: RawMotorMode
    
    public init(leftMotorPower: UInt8, leftMotorMode: RawMotorMode, rightMotorPower: UInt8, rightMotorMode: RawMotorMode) {
        self.leftMotorMode = leftMotorMode
        self.leftMotorPower = leftMotorPower
        
        self.rightMotorMode = rightMotorMode
        self.rightMotorPower = rightMotorPower
    }
    
    public var payload: Data? {
        return Data(bytes: [
                self.leftMotorMode.rawValue,
                self.leftMotorPower,
                self.rightMotorMode.rawValue,
                self.rightMotorPower
            ])
    }
}

public struct Roll: SpheroCommandV1 {
    public enum RollType: UInt8 {
        case stop = 0
        case roll = 1
        case calibrate = 2
    }
    
    public enum RollDirection: UInt8 {
        case forward = 0
        case reverse = 1
    }
    
    public let commandId: UInt8 = SpheroCommandId.roll.rawValue
    
    public let speed: UInt8
    public let heading: UInt16
    public let state: RollType
    public let direction: RollDirection
    
    public init(heading: UInt16, speed: UInt8, state: RollType = .roll, direction: RollDirection = .forward) {
        self.heading = heading
        self.speed = speed
        self.state = state
        self.direction = direction
    }
    
    public var payload: Data? {
        let clampedHeading = (heading % 360)
        let headingLeft = UInt8((clampedHeading >> 8) & 0xff)
        let headingRight = UInt8(clampedHeading & 0xff)
        
        return Data(bytes: [speed, headingLeft, headingRight, state.rawValue, direction.rawValue])
    }
}

public enum CoreCommandId: UInt8 {
    case ping = 0x01
    case versioning = 0x02
    case goToSleep = 0x22
    case powerState = 0x20
}

public struct EnableSensors: SpheroCommandV1 {
    public let commandId: UInt8 = SpheroCommandId.setDataStreaming.rawValue
    
    public let streamingRate: Int
    public let streamingSensors: SensorMaskV1
    
    private var nativeStreamingRate = 400
    private var packetFrames: UInt16 = 1
    
    public init(sensorMask: SensorMaskV1, streamingRate: Int) {
        self.streamingSensors = sensorMask
        self.streamingRate = streamingRate
        
        StreamingDataTrackerV1.sensorMask = sensorMask
    }
    
    public var payload: Data? {
        let divisor = streamingRate > 0 ? UInt16(nativeStreamingRate / streamingRate) : 1
        let sensorRawValue = streamingSensors.rawValue
        
        var bytes = [UInt8]()
        bytes.append(UInt8((divisor >> 8) & 0xff))
        bytes.append(UInt8(divisor & 0xff))
        bytes.append(UInt8((packetFrames >> 8) & 0xff))
        bytes.append(UInt8(packetFrames & 0xff))
        bytes.append(UInt8((sensorRawValue >> 24) & 0xff))
        bytes.append(UInt8((sensorRawValue >> 16) & 0xff))
        bytes.append(UInt8((sensorRawValue >> 8) & 0xff))
        bytes.append(UInt8(sensorRawValue & 0xff))
        bytes.append(0)
        bytes.append(UInt8((sensorRawValue >> 56) & 0xff))
        bytes.append(UInt8((sensorRawValue >> 48) & 0xff))
        bytes.append(UInt8((sensorRawValue >> 40) & 0xff))
        bytes.append(UInt8((sensorRawValue >> 32) & 0xff))
        
        return Data(bytes: bytes)
    }
}

public struct ConfigureLocatorCommand: SpheroCommandV1 {
    public let commandId: UInt8 = SpheroCommandId.configureLocator.rawValue
    public let locatorFlag: LocatorCalibrateFlag
    public let x: UInt16
    public let y: UInt16
    public let yaw: UInt16
    
    public enum LocatorCalibrateFlag: UInt8 {
        case RotateWithCalibrateOff = 0x00
        case RotateWithCalibrateOn = 0x01
    }
    
    public init(newX: UInt16, newY: UInt16, newYaw: UInt16, locatorConfigureFlag: LocatorCalibrateFlag = .RotateWithCalibrateOn) {
        x = newX
        y = newY
        yaw = newYaw
        locatorFlag = locatorConfigureFlag
    }
    
    public var payload: Data? {
        return Data(bytes: [locatorFlag.rawValue,
                            UInt8(x >> 8),
                            UInt8(x),
                            UInt8(y >> 8),
                            UInt8(y),
                            UInt8(yaw >> 8),
                            UInt8(yaw)])
    }
}

public struct ToyOptionsMask: OptionSet {
    public let rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    static let PreventSleepInCharger = ToyOptionsMask(rawValue: 1)
    static let EnableVectorDrive = ToyOptionsMask(rawValue: 2)
    static let DisableSelfLevelInCharger = ToyOptionsMask(rawValue: 2 << 1)
    static let TailLightAlwaysOn = ToyOptionsMask(rawValue: 2 << 2)
    static let EnableMotionTimeout = ToyOptionsMask(rawValue: 2 << 3)
}

public struct SetOptionsFlagsCommand: SpheroCommandV1 {
    public let commandId: UInt8 = SpheroCommandId.setOptionFlags.rawValue
    
    public let optionsMask: ToyOptionsMask
    
    public init(options: ToyOptionsMask) {
        self.optionsMask = options
    }
    
    public var payload: Data? {
        let optionsRawValue = optionsMask.rawValue
        
        var bytes = [UInt8]()
        bytes.append(UInt8((optionsRawValue >> 24) & 0xff))
        bytes.append(UInt8((optionsRawValue >> 16) & 0xff))
        bytes.append(UInt8((optionsRawValue >> 8) & 0xff))
        bytes.append(UInt8(optionsRawValue & 0xff))
        
        return Data(bytes:bytes)
    }
}

public enum SpheroCommandId: UInt8 {
    case setHeading = 0x01
    case stabilization = 0x02
    case rotationRate = 0x03
    case setDataStreaming = 0x11
    case configureCollisionDetection = 0x12
    case configureLocator = 0x13
    case getTemperature = 0x16
    case rgbLedOutput = 0x20
    case backLedOutput = 0x21
    case getUserRgbLedColor = 0x22
    case roll = 0x30
    case rawMotorValues = 0x33
    case setMotionTimeout = 0x34
    case setOptionFlags = 0x35
    case getOptionFlags = 0x36
    case setNonPersistentOptionFlags = 0x37
    case getNonPersistentOptionFlags = 0x38
}
