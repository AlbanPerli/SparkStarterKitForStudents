//
//  CBUUID+SpheroUUIDs.swift
//  SpheroSDK
//
//  Copyright © 2016 Apple Inc. All rights reserved.
//

import Foundation
import CoreBluetooth

extension CBUUID {
    // BLE service characteristics
    @nonobjc static let wakeCharacteristic = CBUUID(string: "22bb746f-2bbf-7554-2d6f-726568705327")
    @nonobjc static let txPowerCharacteristic = CBUUID(string: "22bb746f-2bb2-7554-2d6f-726568705327")
    @nonobjc static let antiDoSCharacteristic = CBUUID(string: "22bb746f-2bbd-7554-2d6f-726568705327")

    // Robot control service characteristics
    @nonobjc static let commandsCharacteristic = CBUUID(string: "22bb746f-2ba1-7554-2d6f-726568705327")
    @nonobjc static let responseCharacteristic = CBUUID(string: "22bb746f-2ba6-7554-2d6f-726568705327")
}
