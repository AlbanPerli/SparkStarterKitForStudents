//
//  R2D2Toy.swift
//  PlaygroundContent
//
//  Created by Jeff Payan on 2017-06-27.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import UIKit

// Black in RGB color space.
private let rgbBlack = UIColor(red: 0, green: 0, blue: 0, alpha: 1)

public enum FrontPSIColor {
    case blue
    case red
    case black
    
    init?(color: UIColor) {
        switch color {
        case UIColor.blue:
            self = .blue
        case UIColor.red:
            self = .red
        // switch/case will not match colors of different color spaces.
        // Check both grayscale and rgb spaces.
        case UIColor.black, rgbBlack:
            self = .black
        default:
            return nil
        }
    }
    
    func color() -> UIColor {
        switch self {
        case .blue:
            return UIColor.blue
        case .red:
            return UIColor.red
        case .black:
            return UIColor.black
        }
    }
}

public enum BackPSIColor {
    case green
    case yellow
    case black
    
    init?(color: UIColor) {
        switch color {
        case UIColor.green:
            self = .green
        case UIColor.yellow:
            self = .yellow
        // switch/case will not match colors of different color spaces.
        // Check both grayscale and rgb spaces.
        case UIColor.black, rgbBlack:
            self = .black
        default:
            return nil
        }
    }
    
    func color() -> UIColor {
        switch self {
        case .green:
            return UIColor.green
        case .yellow:
            return UIColor.yellow
        case .black:
            return UIColor.black
        }
    }
}


class R2D2Toy: SpheroV2Toy {
    
    private enum StanceState {
        case tripod
        case notTripod
        case waitingForTripod(heading: Double, speed: Double)
        
        //need to implement === because of associated values
        public static func ==(lhs: StanceState, rhs: StanceState) -> Bool {
            switch (lhs,rhs) {
            case let (.waitingForTripod(heading, speed), .waitingForTripod(headingTwo, speedTwo)) where (heading == headingTwo && speed == speedTwo) : return true
            case (.tripod,.tripod): return true
            case (.notTripod, .notTripod): return true
            default: return false
            }
        }
    }
    
    private var stanceState: StanceState = .notTripod
    
    override class var descriptor: String { return "D2-" }
    
    public func setDomePosition(angle degrees: Double) {
        let clampedAngle = degrees.clamp(lowerBound: -100.0, upperBound: 100.0)
        core.send(SetDomePosition(angle: clampedAngle))
    }
    
    public func setStance(_ stance: StanceCommand.StanceId) {
        core.send(StanceCommand(stanceId: stance))
    }
    
    public func setFrontPSILed(color: FrontPSIColor) {
        core.send(SetLEDCommand(ledMask: R2LEDMask.frontPSI, color: color.color()))
    }
    
    public func setBackPSILed(color: BackPSIColor) {
        core.send(SetLEDCommand(ledMask: R2LEDMask.backPSI, color: color.color()))
    }
    
    public func setHoloProjectorLed(brightness: Double) {
        let clampedBrightness = UInt8(brightness.clamp(lowerBound: 0.0, upperBound: 255.0))
        core.send(SetLEDCommand(ledMask: R2LEDMask.holoProjector, brightness: clampedBrightness))
    }
    
    public func setLogicDisplayLeds(brightness: Double) {
        let clampedBrightness = UInt8(brightness.clamp(lowerBound: 0.0, upperBound: 255.0))
        core.send(SetLEDCommand(ledMask: R2LEDMask.logicDisplays, brightness: clampedBrightness))
    }
    
    public func setAudioVolume(_ volume: Int) {
        let clampedVolume = UInt8(truncatingIfNeeded: volume)
        core.send(SetAudioVolume(volume: clampedVolume))
    }
    
    public func setRawMotor(leftMotorPower: Double, leftMotorMode: RawMotor.RawMotorMode, rightMotorPower: Double, rightMotorMode: RawMotor.RawMotorMode) {
        let clampedLeftPower = UInt8(leftMotorPower.clamp(lowerBound: 0.0, upperBound: 255.0))
        let clampedRightPower = UInt8(rightMotorPower.clamp(lowerBound: 0.0, upperBound: 255.0))
        
        core.send(RawMotorV2(leftMotorPower: clampedLeftPower,
                           leftMotorMode: leftMotorMode,
                           rightMotorPower: clampedRightPower,
                           rightMotorMode: rightMotorMode))
    }
    
    public func setStanceChangedNotifications(enabled: Bool) {
        core.send(EnableStanceChangedAsyncCommand(enabled: enabled))
    }
    
