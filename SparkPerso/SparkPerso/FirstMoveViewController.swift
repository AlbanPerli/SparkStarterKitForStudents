//
//  FirstMoveViewController.swift
//  SparkPerso
//
//  Created by Alban on 23/09/2020.
//  Copyright © 2020 AlbanPerli. All rights reserved.
//

import UIKit
import DJISDK
class FirstMoveViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func stopOnUp(_ sender: Any) {
        
    }
    @IBAction func frontClicked(_ sender: Any) {
        print("front clicked")
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            mySpark.mobileRemoteController?.rightStickVertical = 0.5
        }

    }
    
    @IBAction func lefftClicked(_ sender: Any) {
        print("left clicked")
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            mySpark.mobileRemoteController?.rightStickHorizontal = -0.5
        }

    }
    
    @IBAction func rightClicked(_ sender: Any) {
        print("right clicked")
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            mySpark.mobileRemoteController?.rightStickHorizontal = 0.5
        }
    }
    
    @IBAction func backClicked(_ sender: Any) {
        print("back clicked")
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            mySpark.mobileRemoteController?.rightStickVertical = -0.5
        }
    }
    
    
    @IBAction func stopClicked(_ sender: UIButton) {
        print("Stop clicked")
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            mySpark.mobileRemoteController?.leftStickVertical = 0.0
            mySpark.mobileRemoteController?.leftStickHorizontal = 0.0
            mySpark.mobileRemoteController?.rightStickHorizontal = 0.0
            mySpark.mobileRemoteController?.rightStickVertical = 0.0
        }
    }
    
    @IBAction func takeOffClicked(_ sender: Any) {
        print("takeoff clicked")
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            if let flightController = mySpark.flightController {
                flightController.startTakeoff(completion: { (err) in
                    print(err.debugDescription)
                })
            }
        }
    }
    
    @IBAction func landingClicked(_ sender: Any) {
        print("landing clicked")
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            if let flightController = mySpark.flightController {
                flightController.startLanding(completion: { (err) in
                    print(err.debugDescription)
                })
            }
        }
    }
    
    @IBAction func upClicked(_ sender: Any) {
        print("UP clicked")
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            mySpark.mobileRemoteController?.leftStickVertical = 0.5
        }
    }
    
    @IBAction func downClicked(_ sender: Any) {
        print("Down clicked")
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            mySpark.mobileRemoteController?.leftStickVertical = -0.5
        }
    }
    
    @IBAction func startSeqClicked(_ sender: Any) {
        move(moves: [Move(duration: 2.0, speed: 0.5),
                     Move(duration: 1.0, speed: 0.9),
                     Move(duration: 3.0, speed: -0.5)])
    }
    
    struct Move {
        var duration:Double
        var speed:Float
    }
    func move(moves:[Move]) {
        
        var localMoves = moves
        print(localMoves)
        print(localMoves.first?.duration)
        if moves.count > 0 {
            if let currentMove = localMoves.first{
                print("Mouvement \(currentMove.duration)")
                DispatchQueue.main.asyncAfter(deadline: .now() + currentMove.duration) {
                    print("Stop")
                    localMoves.remove(at: 0)
                    self.move(moves: localMoves)
                }
            }
        }else{
            print("Finito")
        }
        
        SeqManager.instance.clear()
        
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
