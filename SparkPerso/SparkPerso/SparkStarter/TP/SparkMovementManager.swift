//
//  SparkMovementManager.swift
//  SparkPerso
//
//  Created by AL on 18/10/2019.
//  Copyright © 2019 AlbanPerli. All rights reserved.
//

import Foundation
import DJISDK

class SparkMovementManager:GenericMovementManager {
    
    override init(sequence:[BasicMove]) {
        super.init(sequence: sequence)
        self.sequence.append(Stop())
    }
    
    override func playMove(move: BasicMove, moveDidFinish: @escaping (() -> ())) {
        talkWithSDK(move: move)
        delay(move.durationInSec) {
            moveDidFinish()
        }
        
    }
    
    func talkWithSDK(move:BasicMove) {
        
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            mySpark.mobileRemoteController?.leftStickVertical = 0.0
            mySpark.mobileRemoteController?.leftStickHorizontal = 0.0
            mySpark.mobileRemoteController?.rightStickHorizontal = 0.0
            mySpark.mobileRemoteController?.rightStickVertical = 0.0
            
            let speed = move.speed
            
            switch move {
            case is Front:
                mySpark.mobileRemoteController?.rightStickVertical = speed
            case is RotateLeft:
                mySpark.mobileRemoteController?.leftStickHorizontal = -speed
            case is RotateRight:
                mySpark.mobileRemoteController?.leftStickHorizontal = speed
            case is Rotate90Right:
                mySpark.mobileRemoteController?.leftStickHorizontal = speed
            case is Rotate90Left:
                mySpark.mobileRemoteController?.leftStickHorizontal = -speed
            default: break
            }
            
            
        }
    }
}
