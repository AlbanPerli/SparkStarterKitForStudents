//
//  Double+Utils.swift
//  SpheroSDK
//
//  Created by Anthony Blackman on 2017-03-15.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation

extension Double {
    
    public func clamp(lowerBound: Double, upperBound: Double) -> Double {
        var clamped = self
        clamped = max(lowerBound, clamped)
        clamped = min(upperBound, clamped)
        return clamped
    }
    
    public func positiveRemainder(dividingBy divisor: Double) -> Double {
        var remainder = truncatingRemainder(dividingBy: divisor)
        if self < 0.0 {
            remainder += divisor
        }
        return remainder
    }
    
    public static func random() -> Double {
        return Double(Int.random(in: 0..<Int.max)) / Double(UInt32.max)
    }
    
    // Puts an angle in the range (-180,180]
    public func canonizedAngle(fullTurn: Double = 360.0) -> Double {
        let halfTurn = 0.5 * fullTurn
        var result = self.truncatingRemainder(dividingBy: fullTurn)
        if result > halfTurn {
            result -= fullTurn
        } else if result <= -halfTurn {
            result += fullTurn
        }
        return result
    }
    
}
