//
//  SensorControl.swift
//  PlaygroundContent
//
//  Created by Jeff Payan on 2017-06-29.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation

protocol SensorControl {
    var interval: Int { get set }
    
    var onDataReady: ((_ sensorData: SensorControlData) -> Void)? { get set }
    var onFreefallDetected: (() -> Void)? { get set }
    var onLandingDetected: (() -> Void)? { get set }
    
    func enable(sensors sensorMask: SensorMask)
    func disable()
    
    func resetLocator()
}

public enum SensorMaskValues: Int {
    case off = 0
    case locator = 1
    case gyro = 2
    case orientation = 3
    case accelerometer = 4
}

public typealias SensorMask = [SensorMaskValues]
