//
//  SensorControlV1.swift
//  SpheroSDK
//
//  Created by Jeff Payan on 2017-03-14.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation

public struct SensorMaskV1: OptionSet {
    public let rawValue: UInt64
    
    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
    
    public static let off = SensorMaskV1(rawValue: 0)
    public static let gyroZFiltered = SensorMaskV1(rawValue: 1 << 10)
    public static let gyroYFiltered = SensorMaskV1(rawValue: 1 << 11)
    public static let gyroXFiltered = SensorMaskV1(rawValue: 1 << 12)
    public static let accelerometerZFiltered = SensorMaskV1(rawValue: 1 << 13)
    public static let accelerometerYFiltered = SensorMaskV1(rawValue: 1 << 14)
    public static let accelerometerXFiltered = SensorMaskV1(rawValue: 1 << 15)
    public static let imuYawAngleFiltered = SensorMaskV1(rawValue: 1 << 16)
    public static let imuRollAngleFiltered = SensorMaskV1(rawValue: 1 << 17)
    public static let imuPitchAngleFiltered = SensorMaskV1(rawValue: 1 << 18)
    public static let gyroZRaw = SensorMaskV1(rawValue: 1 << 22)
    public static let gyroYRaw = SensorMaskV1(rawValue: 1 << 23)
    public static let gyroXRaw = SensorMaskV1(rawValue: 1 << 24)
    public static let accelerometerZRaw = SensorMaskV1(rawValue: 1 << 25)
    public static let accelerometerYRaw = SensorMaskV1(rawValue: 1 << 26)
    public static let accelerometerXRaw = SensorMaskV1(rawValue: 1 << 27)
    public static let locatorX = SensorMaskV1(rawValue: 1 << 59)
    public static let locatorY = SensorMaskV1(rawValue: 1 << 58)
    public static let velocityX = SensorMaskV1(rawValue: 1 << 56)
    public static let velocityY = SensorMaskV1(rawValue: 1 << 55)
    public static let accelerometerRaw =  SensorMaskV1(rawValue: accelerometerZRaw.rawValue | accelerometerYRaw.rawValue | accelerometerXRaw.rawValue)
    public static let gyroFilteredAll = SensorMaskV1(rawValue: gyroZFiltered.rawValue | gyroYFiltered.rawValue | gyroXFiltered.rawValue)
    public static let imuAnglesFilteredAll = SensorMaskV1(rawValue: imuYawAngleFiltered.rawValue | imuRollAngleFiltered.rawValue | imuPitchAngleFiltered.rawValue)
    public static let accelerometerFilteredAll = SensorMaskV1(rawValue: accelerometerZFiltered.rawValue | accelerometerYFiltered.rawValue | accelerometerXFiltered.rawValue)
    public static let locatorAll = SensorMaskV1(rawValue: locatorX.rawValue | locatorY.rawValue | velocityX.rawValue | velocityY.rawValue)
}

//V1 Sensor Control
class SensorControlV1: SensorControl {
    weak var toyCore: SpheroV1ToyCore?
    var interval: Int = SensorControlDefaults.interval
    
    var onDataReady: ((_ sensorData: SensorControlData) -> Void)?
    
    var onFreefallDetected: (() -> Void)? {
        //pipe this to our free fall detector
        get {
            return freefallDetector.onFreefallDetected
        }
        set {
            freefallDetector.onFreefallDetected = newValue
        }
    }
    
    var onLandingDetected: (() -> Void)? {
        //pipe this to our free fall detector
        get {
            return freefallDetector.onLandingDetected
        }
        set {
            freefallDetector.onLandingDetected = newValue
        }
    }

    fileprivate let freefallDetector = FreefallLandingDetector()
    
    public init(toyCore: SpheroV1ToyCore) {
        self.toyCore = toyCore
        self.toyCore?.addAsyncListener(self)
    }
    
    func enable(sensors sensorMask: SensorMask) {
        let intervalInSeconds = Double(interval) / Double(SensorControlDefaults.intervalToHz)
        let streamingRate = Int(1.0/intervalInSeconds)
        var v1SensorMask: SensorMaskV1 = []
        
        for sensorVal in sensorMask {
            switch sensorVal {
            case .locator:
                v1SensorMask.insert(.locatorAll)
                
            case .gyro:
                v1SensorMask.insert(.gyroFilteredAll)
                
            case .orientation:
                v1SensorMask.insert(.imuAnglesFilteredAll)

            case .accelerometer:
                v1SensorMask.insert(.accelerometerFilteredAll)

            case .off:
                v1SensorMask.insert(.off)
            }
        }
        
        toyCore?.send(EnableSensors(sensorMask: v1SensorMask, streamingRate: streamingRate))
    }
    
    func disable() {
        toyCore?.send(EnableSensors(sensorMask: [], streamingRate: 0))
    }
    
    func resetLocator() {
        toyCore?.send(ConfigureLocatorCommand(newX: 0, newY: 0, newYaw: 0))
    }
}

extension SensorControlV1: ToyCoreAsyncListener {
    func toyCore(_ toyCore: SpheroV1ToyCore, didReceiveAsyncResponse response: AsyncCommandResponse) {
        guard let sensorData = response as? SensorDataCommandResponse else { return }
        
        freefallDetector.checkFreefallStatus(sensorData: sensorData)
        onDataReady?(sensorData)
    }
    
    func toyCore(_ toyCore: SpheroV1ToyCore, didReceiveDeviceResponse response: DeviceCommandResponse) { }
    
}
