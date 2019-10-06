//
//  ToyProtocols.swift
//  SpheroSDK
//
//  Created by Jeff Payan on 2017-03-14.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation

protocol DriveRollable {
    func roll(heading: Double, speed: Double, rollType: Roll.RollType, direction: Roll.RollDirection)
    func stopRoll(heading: Double)
}

protocol Aimable {
    func startAiming()
    func stopAiming()
    func rotateAim(_ heading: Double)
}

protocol Collidable {
    func setCollisionDetection(configuration: CollisionConfiguration)
    
    var onCollisionDetected: ((_ collisionData: CollisionData) -> Void)? { get set }
}

protocol SensorControlProvider {
    var sensorControl: SensorControl { get }
}
