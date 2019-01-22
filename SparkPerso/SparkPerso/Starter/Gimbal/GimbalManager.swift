//
//  GimbalManager.swift
//  SparkPerso
//
//  Created by AL on 21/01/2019.
//  Copyright © 2019 AlbanPerli. All rights reserved.
//

import UIKit
import DJISDK

public class GimbalManager {
    
    var gimbal: DJIGimbal?
    var front:Float = 90.0
    var under:Float = -90.0
    var defaultPitch: NSNumber = 0
    private var speed: TimeInterval?
    var ready = false
    
    static let shared = GimbalManager()
    
    func setup(withDuration duration: TimeInterval, defaultPitch defaultPitchRotation: NSNumber = 0) {
        
        speed = duration
        gimbal = getGimbal()
        
        gimbal?.setMode(DJIGimbalMode.free, withCompletion: { (err) in
            self.ready = true
        })
        
    }
    
    private func getGimbal() -> DJIGimbal? {
        if let spark = DJISDKManager.product() as? DJIAircraft {
            if let gimbal = spark.gimbal {
                gimbal.delegate = self as? DJIGimbalDelegate
                
                return gimbal
            }
            
            return nil
        }
        
        return nil
    }
    
    
    func rotate(degrees: Float) {
  
        let rotation = DJIGimbalRotation(pitchValue: NSNumber(value: degrees), rollValue: 0, yawValue: 0, time: self.speed!, mode: DJIGimbalRotationMode.relativeAngle)
        
        self.gimbal!.rotate(with: rotation, completion: { err in
            if err != nil {
                print("Error while rotating gimbal : \(String(describing: err))")
            }
        })
        
    }
    
    func lookFront() {
        rotate(degrees: front)
    }
    
    func lookUnder() {
        rotate(degrees: under)
    }
    
    func resetGimbal(){
        self.gimbal!.reset { (err) in
            
        }
    }
}

