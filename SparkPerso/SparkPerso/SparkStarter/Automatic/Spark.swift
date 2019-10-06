//
//  Spark.swift
//  SparkPerso
//
//  Created by AL on 22/01/2019.
//  Copyright © 2019 AlbanPerli. All rights reserved.
//

import Foundation
import DJISDK

class Spark {
    static let instance = Spark()
    var airCraft:DJIAircraft? {
        didSet{
            
        }
    }
    
    func move(movement:Movement) {
        stop()
        if let mySpark = self.airCraft {
            mySpark.mobileRemoteController?.rightStickVertical = movement.rightStickVerticalValue()
            mySpark.mobileRemoteController?.rightStickHorizontal = movement.rightStickVerticalValue()
            
        }
    }
    
    func stop() {
        if let mySpark = self.airCraft {
            mySpark.mobileRemoteController?.leftStickVertical = 0.0
            mySpark.mobileRemoteController?.leftStickHorizontal = 0.0
            mySpark.mobileRemoteController?.rightStickHorizontal = 0.0
            mySpark.mobileRemoteController?.rightStickVertical = 0.0
        }
    }
}
