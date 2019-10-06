//
//  SensorCommandResponseV2.swift
//  PlaygroundContent
//
//  Created by Jeff Payan on 2017-06-29.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import GLKit

struct StreamingDataTrackerV2 {
    static var sensorMask: SensorMaskV2?
}

fileprivate func valueFrom(data: Data, startLocation: Int) -> Double {
    let dataArray = [UInt8](data[startLocation..<startLocation+4])
    
    guard let float = Float32(dataArray.reversed()) else { return 0.0 }
    return Double(float)
}

public struct SensorDataCommandResponseV2: CommandResponseV2, SensorControlData {
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
    
    public init(data: Data) {
        var location = 0
        let sensorMask = StreamingDataTrackerV2.sensorMask!
        
        if sensorMask.contains(.imuAnglesFilteredAll) {
            var yaw, pitch, roll: Int?
            
            pitch = Int(valueFrom(data: data, startLocation: location))
            location = location + 4
            
            roll = Int(valueFrom(data: data, startLocation: location))
            location = location + 4
            
            yaw = Int(valueFrom(data: data, startLocation: location))
            location = location + 4
            
            self.orientation = AttitudeSensorData(yaw: yaw, pitch: pitch, roll: roll)
        }
        
        if sensorMask.contains(.accelerometerFilteredAll) {
            var filteredX, filteredY, filteredZ: Double?
            filteredX = valueFrom(data: data, startLocation: location)
            location = location + 4
            
            filteredY = valueFrom(data: data, startLocation: location)
            location = location + 4
            
            filteredZ = valueFrom(data: data, startLocation: location)
            location = location + 4
            
            let filteredAcceleration = ThreeAxisSensorData<Double>(x: filteredX, y: filteredY, z: filteredZ)
            self.accelerometer = AccelerometerSensorData(filteredAcceleration: filteredAcceleration , rawAcceleration: nil)
        }
        
        if sensorMask.contains(.gyroRawAll) {
            let multiplier = 2000.0 / 32767.0
            var filteredX, filteredY, filteredZ: Int?
            
            filteredX = Int(valueFrom(data: data, startLocation: location) * multiplier)
            location = location + 4
            
            filteredY = Int(valueFrom(data: data, startLocation: location) * multiplier)
            location = location + 4
            
            filteredZ = Int(valueFrom(data: data, startLocation: location) * multiplier)
            location = location + 4
            
            let filteredGyro = ThreeAxisSensorData(x: filteredX, y: filteredY, z: filteredZ)
            
            self.gyro = GyroscopeSensorData(rotationRate: filteredGyro, rawRotation: nil)
        }
        
        if sensorMask.contains(.locatorAll) {
            var positionX, positionY, velocityX, velocityY: Double?
            let metersToCentimeters = 100.0
            
            positionX = valueFrom(data: data, startLocation: location) * metersToCentimeters
            location = location + 4
            
            positionY = valueFrom(data: data, startLocation: location) * metersToCentimeters
            location = location + 4
            
            velocityX = valueFrom(data: data, startLocation: location) * metersToCentimeters
            location = location + 4
            
            velocityY = valueFrom(data: data, startLocation: location) * metersToCentimeters
            location = location + 4
            
            let positionData = TwoAxisSensorData<Double>(x: positionX, y: positionY)
            let velocityData = TwoAxisSensorData<Double>(x: velocityX, y: velocityY)
            self.locator = LocatorSensorData(position: positionData, velocity: velocityData)
        }
        
        if sensorMask.contains(.gyroFilteredAll) {
            var filteredX, filteredY, filteredZ: Int?
            
            filteredX = Int(valueFrom(data: data, startLocation: location))
            location = location + 4
            
            filteredY = Int(valueFrom(data: data, startLocation: location))
            location = location + 4
            
            filteredZ = Int(valueFrom(data: data, startLocation: location))
            location = location + 4
            
            let filteredGyro = ThreeAxisSensorData(x: filteredX, y: filteredY, z: filteredZ)
            
            self.gyro = GyroscopeSensorData(rotationRate: filteredGyro, rawRotation: nil)
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

typealias SensorDataCommand = SensorDataCommandResponseV2
