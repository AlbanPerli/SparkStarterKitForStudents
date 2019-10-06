//
//  BoltToy.swift
//  SupportingContent
//
//  Created by Malin Sundberg on 2018-08-03.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

class BoltToy: SpheroV2Toy {
    private let maxScrollingTextLength = 26
    private let maxScrollingTextSpeed = 30
    private let maxPixelValue = 7
    
    override class var descriptor: String { return "SB-" }
    
    public override var batteryLevel: Double? {
        get {
            guard let batteryVoltage = core.batteryVoltage else { return nil }
            return (batteryVoltage - 3.55) / (3.9 - 3.55)
        }
    }
    
    func setMainLed(color: UIColor) {
        setMatrix(color: color)
    }
    
    // These commands should be made availble to the user of the app
    func setBackLed(color: UIColor) {
        core.send(SetBoltLEDCommand(ledMask: BoltLEDMask.back, color: color))
    }
    
    func setFrontLed(color: UIColor) {
        core.send(SetBoltLEDCommand(ledMask: BoltLEDMask.front, color: color))
    }
    
    override func startAiming() {
        core.send(SetBoltLEDCommand(ledMask: BoltLEDMask.back, color: .blue))
    }
    
    override func stopAiming() {
        core.send(SetBoltLEDCommand(ledMask: BoltLEDMask.back, color: .black))
        core.send(ResetYawCommand())
    }
    
    public func setStabilization(state: SetStabilization.State) {
        core.send(SetStabilizationV2(state: state))
    }
    
    private func clampPixel(_ pixel: Pixel) -> Pixel {
        return Pixel(x: (0...maxPixelValue).clamp(pixel.x), y: (0...maxPixelValue).clamp(pixel.y))
    }
    
    func drawMatrix(pixel: Pixel, color: UIColor) {
        let clampedPixel = clampPixel(pixel)
        
        core.send(DrawMatrixPixel(x: UInt8(clampedPixel.x), y: UInt8(clampedPixel.y), color: color))
    }
    
    func drawMatrixLine(from startPixel: Pixel, to endPixel: Pixel, color: UIColor) {
        let clampedStart = clampPixel(startPixel)
        let clampedEnd = clampPixel(endPixel)
        
        core.send(DrawMatrixLine(startX: UInt8(clampedStart.x), startY: UInt8(clampedStart.y), endX: UInt8(clampedEnd.x), endY: UInt8(clampedEnd.y), color: color))
    }
    
    func drawMatrix(fillFrom startPixel: Pixel, to endPixel: Pixel, color: UIColor) {
        let clampedStart = clampPixel(startPixel)
        let clampedEnd = clampPixel(endPixel)
        
        core.send(DrawMatrixFill(startX: UInt8(clampedStart.x), startY: UInt8(clampedStart.y), endX: UInt8(clampedEnd.x), endY: UInt8(clampedEnd.y), color: color))
    }
    
    func setMatrix(color: UIColor) {
        core.send(SetMatrixColor(color))
    }
    
    func clearMatrix() {
        core.send(ClearMatrix())
    }
    
    func setMatrix(rotation: MatrixRotation) {
        core.send(SetMatrixRotation(rotation: rotation.rawValue))
    }
    
    func scrollMatrix(text: String, color: UIColor, speed: Int, loop: ScrollingTextLoopMode) {
        let slicedString = String(text.prefix(maxScrollingTextLength))
        core.send(SetMatrixScrollingText(text: slicedString, color: color, speed: UInt8((0...maxScrollingTextSpeed).clamp(speed)), loop: loop.rawValue))
    }
}

public struct BoltLEDMask: LEDMask, OptionSet {
    public let rawValue: UInt16
    
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
    static let front = BoltLEDMask(rawValue: 0x07)
    static let back = BoltLEDMask(rawValue: 0x38)
    static let all = BoltLEDMask(rawValue: 0x3F)
    
    public var maskValue: UInt16 {
        return self.rawValue
    }
}
