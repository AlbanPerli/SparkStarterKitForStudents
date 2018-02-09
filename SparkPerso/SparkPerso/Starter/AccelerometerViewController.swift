//
//  AccelerometerViewController.swift
//  SparkPerso
//
//  Created by AL on 04/02/2018.
//  Copyright © 2018 AlbanPerli. All rights reserved.
//

import UIKit
import CoreMotion
import DJISDK

// Resources: https://www.hackingwithswift.com/example-code/system/how-to-use-core-motion-to-read-accelerometer-data
// CoreMotion documentation:
// https://developer.apple.com/documentation/coremotion
// https://developer.apple.com/documentation/coremotion/cmmotionmanager

class AccelerometerViewController: UIViewController {

    var rotateLeftTimer:Timer? = nil
    var rotateRightTimer:Timer? = nil
    
    // The 'Movement' struct is the same in MovementLevelOneViewController and AccelerometerViewController
    // Maybe we can build a Kind of CommandManager?
    // Maybe a 'Spark Entity' with a CommandManager,TakeOffManager,HeadingManager,StatusManager...
    // Maybe a 'BrainManager' for the 'Spark Entity'
    // An array of 'Movement' could be considered as a path for the Spark
    // Using a combination of time + speed + this path + A* algorithm could lead to a self driven Spark...
    
    let commonValue:Float = 0.5
    
    struct Movement {
        
        enum MovementType {
            case forward,backward,left,right,up,down,rotateLeft,rotateRight
        }
        
        var value:Float
        var type:MovementType
    }
    
    @IBOutlet weak var startStopButton: UIButton!
    var motionManager: CMMotionManager!
    var sendCommands = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDel = UIApplication.shared.delegate as! AppDelegate
        appDel.myOrientation = .landscapeLeft
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
        
        motionManager = CMMotionManager()

        // Gyro updates
//        motionManager.startGyroUpdates(to: OperationQueue.main) { (gyroDatas, error) in
//
//            guard error == nil else { print("Manage Motion Manager error!"); return }
//
//
//        if let data = gyroDatas {
//            print(data.rotationRate)
//        }
//
//
//
//        }
        
        
        motionManager.startAccelerometerUpdates(to: OperationQueue.main) { (accelerometerDatas, error) in
            
            guard error == nil else { print("Manage Motion Manager error!"); return }
            
            if self.sendCommands {
                if let data = accelerometerDatas {
                    self.sendCommandForAccelerometerDatas(data)
                }
            }
            
            
        }
       
        // Everything in one place
        // Core Motion documentation:
        //
//        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { (motion, error) in
//            guard error == nil else { print("Manage Motion Manager error!"); return }
//
//            if let datas = motion {
//                // datas. // uncomment and press escape after the dot '.'
//            }
//
//        }
       
        updateButtonLabel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let appDel = UIApplication.shared.delegate as! AppDelegate
        appDel.myOrientation = .portrait
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
   
    @IBAction func startStopButtonClicked(_ sender: UIButton) {
        
        sendCommands = !sendCommands
        if sendCommands == false {
            stop()
            clearTimers()
        }
        updateButtonLabel()
        
    }
    
    @IBAction func touchEndOnLeftButton(_ sender: UIButton) {
        clearTimers()
        stopRotations()
    }
    
    @IBAction func rotateLeftButtonClicked(_ sender: UIButton) {
        print("test left")
        clearTimers()
        
        rotateLeftTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (t) in
            print("Send rotate right")
            self.sendCommand(Movement(value: self.commonValue, type: .rotateLeft))
        })
        
    }
    
    
    @IBAction func touchEndOnRightButton(_ sender: UIButton) {
        clearTimers()
        stopRotations()
    }
    
    @IBAction func rotateRightButtonClicked(_ sender: UIButton) {
        
        clearTimers()
        
        rotateRightTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (t) in
            print("Send rotate right")
            self.sendCommand(Movement(value: self.commonValue, type: .rotateRight))
        })
        
    }
    
    func resetLeftTimer() {
        if let timer = rotateLeftTimer{
            timer.invalidate()
            rotateLeftTimer = nil
        }
    }
    
    func resetRightTimer() {
        if let timer = rotateRightTimer {
            timer.invalidate()
            rotateRightTimer = nil
        }
    }
    
    func clearTimers() {
        resetLeftTimer()
        resetRightTimer()
    }
    
    func updateButtonLabel() {
        if sendCommands {
            self.startStopButton.setTitle("STOP", for: UIControlState.normal)
        }else{
            self.startStopButton.setTitle("START", for: UIControlState.normal)
        }
    }
    
    
    func sendCommandForAccelerometerDatas(_ datas:CMAccelerometerData) {
       
        // Considering the mobile device is landscape left
        // x = 0 -> phone on a table
        // from -0.5 To -1: go forward
        // 0.5 To 1: go backward
        // y = 0 -> phone on a table
        // from 0.5 To 1: go "Right"
        // -0.5 To -1: go "Left"
        
        if datas.acceleration.x <= -0.4
            && datas.acceleration.x >= -1.0 {
            sendCommand(Movement(value: commonValue, type: .forward))
        }else if datas.acceleration.x >= 0.4
            && datas.acceleration.x <= 1.0 {
            sendCommand(Movement(value: -commonValue, type: .backward))
        }else{
            self.stopRightStickHorizontal()
        }
        
        if datas.acceleration.y <= -0.4
            && datas.acceleration.y >= -1.0 {
            sendCommand(Movement(value: commonValue, type: .left))
        }else if datas.acceleration.y >= 0.4
            && datas.acceleration.y <= 1.0 {
            sendCommand(Movement(value: -commonValue, type: .right))
        }else{
            self.stopRightStickVertivcal()
        }
        
    }
    
    func sendCommand(_ movement:Movement) {
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            switch movement.type {
            case .forward,.backward:
                print("Forward,Backward \(movement.value)")
                mySpark.mobileRemoteController?.rightStickVertical = movement.value
            case .left,.right:
                mySpark.mobileRemoteController?.rightStickHorizontal = movement.value
                print("Left,Right \(movement.value)")
            case .up,.down:
                mySpark.mobileRemoteController?.leftStickVertical = movement.value
                print("Up,Down \(movement.value)")
            case .rotateLeft,.rotateRight:
                print("RotateLeft,RotateRight \(movement.value)")
                mySpark.mobileRemoteController?.leftStickHorizontal = movement.value
                break
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
    
    func stopRightStickHorizontal() {
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            mySpark.mobileRemoteController?.rightStickHorizontal = 0.0
        }
    }
    
    func stopRightStickVertivcal() {
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            mySpark.mobileRemoteController?.rightStickVertical = 0.0
        }
    }
    
    func stopRotations() {
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            mySpark.mobileRemoteController?.leftStickHorizontal = 0.0
        }
    }
    
   
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
