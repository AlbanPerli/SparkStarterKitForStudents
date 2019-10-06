//
//  CollisionData.swift
//  SpheroSDK
//
//  Created by Anthony Blackman on 2017-03-13.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation


public struct CollisionConfiguration {
    public enum DetectionMethod: UInt8 {
        case off = 0
        case simple = 1
        case filtered = 2
        case hybrid = 3
    }
    
    public var detectionMethod: DetectionMethod
    public var xThreshold: UInt8
    public var xSpeedThreshold: UInt8
    public var yThreshold: UInt8
    public var ySpeedThreshold: UInt8
    public var postTimeDeadZone: TimeInterval
    
    public init(
        detectionMethod: DetectionMethod,
        xThreshold: UInt8,
        xSpeedThreshold: UInt8,
        yThreshold: UInt8,
        ySpeedThreshold: UInt8,
        postTimeDeadZone: TimeInterval
        ) {
        self.detectionMethod = detectionMethod
        self.xThreshold = xThreshold
        self.xSpeedThreshold = xSpeedThreshold
        self.yThreshold = yThreshold
        self.ySpeedThreshold = ySpeedThreshold
        self.postTimeDeadZone = postTimeDeadZone
    }
    
    public init(
        detectionMethod: DetectionMethod,
        xThreshold: Double,
        xSpeedThreshold: Double,
        yThreshold: Double,
        ySpeedThreshold: Double,
        postTimeDeadZone: TimeInterval
        ) {
        self.init(
            detectionMethod: detectionMethod,
            xThreshold: UInt8(xThreshold.clamp(lowerBound: 0.0, upperBound: 255.0)),
            xSpeedThreshold: UInt8(xSpeedThreshold.clamp(lowerBound: 0.0, upperBound: 255.0)),
            yThreshold: UInt8(yThreshold.clamp(lowerBound: 0.0, upperBound: 255.0)),
            ySpeedThreshold: UInt8(ySpeedThreshold.clamp(lowerBound: 0.0, upperBound: 255.0)),
            postTimeDeadZone: postTimeDeadZone
        )
    }
    
    public static var enabled: CollisionConfiguration {
        get {
            return CollisionConfiguration(
                detectionMethod: .simple,
                xThreshold: 90.0,
                xSpeedThreshold: 130.0,
                yThreshold: 90.0,
                ySpeedThreshold: 130.0,
                postTimeDeadZone: 1.0
            )
        }
    }
    
    public static var disabled: CollisionConfiguration {
        get {
            return CollisionConfiguration(
                detectionMethod: .off,
                xThreshold: 0.0,
                xSpeedThreshold: 0.0,
                yThreshold: 0.0,
                ySpeedThreshold: 0.0,
                postTimeDeadZone: 0.0
            )
        }
    }
}

public struct CollisionAcceleration {
    public var x: Double
    public var y: Double
    public var z: Double
}

public struct CollisionAxis {
    public var x: Bool
    public var y: Bool
}

public struct CollisionPower {
    public var x: Double
    public var y: Double
    public var z: Double?
}

private func accelerometerDataToGs(bytes: ArraySlice<UInt8>) -> Double {
    let intData = intFromBytes(bytes: bytes)
    
    return Double(Int16(truncatingIfNeeded: intData)) / 4096.0
}

private func intFromBytes(bytes: ArraySlice<UInt8>) -> Int {
    var result = 0
    for byte in bytes {
        result *= 256
        result += Int(byte)
    }
    
    return result
}

public protocol CollisionData {
    
    var impactAcceleration: CollisionAcceleration { get set }
    var impactAxis: CollisionAxis { get set }
    var impactPower: CollisionPower { get set }
    var impactSpeed: Double { get set }
    var timestamp: TimeInterval { get set }
    var impactAngle: Double { get }
    
    init(impactAcceleration: CollisionAcceleration, impactAxis: CollisionAxis, impactPower: CollisionPower, impactSpeed: Double, timestamp: TimeInterval)
    
}

extension CollisionData {
    
