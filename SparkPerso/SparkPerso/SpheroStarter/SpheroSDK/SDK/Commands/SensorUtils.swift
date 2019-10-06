//
//  SensorUtils.swift
//  PlaygroundContent
//
//  Created by Jeff Payan on 2017-08-01.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import GLKit

public struct SensorControlDefaults {
    static let intervalToHz = 1000
    static let interval = 250
}

public protocol SensorControlData {
    var locator: LocatorSensorData? { get }
    var orientation: AttitudeSensorData? { get }
    var gyro: GyroscopeSensorData? { get }
    var accelerometer: AccelerometerSensorData? { get }
    var verticalAcceleration: Double? { get }
    var rotationMatrix: GLKMatrix3? { get }
}

public class FreefallLandingDetector {
    fileprivate var freeFallVerticalAccelerationThreshold: Double = 0.1
    fileprivate var freeFallTimeThreshold: TimeInterval = 0.2
    fileprivate var isInFreeFall = false
    fileprivate var lastLandedTime: TimeInterval?
    
    var onFreefallDetected: (() -> Void)?
    var onLandingDetected: (() -> Void)?
    
    func checkFreefallStatus(sensorData data: SensorControlData) {
        guard let verticalAcceleration = data.verticalAcceleration else { return }
        let isFreeFall = abs(verticalAcceleration) < freeFallVerticalAccelerationThreshold
        let now = Date().timeIntervalSince1970
        
        if isFreeFall {
            if let lastLandedTime = lastLandedTime {
                if !isInFreeFall && now - lastLandedTime > freeFallTimeThreshold {
                    isInFreeFall = true
                    onFreefallDetected?()
                }
            } else {
                // We've just started reading sensor data while in free fall.
                // Don't create a FreeFall event until this fall is over.
                isInFreeFall = true
            }
        } else {
            if isInFreeFall {
                onLandingDetected?()
            }
            
            isInFreeFall = false
            lastLandedTime = now
        }
    }
}

extension SignedInteger {
    init?(_ bytes: [UInt8]) {
        guard bytes.count == MemoryLayout<Self>.size else { return nil }
        self = bytes.withUnsafeBytes {
            return $0.load(fromByteOffset: 0, as: Self.self)
        }
    }
}

extension FloatingPoint {
    init?(_ bytes: [UInt8]) {
        guard bytes.count == MemoryLayout<Self>.size else { return nil }
        self = bytes.withUnsafeBytes {
            return $0.load(fromByteOffset: 0, as: Self.self)
        }
    }
}

public typealias SensorData = SensorControlData
