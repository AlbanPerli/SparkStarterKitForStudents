//
//  SensorData.swift
//  SpheroSDK
//
//  Created by Jeff Payan on 2017-03-10.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import GLKit

public struct TwoAxisSensorData<T> {
    public var x: T?
    public var y: T?
}

public struct ThreeAxisSensorData<T> {
    public var x: T?
    public var y: T?
    public var z: T?
}

public struct AccelerometerSensorData {
    public var filteredAcceleration: ThreeAxisSensorData<Double>?
    public var rawAcceleration: ThreeAxisSensorData<Int>?
}

public struct GyroscopeSensorData {
    public var rotationRate: ThreeAxisSensorData<Int>?
    public var rawRotation: ThreeAxisSensorData<Int>?
}

public struct AttitudeSensorData {
    public var yaw: Int?
    public var pitch: Int?
    public var roll: Int?
}

public struct LocatorSensorData {
    public var position: TwoAxisSensorData<Double>?
    public var velocity: TwoAxisSensorData<Double>?
}

fileprivate func valueFrom(data: Data, startLocation: Int) -> Int {
    let dataArray = [UInt8](data[startLocation..<startLocation+2])

    guard let intValue = Int16(dataArray.reversed()) else { return 0 }
    return Int(intValue)
}

public struct SensorDataCommandResponse: AsyncCommandResponse, SensorControlData {
    /// The (x, y) position and velocity.
    /// Position is the offset from the locator's origin, measured in centimeters.
    ///Velocity is measured in centimeters per second.
    private(set) public var locator: LocatorSensorData?
    /// The orientation on each axis (yaw, pitch and roll).
    /// Measured in degrees from -180° to 180°.
    private(set) public var orientation: AttitudeSensorData?
    /// The rotation rate around an axis (x, y, z).
    /// Measured in degrees per second from -2,000° to 2,000°.
    private(set) public var gyro: GyroscopeSensorData?
    /// The acceleration in 3 dimensions (x: right/left, y: forward/back, z: down/up).
    /// Measured in g-forces from -8 to 8 g's.
    private(set) public var accelerometer: AccelerometerSensorData?

    private let gravityFactor = 4096.0
    