    public var impactAngle: Double {
        get {
            let angleRadians = atan2(-impactAcceleration.x, -impactAcceleration.y)
            let angleDegrees = angleRadians * 180.0 / .pi
            
            return angleDegrees
        }
    }
    
}

public struct CollisionDataCommandResponseV1: AsyncCommandResponse, CollisionData {
    public var impactAcceleration: CollisionAcceleration
    public var impactAxis: CollisionAxis
    public var impactPower: CollisionPower
    public var impactSpeed: Double
    public var timestamp: TimeInterval
    public var dataLength = 16
    
    public init(impactAcceleration: CollisionAcceleration, impactAxis: CollisionAxis, impactPower: CollisionPower, impactSpeed: Double, timestamp: TimeInterval) {
        self.impactAcceleration = impactAcceleration
        self.impactAxis = impactAxis
        self.impactPower = impactPower
        self.impactSpeed = impactSpeed
        self.timestamp = timestamp
    }

    public init?(data: [UInt8]) {
        if data.count == dataLength {
            let impactAccelX = accelerometerDataToGs(bytes: data[0...1])
            let impactAccelY = accelerometerDataToGs(bytes: data[2...3])
            let impactAccelZ = accelerometerDataToGs(bytes: data[4...5])
            
            self.impactAcceleration = CollisionAcceleration(x: impactAccelX, y: impactAccelY, z: impactAccelZ)
            
            let impactMask = data[6]
            let impactAxisX = impactMask & 0x01 != 0
            let impactAxisY = impactMask & 0x02 != 0
            
            self.impactAxis = CollisionAxis(x: impactAxisX, y: impactAxisY)
            
            let impactPowerX = Double(intFromBytes(bytes: data[7...8]))
            let impactPowerY = Double(intFromBytes(bytes: data[9...10]))
            self.impactPower = CollisionPower(x: impactPowerX, y: impactPowerY, z: nil)
            
            self.impactSpeed = Double(data[11]) / 255.0
            
            self.timestamp = (Date().timeIntervalSince1970)
        } else {
            return nil
        }
    }
    
}

public struct CollisionDataCommandResponseV2: CommandResponseV2, CollisionData {
    public var impactAcceleration: CollisionAcceleration
    public var impactAxis: CollisionAxis
    public var impactPower: CollisionPower
    public var impactSpeed: Double
    public var timestamp: TimeInterval
    public var dataLength = 16
    
    public init(impactAcceleration: CollisionAcceleration, impactAxis: CollisionAxis, impactPower: CollisionPower, impactSpeed: Double, timestamp: TimeInterval) {
        self.impactAcceleration = impactAcceleration
        self.impactAxis = impactAxis
        self.impactPower = impactPower
        self.impactSpeed = impactSpeed
        self.timestamp = timestamp
    }
    
    public init?(data: [UInt8]) {
        if data.count >= dataLength {
            let impactAccelX = accelerometerDataToGs(bytes: data[0...1])
            let impactAccelY = accelerometerDataToGs(bytes: data[2...3])
            let impactAccelZ = accelerometerDataToGs(bytes: data[4...5])
            
            self.impactAcceleration = CollisionAcceleration(x: impactAccelX, y: impactAccelY, z: impactAccelZ)
            
            let impactMask = data[6]
            let impactAxisX = impactMask & 0x01 != 0
            let impactAxisY = impactMask & 0x02 != 0
            
            self.impactAxis = CollisionAxis(x: impactAxisX, y: impactAxisY)
            
            let impactPowerX = Double(intFromBytes(bytes: data[7...8]))
            let impactPowerY = Double(intFromBytes(bytes: data[9...10]))
            let impactPowerZ = Double(intFromBytes(bytes: data[11...12]))
            self.impactPower = CollisionPower(x: impactPowerX, y: impactPowerY, z: impactPowerZ)
            
            self.impactSpeed = Double(data[13]) / 255.0
            
            self.timestamp = (Date().timeIntervalSince1970)
        } else {
            return nil
        }
    }
}

typealias CollisionDataCommandResponse = CollisionDataCommandResponseV1
