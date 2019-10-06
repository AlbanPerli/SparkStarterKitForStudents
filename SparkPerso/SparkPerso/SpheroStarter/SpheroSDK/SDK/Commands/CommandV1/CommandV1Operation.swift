//
//  CommandOperation.swift
//  SpheroSDK
//
//  Created by Jeff Payan on 2017-03-15.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import CoreBluetooth

class CommandOperation: Operation {
    
    let command: CommandV1
    let commandSequencer: CommandSequencerV1
    
    weak var toyCore: SpheroV1ToyCore?
    weak var characteristic: CBCharacteristic?

    private var _finished = false // Our read-write mirror of the super's read-only finished property
    private var _executing = false // Our read-write mirror of the super's read-only executing property
    
    public init(_ command: CommandV1, toyCore: SpheroV1ToyCore, commandSequencer: CommandSequencerV1, characteristic: CBCharacteristic) {
        self.command = command
        self.commandSequencer = commandSequencer

        self.toyCore = toyCore
        self.characteristic = characteristic
        
        super.init()
    }
    
    override var isExecuting: Bool {
        get { return _executing }
        set {
            willChangeValue(forKey:"isExecuting")
            _executing = newValue
            didChangeValue(forKey:"isExecuting")
        }
    }
    
    override var isFinished: Bool {
        get { return _finished }
        set {
            willChangeValue(forKey: "isFinished")
            _finished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override func start() {
        if isCancelled {
            isFinished = true
            return
        }
        
        isExecuting = true
        
        guard let toyCore = toyCore, let characteristic = characteristic else { isFinished = true; return }
        
        toyCore.onCharacteristicWrite =  { [unowned self] (peripheral, characteristic, error) in
            self.isExecuting = false
            self.isFinished = true
        }
        
        toyCore.writeValue(commandSequencer.data(from: command), for: characteristic, type: .withResponse)
    }
}
