//
//  MiniToy.swift
//  SupportingContent
//
//  Created by Malin Sundberg on 2018-07-24.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import UIKit

class MiniToy: SpheroV2Toy {
    override class var descriptor: String { return "SM-" }
    
    public override var batteryLevel: Double? {
        get {
            guard let batteryVoltage = core.batteryVoltage else { return nil }
            return (batteryVoltage - 3.4) / (3.65 - 3.4)
        }
    }
    
    public override func setBackLed(brightness: Double) {
        core.send(SetLEDCommand(ledMask: MiniLEDMask.back,  brightness: UInt8(brightness)))
    }
    
    func setMainLed(color: UIColor) {
        core.send(SetLEDCommand(ledMask: MiniLEDMask.body, color: color))
    }
    
    public func setStabilization(state: SetStabilization.State) {
        core.send(SetStabilizationV2(state: state))
    }
}



public struct MiniLEDMask: LEDMask, OptionSet {
    public let rawValue: UInt16
    
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
    static let body = MiniLEDMask(rawValue: 0x0E)
    static let back = MiniLEDMask(rawValue: 0x01)
    
    public var maskValue: UInt16 {
        return self.rawValue
    }
}
