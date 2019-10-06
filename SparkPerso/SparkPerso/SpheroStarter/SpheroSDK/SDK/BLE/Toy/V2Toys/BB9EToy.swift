//
//  BB9EToy.swift
//  PlaygroundContent
//
//  Created by Jeff Payan on 2017-06-22.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import UIKit

class BB9EToy: SpheroV2Toy {
    override class var descriptor: String { return "GB-" }
    
    public func setMainLed(color: UIColor) {
        core.send(SetLEDCommand(ledMask: BB9ELEDMask.body, color: color))
    }
    
    public override func setBackLed(brightness: Double) {
        let clampedBrightness = UInt8(brightness.clamp(lowerBound: 0.0, upperBound: 255.0))
        core.send(SetLEDCommand(ledMask: BB9ELEDMask.back, brightness: clampedBrightness))
    }
    
    public func setHeadLed(brightness: Double) {
        let clampedBrightness = UInt8(brightness.clamp(lowerBound: 0.0, upperBound: 255.0))
        core.send(SetLEDCommand(ledMask: BB9ELEDMask.head, brightness: clampedBrightness))
    }
    
    public func setStabilization(state: SetStabilization.State) {
        core.send(SetStabilizationV2(state: state))
    }
    
    override func startAiming() {
        super.startAiming()
        
        setBackLed(brightness: 255.0)
    }
    
    override func stopAiming() {
        super.stopAiming()
        
        setBackLed(brightness: 0.0)
    }
    
    public override var batteryLevel: Double? {
        get {
            guard let batteryVoltage = core.batteryVoltage else { return nil }
            
            return (batteryVoltage - 6.5) / (7.8 - 6.5)
        }
    }
}


public struct BB9ELEDMask: LEDMask, OptionSet {
    public let rawValue: UInt16
    
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
    static let head = BB9ELEDMask(rawValue: 0x10)
    static let body = BB9ELEDMask(rawValue: 0x07)
    static let back = BB9ELEDMask(rawValue: 0x08)
    
    public var maskValue: UInt16 {
        return self.rawValue
    }
}

public struct BB9EAnimations: AnimationBundle {
    
    public var animationId: Int { return animation.rawValue }
    private let animation: BB9EAnimationBundles

    static let alarm = BB9EAnimations(animation: .alarm)
    static let no = BB9EAnimations(animation: .no)
    static let scan = BB9EAnimations(animation: .scan)
    static let scared = BB9EAnimations(animation: .scared)
    static let yes = BB9EAnimations(animation: .yes)
    
    private enum BB9EAnimationBundles: Int {
        case alarm = 0
        case no = 1
        case scan = 2
        case scared = 3
        case yes = 4
    }
}
