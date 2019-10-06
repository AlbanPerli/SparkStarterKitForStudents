//
//  VersionsCommandResponse.swift
//  SpheroSDK
//
//  Created by Jeff Payan on 2017-03-17.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation

enum ToyModel: Int {
    case unknown = -1
    case sprkPlus = 50
}

public struct AppVersion: Comparable {
    let major: String
    let minor: String
    var build: String? = nil
    
    private func compare(to appVersion: AppVersion) -> ComparisonResult {
        let majorResult = major.compare(appVersion.major)
        if majorResult != .orderedSame {
            return majorResult
        }
        
        return minor.compare(appVersion.minor)
    }
    
    public static func <(lhs: AppVersion, rhs: AppVersion) -> Bool {
        return lhs.compare(to: rhs) == .orderedAscending
    }
    
    public static func ==(lhs: AppVersion, rhs: AppVersion) -> Bool {
        return lhs.major == rhs.major && lhs.minor == rhs.minor
    }
}

class VersionsCommandResponse: DeviceCommandResponse {
    public let appVersion: AppVersion
    public let modelNumber: ToyModel
    
    public init(_ data: Data) {
        let major = data[3]
        let minor = data[4]
        let model = data[1]
        
        appVersion = AppVersion(major: "\(major)", minor: "\(minor)", build: nil)
        modelNumber = ToyModel(rawValue: Int(model)) ?? .unknown
    }
}

class VersionsCommandResponseV2: CommandResponseV2 {
    public let appVersion: AppVersion
    
    public init?(_ data: Data) {
        if data.count >= 6 {
            let major = UInt16(data[0]) << 8 | UInt16(data[1])
            let minor = UInt16(data[2]) << 8 | UInt16(data[3])
            let build = UInt16(data[4]) << 8 | UInt16(data[5])
            
            appVersion = AppVersion(major: "\(major)", minor: "\(minor)", build: "\(build)")
        } else {
            return nil
        }
    }
}