    public init(data: Data) {
        var location = 0
        let sensorMask = StreamingDataTrackerV1.sensorMask!
        
        //if we have any of these
        if !sensorMask.isDisjoint(with: [.accelerometerXRaw, .accelerometerYRaw, .accelerometerZRaw]) {
            var rawAccel = ThreeAxisSensorData<Int>(x: nil, y: nil, z: nil)
            
            if sensorMask.contains(.accelerometerXRaw) {
                rawAccel.x = valueFrom(data: data, startLocation: location)
                location = location + 2
            }
            if sensorMask.contains(.accelerometerYRaw) {
                rawAccel.y = valueFrom(data: data, startLocation: location)
                location = location + 2
            }
            
            if sensorMask.contains(.accelerometerZRaw) {
                rawAccel.y = valueFrom(data: data, startLocation: location)
                location = location + 2
            }
            
            self.accelerometer = AccelerometerSensorData(filteredAcceleration: nil, rawAcceleration: rawAccel)
        }
        
        if !sensorMask.isDisjoint(with: [.gyroXRaw, .gyroYRaw, .gyroZRaw]) {
            var rawGyro = ThreeAxisSensorData<Int>(x: nil, y: nil, z: nil)
            let deciDegreesToDegrees = 10

            if sensorMask.contains(.gyroXRaw) {
                rawGyro.x = valueFrom(data: data, startLocation: location) / deciDegreesToDegrees
                location = location + 2
            }
            if sensorMask.contains(.gyroYRaw) {
                rawGyro.y = valueFrom(data: data, startLocation: location) / deciDegreesToDegrees
                location = location + 2
            }
            
            if sensorMask.contains(.gyroZRaw) {
                rawGyro.y = valueFrom(data: data, startLocation: location) / deciDegreesToDegrees
                location = location + 2
            }
            
            self.gyro = GyroscopeSensorData(rotationRate: nil, rawRotation: rawGyro)
        }
        
        if !sensorMask.isDisjoint(with: [.imuPitchAngleFiltered, .imuYawAngleFiltered, .imuRollAngleFiltered]) {
            var yaw, pitch, roll: Int?
            
            if sensorMask.contains(.imuPitchAngleFiltered) {
                pitch = valueFrom(data: data, startLocation: location)
                location = location + 2
            }
            
            if sensorMask.contains(.imuRollAngleFiltered) {
                roll = valueFrom(data: data, startLocation: location)
                location = location + 2
            }
            
            if sensorMask.contains(.imuYawAngleFiltered) {
                yaw = valueFrom(data: data, startLocation: location)
                location = location + 2
            }
            
            self.orientation = AttitudeSensorData(yaw: yaw, pitch: pitch, roll: roll)
        }
        
        if !sensorMask.isDisjoint(with: [.accelerometerXFiltered, .accelerometerYFiltered, .accelerometerZFiltered]) {
            var filteredX, filteredY, filteredZ: Double?
            if sensorMask.contains(.accelerometerXFiltered) {
                filteredX = Double(valueFrom(data: data, startLocation: location)) / gravityFactor
                location = location + 2
            }
            
            if sensorMask.contains(.accelerometerYFiltered) {
                filteredY = Double(valueFrom(data: data, startLocation: location)) / gravityFactor
                location = location + 2
            }
            
            if sensorMask.contains(.accelerometerZFiltered) {
                filteredZ = Double(valueFrom(data: data, startLocation: location)) / gravityFactor
                location = location + 2
            }
            
            let filteredAcceleration = ThreeAxisSensorData<Double>(x: filteredX, y: filteredY, z: filteredZ)
            if var accel = self.accelerometer {
                accel.filteredAcceleration = filteredAcceleration
            } else {
                self.accelerometer = AccelerometerSensorData(filteredAcceleration: filteredAcceleration , rawAcceleration: nil)
            }
        }
        
        if !sensorMask.isDisjoint(with: [.gyroXFiltered, .gyroYFiltered, .gyroZFiltered]) {
            var filteredX, filteredY, filteredZ: Int?
            let deciDegreesToDegrees = 10
            if sensorMask.contains(.gyroXFiltered) {
                filteredX = valueFrom(data: data, startLocation: location) / deciDegreesToDegrees
                location = location + 2
            }
            
            if sensorMask.contains(.gyroYFiltered) {
                filteredY = valueFrom(data: data, startLocation: location) / deciDegreesToDegrees
                location = location + 2
            }
            
            if sensorMask.contains(.gyroZFiltered) {
                filteredZ = valueFrom(data: data, startLocation: location) / deciDegreesToDegrees
                location = location + 2
            }
            
            let filteredGyro = ThreeAxisSensorData(x: filteredX, y: filteredY, z: filteredZ)
            if var gyro = self.gyro {
                gyro.rotationRate = filteredGyro
            } else {
                self.gyro = GyroscopeSensorData(rotationRate: filteredGyro, rawRotation: nil)
            }
        }
        
        if !sensorMask.isDisjoint(with: [.locatorX, .locatorY, .velocityX, .velocityY]) {
            var positionX, positionY, velocityX, velocityY: Double?
            
            if sensorMask.contains(.locatorX) {
                positionX = Double(valueFrom(data: data, startLocation: location))
                location = location + 2
            }
            
            if sensorMask.contains(.locatorY) {
                positionY = Double(valueFrom(data: data, startLocation: location))
                location = location + 2
            }
            
            let millimetersToCentimeters = 10.0
            if sensorMask.contains(.velocityX) {
                velocityX = Double(valueFrom(data: data, startLocation: location)) / millimetersToCentimeters
                location = location + 2
            }
            
            if sensorMask.contains(.velocityY) {
                velocityY = Double(valueFrom(data: data, startLocation: location)) / millimetersToCentimeters
                location = location + 2
            }
            
            let positionData = TwoAxisSensorData<Double>(x: positionX, y: positionY)
            let velocityData = TwoAxisSensorData<Double>(x: velocityX, y: velocityY)
            self.locator = LocatorSensorData(position: positionData, velocity: velocityData)
        }
    }
    
    public init(locator: LocatorSensorData?,
                orientation: AttitudeSensorData?,
                gyro: GyroscopeSensorData?,
                accelerometer: AccelerometerSensorData?) {
        self.locator = locator
        self.orientation = orientation
        self.gyro = gyro
        self.accelerometer = accelerometer
    }
    
    public var verticalAcceleration: Double? {
        get {
            guard let rotation = self.rotationMatrix,
                let accelDoubleX = self.accelerometer?.filteredAcceleration?.x,
                let accelDoubleY = self.accelerometer?.filteredAcceleration?.y,
                let accelDoubleZ = self.accelerometer?.filteredAcceleration?.z
                else { return nil }

            
            let accelX = Float(accelDoubleX)
            let accelY = Float(accelDoubleY)
            let accelZ = Float(accelDoubleZ)
            
            let undoRotation = GLKMatrix3Invert(rotation, nil)
            
            var acceleration = GLKVector3Make(accelX, -accelZ, accelY)
            
            acceleration = GLKMatrix3MultiplyVector3(undoRotation, acceleration)
            
            let verticalAcceleration = Double(-acceleration.y)
            
            return verticalAcceleration
        }
    }
    
    public var rotationMatrix: GLKMatrix3? {
        guard let rollDegrees = self.orientation?.roll,
            let pitchDegrees = self.orientation?.pitch,
            let yawDegrees = self.orientation?.yaw
            else { return nil }
        
        let roll  = Float(rollDegrees)  * Float.pi / 180.0
        let pitch = Float(pitchDegrees) * Float.pi / 180.0
        let yaw   = Float(yawDegrees)   * Float.pi / 180.0
        
        var rotation = GLKMatrix3Identity
        rotation = GLKMatrix3RotateZ(rotation, roll)
        rotation = GLKMatrix3RotateX(rotation, pitch)
        rotation = GLKMatrix3RotateY(rotation, yaw)
        
        return rotation
    }
}

struct StreamingDataTrackerV1 {
    static var sensorMask: SensorMaskV1?
}
