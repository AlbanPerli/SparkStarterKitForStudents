//
//  MovementLevelOneViewController.swift
//  SparkPerso
//
//  Created by AL on 14/01/2018.
//  Copyright © 2018 AlbanPerli. All rights reserved.
//

import UIKit
import DJISDK

class MovementLevelOneViewController: UIViewController {

    let commonValue:Float = 0.5
    
    struct Movement {

        enum MovementType {
            case forward,backward,left,right,up,down
        }

        var value:Float
        var type:MovementType
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func stop(_ sender: UIButton) {
        stop()
    }
    
    @IBAction func forward(_ sender: UIButton) {
        let mov = Movement(value: commonValue, type: .forward)
        sendCommand(mov)
    }
    
    @IBAction func backward(_ sender: UIButton) {
        sendCommand(Movement(value: -commonValue, type: .backward))
    }
    
    @IBAction func left(_ sender: Any) {
        sendCommand(Movement(value: -commonValue, type: .left))
    }
    
    @IBAction func right(_ sender: UIButton) {
        sendCommand(Movement(value: commonValue, type: .right))
    }
    
    @IBAction func moveUp(_ sender: UIButton) {
        sendCommand(Movement(value: commonValue, type: .up))
    }
    
    @IBAction func moveDown(_ sender: UIButton) {
        sendCommand(Movement(value: -commonValue, type: .down))
    }
    
    func sendCommand(_ movement:Movement) {
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            switch movement.type {
            case .forward,.backward:
                mySpark.mobileRemoteController?.rightStickVertical = movement.value
            case .left,.right:
                mySpark.mobileRemoteController?.rightStickHorizontal = movement.value
            case .up,.down:
                mySpark.mobileRemoteController?.leftStickVertical = movement.value
            }
        }
    }
    
    func stop() {
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            mySpark.mobileRemoteController?.leftStickVertical = 0.0
            mySpark.mobileRemoteController?.leftStickHorizontal = 0.0
            mySpark.mobileRemoteController?.rightStickHorizontal = 0.0
            mySpark.mobileRemoteController?.rightStickVertical = 0.0
        }
    }
}
