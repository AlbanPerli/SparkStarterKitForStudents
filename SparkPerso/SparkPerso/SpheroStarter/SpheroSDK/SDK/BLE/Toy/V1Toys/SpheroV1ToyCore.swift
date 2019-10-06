//
//  SpheroV1ToyCore.swift
//  PlaygroundContent
//
//  Created by Jeff Payan on 2017-06-21.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol ToyCoreAsyncListener: class {
    func toyCore(_ toyCore: SpheroV1ToyCore, didReceiveAsyncResponse response: AsyncCommandResponse)
    func toyCore(_ toyCore: SpheroV1ToyCore, didReceiveDeviceResponse response: DeviceCommandResponse)
}

struct SpheroV1Services {
    static let bleService = CBUUID(string: "22bb746f-2bb0-7554-2d6f-726568705327")
    static let robotControlService = CBUUID(string: "22bb746f-2ba0-7554-2d6f-726568705327")
}

public typealias ConnectionCallBack = ((_ didPrepareConnection: Bool, _ error: Error?) -> Void)

class SpheroV1ToyCore: NSObject, CBPeripheralDelegate {
    private var wakeCharacteristic: CBCharacteristic!
    private var txPowerCharacteristic: CBCharacteristic!
    private var antiDoSCharacteristic: CBCharacteristic!
    private var commandsCharacteristic: CBCharacteristic!
    private var responseCharacteristic: CBCharacteristic!
    private var commandQueue: OperationQueue
    
    var peripheral: CBPeripheral
    lazy private var commandSequencer: CommandSequencerV1 = CommandSequencerV1()
    
    var appVersion: AppVersion?
    var batteryVoltage: Double?
    
    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.commandQueue = OperationQueue()
        self.commandQueue.maxConcurrentOperationCount = 1
        
        super.init()
        peripheral.delegate = self
    }
    
    class AsyncWeakWrapper {
        weak var value: ToyCoreAsyncListener?
        
        init(value: ToyCoreAsyncListener) {
            self.value = value
        }
    }
    
    private var asyncListeners = [AsyncWeakWrapper]()
    
    public func addAsyncListener(_ asyncListener: ToyCoreAsyncListener) {
        if !asyncListeners.contains() { $0 === asyncListener } {
            asyncListeners.append(AsyncWeakWrapper(value: asyncListener))
        }
    }
    
    public func removeAsyncListener(_ asyncListener: ToyCoreAsyncListener) {
        guard let index = asyncListeners.index(where: {$0 === asyncListener }) else { return }
        asyncListeners.remove(at: index)
    }
    
    func send(_ command: CommandV1) {
        let commandOperation = CommandOperation(command, toyCore: self, commandSequencer: commandSequencer, characteristic: commandsCharacteristic)
        commandQueue.addOperation(commandOperation)
    }
    
    func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {
        peripheral.writeValue(data, for: characteristic, type: type)
    }
    
    var preparationCallback: ConnectionCallBack?
    
    func prepareConnection(callback: @escaping ConnectionCallBack) {
        preparationCallback = callback
        peripheral.discoverServices([SpheroV1Services.bleService, SpheroV1Services.robotControlService])
    }
    
    //MARK - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            //preparationCallback?(false, .peripheralFailed(error: error))
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            switch service.uuid {
            case SpheroV1Services.bleService:
                peripheral.discoverCharacteristics([.wakeCharacteristic, .txPowerCharacteristic, .antiDoSCharacteristic], for:service)
            case SpheroV1Services.robotControlService:
                peripheral.discoverCharacteristics([.commandsCharacteristic, .responseCharacteristic], for: service)
            default:
                //don't care about these
                continue
            }
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            //preparationCallback?(false, .peripheralFailed(error: error))
            preparationCallback = nil
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            switch characteristic.uuid {
            case CBUUID.wakeCharacteristic:
                wakeCharacteristic = characteristic
            case CBUUID.txPowerCharacteristic:
                txPowerCharacteristic = characteristic
            case CBUUID.antiDoSCharacteristic:
                antiDoSCharacteristic = characteristic
            case CBUUID.commandsCharacteristic:
                commandsCharacteristic = characteristic
            case CBUUID.responseCharacteristic:
                responseCharacteristic = characteristic
            default:
                // This is a characteristic we don't care about. Ignore it.
                continue
            }
        }
        
        if wakeCharacteristic != nil && txPowerCharacteristic != nil && antiDoSCharacteristic != nil && commandsCharacteristic != nil && responseCharacteristic != nil {
            peripheral.writeValue(Data("011i3".utf8), for: antiDoSCharacteristic, type: .withResponse)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic === responseCharacteristic {
            if let error = error {
                //preparationCallback?(false, .peripheralFailed(error: error))
                preparationCallback = nil
                return
            }
            
            // Send a versioning comment to try to start the connection.
            send(VersioningCommand())
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
            peripheral.writeValue(Data(bytes: [7]), for: txPowerCharacteristic, type: .withResponse)
        } else if characteristic === txPowerCharacteristic {
            peripheral.writeValue(Data(bytes: [1]), for: wakeCharacteristic, type: .withResponse)
        } else if characteristic === wakeCharacteristic {
            peripheral.setNotifyValue(true, for: responseCharacteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        if let error = error {
            //preparationCallback?(false, .peripheralFailed(error: error))
            preparationCallback = nil
            return
        }
        
        guard characteristic === responseCharacteristic, let response = characteristic.value else { return }
        commandSequencer.parseResponseFromToy(response) { [unowned self] (sequencer, commandResponse) in
            switch commandResponse {
            case let versionsCommandResponse as VersionsCommandResponse:
                self.appVersion = versionsCommandResponse.appVersion
                self.asyncListeners.forEach { $0.value?.toyCore(self, didReceiveDeviceResponse: versionsCommandResponse) }
                self.send(PowerStateCommand())
                
            case let powerState as PowerStateResponse:
                self.batteryVoltage = powerState.batteryVoltage
                self.preparationCallback?(true, nil)
                self.preparationCallback = nil
                
                self.asyncListeners.forEach { $0.value?.toyCore(self, didReceiveDeviceResponse: powerState) }
                
            case let asyncCommandResponse as AsyncCommandResponse:
                self.asyncListeners.forEach { $0.value?.toyCore(self, didReceiveAsyncResponse: asyncCommandResponse) }
                
            case let deviceCommandResponse as DeviceCommandResponse:
                self.asyncListeners.forEach { $0.value?.toyCore(self, didReceiveDeviceResponse: deviceCommandResponse) }
                
            default:
                break
            }
        }
        
    }
}
