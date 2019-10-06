//
//  SpheroV1ToyToy.swift
//  SpheroSDK
//
//  Created by Jeff Payan on 2017-03-14.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

public class SpheroV1Toy: Toy, SensorControlProvider, Collidable {
    
    lazy var sensorControl: SensorControl = SensorControlV1(toyCore: self.core)
    let core: SpheroV1ToyCore
    
    var onCollisionDetected: ((CollisionData) -> Void)?
    
    override var peripheral: CBPeripheral? {
        return core.peripheral
    }
    
    override var appVersion: AppVersion? {
        return core.appVersion
    }
    
    init(peripheral: CBPeripheral, owner: ToyBox) {
        self.core = SpheroV1ToyCore(peripheral: peripheral)
        super.init(identifier: peripheral.identifier, owner: owner)
        self.core.addAsyncListener(self)
    }
    
    fileprivate func sendRollCommand(heading: UInt16, speed: UInt8, rollType: Roll.RollType, direction: Roll.RollDirection) {
        core.send(Roll(heading: heading, speed: speed, state: rollType, direction: direction))
    }
    
    fileprivate func sendHeadingCommand(heading: Double) {
        let intAngle = UInt16(heading.positiveRemainder(dividingBy: 360.0))
        core.send(UpdateHeadingCommand(heading: intAngle))
    }
    
    public func setMainLed(color: UIColor) {
        core.send(SetMainLEDColor(color: color))
    }
    
    public func setBackLed(brightness: Double) {
        core.send(SetBackLEDBrightness(brightness: UInt8(brightness.clamp(lowerBound: 0.0, upperBound: 255.0))))
    }
    
    override public func configureLocator() {
        core.send(ConfigureLocatorCommand(newX: 0, newY: 0, newYaw: 0))
    }

    override public func getPowerState() {
        core.send(PowerStateCommand())
    }
    
    public func setStabilization(state: SetStabilization.State) {
        core.send(SetStabilization(state: state))
    }
    
    public func setCollisionDetection(configuration: CollisionConfiguration) {
        core.send(ConfigureCollisionDetection(configuration: configuration))
    }
    
    override public func setToyOptions(_ options: ToyOptionsMask) {
        core.send(SetOptionsFlagsCommand(options: options))
    }
    
    public func setRawMotor(leftMotorPower: Double, leftMotorMode: RawMotor.RawMotorMode, rightMotorPower: Double, rightMotorMode: RawMotor.RawMotorMode) {
        let clampedLeftPower = UInt8(leftMotorPower.clamp(lowerBound: 0.0, upperBound: 255.0))
        let clampedRightPower = UInt8(rightMotorPower.clamp(lowerBound: 0.0, upperBound: 255.0))
        
        core.send(RawMotor(leftMotorPower: clampedLeftPower,
                           leftMotorMode: leftMotorMode,
                           rightMotorPower: clampedRightPower,
                           rightMotorMode: rightMotorMode))
    }
    
    public override func connect(callback: @escaping ConnectionCallBack) {
        core.prepareConnection(callback: callback)
    }
    
    public override func putAway() {
        core.send(GoToSleepCommand(type: .sleep))
    }
}

//MARK: AsyncMessageListener
extension SpheroV1Toy: ToyCoreAsyncListener {
    
    func toyCore(_ toyCore: SpheroV1ToyCore, didReceiveAsyncResponse response: AsyncCommandResponse) {
        switch response {
        case let collisionData as CollisionData:
            onCollisionDetected?(collisionData)
            
        case _ as DidSleepResponse:
            owner?.disconnect(toy: self)
        
        case _ as SleepWarningResponse:
            core.send(PingCommand())
            
        default:
            break
        }
    }
    
    func toyCore(_ toyCore: SpheroV1ToyCore, didReceiveDeviceResponse response: DeviceCommandResponse) {
        switch response {
        case let powerState as PowerStateResponse:
            core.batteryVoltage = powerState.batteryVoltage
            onBatteryUpdated?(batteryLevel)
            
        default:
            break
        }
    }
}

//MARK: DriveRollable, Aimable
extension SpheroV1Toy: DriveRollable {
    
    public func roll(heading: Double, speed: Double, rollType: Roll.RollType = .roll, direction: Roll.RollDirection = .forward) {
        let direction: Roll.RollDirection = (speed < 0 || direction == .reverse) ? .reverse : .forward
        let intSpeed = UInt8(speed.clamp(lowerBound: 0.0, upperBound: 255.0))
        let intHeading = UInt16(heading.positiveRemainder(dividingBy: 360.0))
        
        sendRollCommand(heading: intHeading, speed: intSpeed, rollType: rollType, direction: direction)
    }
    
    public func stopRoll(heading: Double) {
        let intHeading = UInt16(heading.positiveRemainder(dividingBy: 360.0))
        
        sendRollCommand(heading: intHeading, speed: 0, rollType: .stop, direction: .forward)
    }
    
}

extension SpheroV1Toy: Aimable {
    
    public func startAiming() {
        setBackLed(brightness: 255.0)
    }
    
    public func stopAiming() {
        setBackLed(brightness: 0.0)
        sendHeadingCommand(heading: 0.0)
    }
    
    public func rotateAim(_ heading: Double) {
        let intHeading = UInt16(heading.positiveRemainder(dividingBy: 360.0))
        sendRollCommand(heading: intHeading, speed: 0, rollType: .calibrate, direction: .forward)
    }
    
}
