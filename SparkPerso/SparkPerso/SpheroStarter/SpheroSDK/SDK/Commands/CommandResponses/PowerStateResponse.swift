//
//  PowerStateResponse.swift
//  SpheroSDK
//
//  Created by Jeff Payan on 2017-05-02.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation

public struct PowerStateResponse: DeviceCommandResponse {
    public let batteryVoltage: Double
    
    public init(_ data: Data) {
        let bigByte = UInt16(data[2] as UInt8) << 8 as UInt16
        let littleByte = UInt16(data[3] as UInt8)
        self.batteryVoltage = Double((bigByte + littleByte)) / 100.0
    }
}

public struct BatteryVoltageResponse: CommandResponseV2 {
    public let batteryVoltage: Double
    
    public init?(_ data: Data) {
        guard data.count > 1 else {
            return nil
        }
        
        let bigByte = UInt16(data[0] as UInt8) << 8 as UInt16
        let littleByte = UInt16(data[1] as UInt8)
        self.batteryVoltage = Double((bigByte + littleByte)) / 100.0
    }
}

public struct PreSleepWarningResponse: CommandResponseV2 {}