    public func playSound(_ soundId: PlaySoundCommand.DroidSound, playbackMode: PlaySoundCommand.AudioPlaybackMode) {
        core.send(PlaySoundCommand(sound: soundId, playbackMode: playbackMode))
    }
    
    public func playTestAudio() {
        core.send(TestAudioCommand())
    }
    
    public func stopAudio() {
        core.send(StopAudioCommand())
    }
    
    public override var batteryLevel: Double? {
        get {
            guard let batteryVoltage = core.batteryVoltage else { return nil }
            return (batteryVoltage - 3.4) / (3.65 - 3.4)
        }
    }
    
    override func startAiming() {
        super.startAiming()
        
        setBackPSILed(color: .green)
        setDomePosition(angle: 0.0)
    }
    
    override func stopAiming() {
        super.stopAiming()
        
        setBackPSILed(color: .black)
    }
    
    override func roll(heading: Double, speed: Double, rollType: Roll.RollType = .roll, direction: Roll.RollDirection = .forward) {
        switch stanceState {
        case .tripod:
            super.roll(heading: heading, speed: speed)
            
        case .notTripod:
            stanceState = .waitingForTripod(heading: heading, speed: speed)
            setStance(.tripod)
            
        case .waitingForTripod(heading: _, speed: _):
            stanceState = .waitingForTripod(heading: heading, speed: speed)
        }
    }
    
    override func toyCore(_ toyCore: SpheroV2ToyCore, didReceiveCommandResponse response: CommandResponseV2) {
        super.toyCore(toyCore, didReceiveCommandResponse: response)
        
        if let shoulderComplete = response as? ShouldActionCompleteResponse {
            if shoulderComplete.actionId == .tripod {
                if case StanceState.waitingForTripod(let heading, let speed) = stanceState {
                    stanceState = .tripod
                    roll(heading: heading, speed: speed)
                } else if case .notTripod = stanceState {
                    stanceState = .tripod
                }
                
            } else {
                stanceState = .notTripod
            }
        }
    }
}

public struct R2D2Animations: AnimationBundle {
    
    public var animationId: Int { return animation.rawValue }
    
    public init?(bundleId: Int) {
        if let animation = R2AnimationBundles(rawValue: bundleId) {
            self.animation = animation
        } else {
            return nil
        }
    }
    
    private init(animation: R2AnimationBundles) {
        self.animation = animation
    }
    
    private let animation: R2AnimationBundles
    
    public static let alarmed = R2D2Animations(animation: .alarmed)
    public static let angry = R2D2Animations(animation: .angry)
    public static let annoyed = R2D2Animations(animation: .angry)
    public static let chatty = R2D2Animations(animation: .chatty)
    public static let drive = R2D2Animations(animation: .drive)
    public static let excited = R2D2Animations(animation: .excited)
    public static let happy = R2D2Animations(animation: .happy)
    public static let ionBlast = R2D2Animations(animation: .ionBlast)
    public static let laugh = R2D2Animations(animation: .laugh)
    public static let no = R2D2Animations(animation: .no)
    public static let sad = R2D2Animations(animation: .sad)
    public static let sassy = R2D2Animations(animation: .sassy)
    public static let scared = R2D2Animations(animation: .scared)
    public static let spin = R2D2Animations(animation: .spin)
    public static let yes = R2D2Animations(animation: .yes)
    public static let scan = R2D2Animations(animation: .scan)
    public static let sleep = R2D2Animations(animation: .sleep)
    public static let surprised = R2D2Animations(animation: .surprised)

    private enum R2AnimationBundles: Int {
        case alarmed = 7
        case angry = 8
        case annoyed = 9
        case chatty = 10
        case drive = 11
        case excited = 12
        case happy = 13
        case ionBlast = 14
        case laugh = 15
        case no = 16
        case sad = 17
        case sassy = 18
        case scared = 19
        case spin = 20
        case yes = 21
        case scan = 22
        case sleep = 23
        case surprised = 24
    }
}

public struct R2LEDMask: LEDMask, OptionSet { 
    public let rawValue: UInt16
    
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
    static let frontPSI = R2LEDMask(rawValue: 0x07)
    static let backPSI = R2LEDMask(rawValue: 0x70)
    static let holoProjector = R2LEDMask(rawValue: 0x80)
    static let logicDisplays = R2LEDMask(rawValue: 0x08)
    
    public var maskValue: UInt16 {
        return self.rawValue
    }
}
