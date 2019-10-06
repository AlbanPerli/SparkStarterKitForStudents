//
//  CommandOperation.swift
//  SpheroSDK
//
//  Created by Jeff Payan on 2017-03-15.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import CoreBluetooth

class CommandOperationV2: Operation {
    
    let command: CommandV2
    let commandSequencer: CommandSequencerV2
    
    weak var toyCore: SpheroV2ToyCore?
    weak var characteristic: CBCharacteristic?
    
    private var _finished = false // Our read-write mirror of the super's read-only finished property
    private var _executing = false // Our read-write mirror of the super's read-only executing property
    
    public init(_ command: CommandV2, toyCore: SpheroV2ToyCore, commandSequencer: CommandSequencerV2, characteristic: CBCharacteristic) {
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
        let data = Array(commandSequencer.data(from: command))
        let chunks = data.chunked(by: 20)
        var index = 0
        
        toyCore.onCharacteristicWrite = { [unowned self] (peripheral, characteristic, error) in
            if (index == chunks.count - 1) {
                self.isExecuting = false
                self.isFinished = true
            } else {
                index += 1
                toyCore.writeValue(Data(bytes: chunks[index]), for: characteristic, type: .withResponse)
            }

        }
        
        toyCore.writeValue(Data(bytes: chunks[index]), for: characteristic, type: .withResponse)
    }
}
