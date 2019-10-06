//
//  SpheroV2Toy.swift
//  PlaygroundContent
//
//  Created by Jeff Payan on 2017-06-22.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

class SpheroV2Toy: Toy, SensorControlProvider, Aimable, Collidable, DriveRollable, ToyCoreCommandListener {
    
    lazy var sensorControl: SensorControl = SensorControlV2(toyCore: self.core)
    let core: SpheroV2ToyCore
    
    var onCollisionDetected: ((CollisionData) -> Void)?
    
    init(peripheral: CBPeripheral, owner: ToyBox, commandSequencer: CommandSequencerV2 = CommandSequencerV2()) {
        self.core = SpheroV2ToyCore(peripheral: peripheral, commandSequencer: commandSequencer)
        super.init(identifier: peripheral.identifier, owner: owner)
        self.core.addAsyncListener(self)
    }
    
    fileprivate func sendRollCommand(heading: UInt16, speed: UInt8, flags: DriveWithHeadingCommand.DriveFlags) {
        core.send(DriveWithHeadingCommand(speed: speed, heading: heading, flags: flags))
    }
    
    override var peripheral: CBPeripheral? {
        return core.peripheral
    }
    
    override var appVersion: AppVersion? {
        return core.appVersion
    }
    
    override public func getPowerState() {
        core.send(GetBatteryVoltageCommand())
    }
    
    public func setCollisionDetection(configuration: CollisionConfiguration) {
        core.send(ConfigureCollisionDetectionV2(configuration: configuration))
    }
    
    override public func setToyOptions(_ options: ToyOptionsMask) {
        // At the moment, we don't support setting of any options for V2 toys. This function is only here to keep a consistancy between the available functions for the V1 and V2 SDK.
    }
        
    public func playAnimationBundle(_ bundle: AnimationBundle) {
        core.send(PlayAnimationBundleCommand(animationBundleId: UInt16(bundle.animationId)))
    }
    
    override public func configureLocator() {
        core.send(ResetLocator())
    }
    
    public func setBackLed(brightness: Double) {
        core.send(SetLEDCommand(ledMask: MiniLEDMask.back, brightness: UInt8(brightness)))
    }
    
    //MARK: Aiming
    //can't put this in an extension, because R2 needs to override start Aiming
    func startAiming() {
        setBackLed(brightness: 255)
    }
    
    func stopAiming() {
        setBackLed(brightness: 0)
        core.send(ResetYawCommand())
    }
    
    //MARK: DriveRollable
    //here for same reason as above
    func roll(heading: Double, speed: Double, rollType: Roll.RollType = .roll, direction: Roll.RollDirection = .forward) {
        let flags: DriveWithHeadingCommand.DriveFlags = (speed < 0 || direction == .reverse) ? .reverse : []
        let intSpeed = UInt8(abs(speed).clamp(lowerBound: 0.0, upperBound: 255.0))
        let intHeading = UInt16(heading.positiveRemainder(dividingBy: 360.0))
        
        sendRollCommand(heading: intHeading, speed: intSpeed, flags: flags)
    }
    
    func stopRoll(heading: Double) {
        let intHeading = UInt16(heading.positiveRemainder(dividingBy: 360.0))
        sendRollCommand(heading: intHeading, speed: 0, flags: [])
    }
    
    func rotateAim(_ heading: Double) {
        let intHeading = UInt16(heading.positiveRemainder(dividingBy: 360.0))
        core.send(DriveWithHeadingCommand(speed: 0, heading: intHeading, flags: [.fastTurnMode]))
    }

    func toyCore(_ toyCore: SpheroV2ToyCore, didReceiveCommandResponse response: CommandResponseV2) {
        switch response {
        case _ as DidSleepResponseV2:
            owner?.disconnect(toy: self)

        case _ as PreSleepWarningResponse:
            core.send(EchoCommand())
            
        case let collision as CollisionData:
            onCollisionDetected?(collision)

        default:
            break
        }
    }
    
    override func connect(callback: @escaping ConnectionCallBack) {
        core.prepareConnection(callback: callback)
    }
    
    override func putAway() {
        core.send(GoToSleepCommandV2())
    }
}

public protocol AnimationBundle {
    var animationId: Int { get }
}
