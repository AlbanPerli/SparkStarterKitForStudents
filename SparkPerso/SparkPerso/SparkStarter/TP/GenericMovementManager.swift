//
//  GenericMovementManager.swift
//  SparkPerso
//
//  Created by AL on 18/10/2019.
//  Copyright © 2019 AlbanPerli. All rights reserved.
//

import Foundation

class GenericMovementManager {
    
    var sequence:[BasicMove]
    var stopAll:Bool = false
    
    init(sequence:[BasicMove]) {
        self.sequence = sequence
    }
    
    func sequenceDescription() -> String {
        
        var fullDescription = ""
        
        // let str = sequence.map{ $0.description }.joined(separator: "\n")
        
        for move in sequence {
            fullDescription += "\(move.description)\n"
        }
        
        return fullDescription
    }
    
    func clearSequence() {
        self.sequence = []
    }
    
    func redAlert() {
        clearSequence()
        stopAll = true
        print("!!!!!!!! RED ALERT !!!!!!!!")
        playMove(move: Stop()) {
            print("Secure stop is send")
        }
    }
    
    func playSequence() {
        self.startSequence(sequence: self.sequence)
    }
    
    func startSequence(sequence:[BasicMove]) {
        
        if sequence.count == 0 || stopAll {
            print("Sequence finished")
        }else{
            if let move = sequence.first {
                playMove(move: move) {
                    print("Move Did finish")
                    print("Remove Movement from sequence")
                    let seqMinusFirst = Array(sequence.dropFirst())
                    self.startSequence(sequence: seqMinusFirst)
                }
            }
        }
        
    }

    func playMove(move:BasicMove, moveDidFinish:@escaping (()->()))  {
        print(move.description)
        delay(move.durationInSec) {
            moveDidFinish()
        }
    }
    
}
