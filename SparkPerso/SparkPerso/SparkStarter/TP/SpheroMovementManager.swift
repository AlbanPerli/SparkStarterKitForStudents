//
//  SpheroMovementManager.swift
//  SparkPerso
//
//  Created by AL on 18/10/2019.
//  Copyright © 2019 AlbanPerli. All rights reserved.
//

import Foundation

class SpheroMovementManager:GenericMovementManager {
    
    override func playMove(move: BasicMove, moveDidFinish: @escaping (() -> ())) {
        talkWithSDK(move: move)
        if move.durationInSec > 3.0 {
            
            delay(1.0) {
                self.talkWithSDK(move: move)
                delay(1.0) {
                    moveDidFinish()
                }
            }
        }else{
            delay(move.durationInSec) {
                moveDidFinish()
            }
        }
    }
    
    func recursiveSending(move:BasicMove, duration:Float) {
        /*
        if duration == 0.0 {
            finishedCallBack()
        }else{
            delay(duration) {
                self.talkWithSDK(move: move)
            }
        }
         */ 
    }
    
    func talkWithSDK(move:BasicMove) {
        print("Move from Sphero SDK")
        SharedToyBox.instance.bolt?.roll(heading: move.heading, speed: Double(move.speed))
    }
}
