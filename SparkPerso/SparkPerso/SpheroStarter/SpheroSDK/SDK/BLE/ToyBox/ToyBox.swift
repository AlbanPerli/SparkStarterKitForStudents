//
//  ToyBox.swift
//  SpheroSDK
//
//  Created by Jeff Payan on 2017-03-08.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import CoreBluetooth

public enum ConnectionError: Error {
    case noToyFound
    case peripheralFailed(error: Error?)
}

public protocol ToyBoxListener: class {
    func toyBoxReady(_ toyBox: ToyBox)
    func toyBox(_ toyBox: ToyBox, discovered descriptor: ToyDescriptor)
    func toyBox(_ toyBox: ToyBox, readied toy: Toy)
    func toyBox(_ toyBox: ToyBox, putAway toy: Toy)
}

public struct ToyDescriptor {
    let name: String?
    let identifier: UUID
    let peripheral:CBPeripheral!
    let rssi: Int?
    let advertisedPower: Int?
    
    private let disasociationLevel = 96.0
    public func signalStrength() -> Int {
        guard let rssi = rssi else { return 0 }
        
        let advertisementPowerFactor = advertisedPower == -10 ? 48.0 : 30.0
        let ratio =  1.0 / -(disasociationLevel - advertisementPowerFactor)
        var logSignalQuality = (1.0 - (disasociationLevel + Double(rssi))) * ratio
        
        if logSignalQuality > 1.0 {
            logSignalQuality = 1.0
        }
        
        return Int(logSignalQuality * 100.0)
    }
}

public final class ToyBox:NSObject {
    
    class ToyBoxListenerWeakWrapper {
        weak var value: ToyBoxListener?
        
        init(value: ToyBoxListener) {
            self.value = value
        }
    }
    
    private var listeners: [ToyBoxListenerWeakWrapper] = []
    
    public func addListener(_ listener: ToyBoxListener) {
        if !listeners.contains() { $0 === listener } {
            listeners.append(ToyBoxListenerWeakWrapper(value: listener))
        }
    }
    
    public func removeListener(_ listener: ToyBoxListener) {
        guard let index = listeners.index(where: {$0 === listener }) else { return }
        listeners.remove(at: index)
    }
    
    private var queue = DispatchQueue(label: "com.sphero.sdk.queue")
    
    public var centralManager: CBCentralManager!
    
    private var connectedToys: [UUID: Toy] = [:]
    
    public override init() {
        super.init()
    }
    
    func start() {
        self.centralManager = CBCentralManager(delegate: self, queue: queue)
    }
    
    func startScan() {
        self.centralManager.scanForPeripherals(withServices: [SpheroV1Services.robotControlService, SpheroV2Services.apiV2ControlService], options: nil)
    }
    
    func stopScan() {
        self.centralManager.stopScan()
    }
    
    func putAway(toy: Toy) {
        toy.putAway()
    }
    
    func disconnect(toy: Toy) {
        guard let toy = connectedToys[toy.identifier], let peripheral = toy.peripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func connect(toy: Toy) {
        centralManager.connect(toy.peripheral!, options: nil)
    }
    
}

extension ToyBox:CBCentralManagerDelegate{

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard let toy = connectedToys[peripheral.identifier] else { return }
        
        connectedToys[peripheral.identifier] = nil
        
        listeners.forEach { $0.value?.toyBox(self, putAway: toy) }
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            listeners.forEach { $0.value?.toyBoxReady(self) }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    
        let rssi = RSSI.doubleValue
        guard rssi < 0.0 && rssi > -70.0 else { return }
        
        let toyDescriptor = ToyDescriptor(name: peripheral.name, identifier: peripheral.identifier, peripheral: peripheral, rssi: Int(rssi), advertisedPower: 38)
        listeners.forEach { $0.value?.toyBox(self, discovered: toyDescriptor) }
        
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let peripheralName = peripheral.name else { fatalError("Peripheral had no name") }
        
        var toy: Toy?
        switch peripheralName {
        case let sprk where (sprk.hasPrefix(SPRKToy.descriptor)):
            toy = SPRKToy(peripheral: peripheral, owner: self)
        case let mini where (mini.hasPrefix(MiniToy.descriptor)):
            toy = MiniToy(peripheral: peripheral, owner: self)
        case let bolt where (bolt.hasPrefix(BoltToy.descriptor)):
            toy = BoltToy(peripheral: peripheral, owner: self, commandSequencer: CommandSequencerV21())
        case let bb8 where (bb8.hasPrefix(BB8Toy.descriptor)):
            toy = BB8Toy(peripheral: peripheral, owner: self)
            
        case let bb9e where (bb9e.hasPrefix(BB9EToy.descriptor)):
            toy = BB9EToy(peripheral: peripheral, owner: self)
            
        case let r2d2 where (r2d2.hasPrefix(R2D2Toy.descriptor)):
            toy = R2D2Toy(peripheral: peripheral, owner: self)
            
        default:
            break
        }
        
        guard let returnToy = toy else { fatalError("Could not make toy from peripheral") }
        
        returnToy.connect { didPrepareConnection, error in
            if didPrepareConnection {
                self.connectedToys[peripheral.identifier] = returnToy
                self.listeners.forEach { $0.value?.toyBox(self, readied: returnToy) }
            } else {
                central.cancelPeripheralConnection(peripheral)
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectedToys[peripheral.identifier] = nil
    }
    
    
}
