//
//  SDKUtils.swift
//  SupportingContent
//
//  Created by Jeff Payan on 2018-08-08.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation

extension ClosedRange {
    func clamp(_ value : Bound) -> Bound {
        return self.lowerBound > value ? self.lowerBound
            : self.upperBound < value ? self.upperBound
            : value
    }
}

public struct Pixel {
    let x: Int
    let y: Int
    
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

public enum MatrixRotation: UInt8 {
    case deg0 = 0x00
    case deg90 = 0x01
    case deg180 = 0x02
    case deg270 = 0x03
}

public enum ScrollingTextLoopMode: UInt8 {
    case noLoop = 0x00
    case loopForever = 0x01
}

extension Array {
    func chunked(by chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
} 
