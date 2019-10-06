//
//  SpheroV2ToyCore.swift
//  PlaygroundContent
//
//  Created by Jeff Payan on 2017-06-22.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol ToyCoreCommandListener: class {
    func toyCore(_ toyCore: SpheroV2ToyCore, didReceiveCommandResponse response: CommandResponseV2)
}

struct SpheroV2Services {
    static let apiV2ControlService = CBUUID(string: "00010001-574f-4f20-5370-6865726f2121")
    static let nordicDfuService = CBUUID(string: "00020001-574F-4F20-5370-6865726F2121")
}

struct SpheroV2Characteristics {
    static let apiV2Characteristic = CBUUID(string: "00010002-574f-4f20-5370-6865726f2121")
    static let dfuControlCharactersitic = CBUUID(string: "00020002-574F-4F20-5370-6865726F2121")
    static let dfuInfoCharactersitic = CBUUID(string: "00020004-574F-4F20-5370-6865726F2121")
    static let antiDoSCharacteristic = CBUUID(string: "00020005-574F-4F20-5370-6865726F2121")
}

class SpheroV2ToyCore: NSObject, CBPeripheralDelegate {
    
    private var dfuInfoCharaceristic: CBCharacteristic!
    private var dfuControlCharaceristic: CBCharacteristic!
    private var antiDoSCharacteristic: CBCharacteristic!
    private var commandsCharacteristic: CBCharacteristic!
    private var commandQueue: OperationQueue
    
    let peripheral: CBPeripheral
    private var commandSequencer: CommandSequencerV2

    var appVersion: AppVersion?
    var batteryVoltage: Double?
    var rssiListenerCallback:((Int)->())? = nil
    
    init(peripheral: CBPeripheral, commandSequencer: CommandSequencerV2) {
        self.peripheral = peripheral
        self.commandQueue = OperationQueue()
        self.commandQueue.maxConcurrentOperationCount = 1
        self.commandSequencer = commandSequencer
        
        super.init()
        peripheral.delegate = self
    }
    
    class AsyncWeakWrapper {
        weak var value: ToyCoreCommandListener?
        
        init(value: ToyCoreCommandListener) {
            self.value = value
        }
    }
    
    private var asyncListeners = [AsyncWeakWrapper]()
    
    public func addAsyncListener(_ asyncListener: ToyCoreCommandListener) {
        if !asyncListeners.contains() { $0 === asyncListener } {
            asyncListeners.append(AsyncWeakWrapper(value: asyncListener))
        }
    }
    
    public func removeAsyncListener(_ asyncListener: ToyCoreCommandListener) {
        guard let index = asyncListeners.index(where: {$0 === asyncListener }) else { return }
        asyncListeners.remove(at: index)
    }
    
    func send(_ command: CommandV2) {
        let commandOperation = CommandOperationV2(command, toyCore: self, commandSequencer: commandSequencer, characteristic: commandsCharacteristic)
        commandQueue.addOperation(commandOperation)
    }
    
    func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {
        peripheral.writeValue(data, for: characteristic, type: type)
    }
    
    var preparationCallback: ConnectionCallBack?
    
    func prepareConnection(callback: @escaping ConnectionCallBack) {
        preparationCallback = callback
        peripheral.discoverServices([SpheroV2Services.apiV2ControlService, SpheroV2Services.nordicDfuService])
    }
        
    //MARK - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        DispatchQueue.main.async {
            self.rssiListenerCallback?(RSSI.intValue)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            switch service.uuid {
            case SpheroV2Services.nordicDfuService:
                peripheral.discoverCharacteristics([SpheroV2Characteristics.dfuControlCharactersitic, SpheroV2Characteristics.dfuInfoCharactersitic, SpheroV2Characteristics.antiDoSCharacteristic], for:service)
            case SpheroV2Services.apiV2ControlService:
                peripheral.discoverCharacteristics([SpheroV2Characteristics.apiV2Characteristic], for: service)
            default:
                //don't care about these
                continue
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            
            preparationCallback = nil
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            switch characteristic.uuid {
            case SpheroV2Characteristics.dfuControlCharactersitic:
                dfuControlCharaceristic = characteristic
            case SpheroV2Characteristics.dfuInfoCharactersitic:
                dfuInfoCharaceristic = characteristic
            case SpheroV2Characteristics.antiDoSCharacteristic:
                antiDoSCharacteristic = characteristic
            case SpheroV2Characteristics.apiV2Characteristic:
                commandsCharacteristic = characteristic
            default:
                // This is a characteristic we don't care about. Ignore it.
                continue
            }
        }
        
        if dfuControlCharaceristic != nil && dfuInfoCharaceristic != nil && antiDoSCharacteristic != nil && commandsCharacteristic != nil {
			peripheral.writeValue(Data("usetheforce...band".utf8), for: antiDoSCharacteristic, type: .withResponse)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic === commandsCharacteristic {
            if let error = error {
                //preparationCallback?(false, .peripheralFailed(error: error))
                preparationCallback = nil
                return
            }
            
            send(WakeCommand())
        } else if characteristic === dfuControlCharaceristic {
            if let error = error {
                //preparationCallback?(false, .peripheralFailed(error: error))
                preparationCallback = nil
                return
            }
            
            peripheral.writeValue(Data(bytes: [UInt8(0x30)]), for: dfuControlCharaceristic, type: .withResponse)
        }
    }
    
    var onCharacteristicWrite: ((_ peripheral: CBPeripheral, _ characteristic: CBCharacteristic, _ error: Error?) -> Void)?
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {

        if let error = error {
            //preparationCallback?(false, .peripheralFailed(error: error))
            preparationCallback = nil
            return
        }
        
        onCharacteristicWrite?(peripheral, characteristic, error)
        
        if characteristic === antiDoSCharacteristic {
            peripheral.setNotifyValue(true, for: dfuControlCharaceristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if let error = error {
            //preparationCallback?(false, .peripheralFailed(error: error))
            preparationCallback = nil
            return
        }
        
        if characteristic === dfuControlCharaceristic {
            peripheral.setNotifyValue(true, for: commandsCharacteristic)
            return
        }
        
        guard characteristic === commandsCharacteristic, let response = characteristic.value else { return }
        
        commandSequencer.parseResponseFromToy(response) { [unowned self]  (sequencer, commandResponse) in
            switch commandResponse {
            case let versionsCommandResponse as VersionsCommandResponseV2:
                self.appVersion = versionsCommandResponse.appVersion
                
                self.send(GetBatteryVoltageCommand())

            case let batteryResponse as BatteryVoltageResponse:
                self.batteryVoltage = batteryResponse.batteryVoltage
                
                self.preparationCallback?(true, nil)
                self.preparationCallback = nil
                
            case _ as WakeCommandResponse:
                self.send(VersioningCommandV2())
                
            default:
                break
            }
            
            if let commandResponse = commandResponse {
                self.asyncListeners.forEach { $0.value?.toyCore(self, didReceiveCommandResponse: commandResponse) }
            }
        }
    }
}
