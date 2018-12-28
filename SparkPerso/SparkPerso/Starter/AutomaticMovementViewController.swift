//
//  AutomaticMovementViewController.swift
//  SparkPerso
//
//  Created by AL on 23/02/2018.
//  Copyright © 2018 AlbanPerli. All rights reserved.
//

import UIKit
import DJISDK

class AutomaticMovementViewController: UIViewController {

    @IBOutlet weak var launchButton: UIButton!
    
    let manager = MovementManager()
    var canSendCommand = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        manager.stateChanged = { isRunning in
            
            self.launchButton.isEnabled = !isRunning
            
        }
        
        manager.emitMovement = { mov in
            
            if self.canSendCommand {
               self.sendCommand(mov: mov)
            }
        }
        
        // Read a json
        if let filepath = Bundle.main.path(forResource: "Scenar", ofType: "json") {
            do {
                let contents = try String(contentsOfFile: filepath)
                
                let json = JSON(parseJSON: contents)
                let scenar = Scenarios(json: json)
                for info in scenar.infos!{
                    print(info.dictionaryRepresentation())
                    
                }
                
            } catch {
                // contents could not be loaded
            }
        } else {
            // example.txt not found!
        }

        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func launchProcess(_ sender: UIButton) {
        
        canSendCommand = true
        manager.launchProcess()
    }
    
    
    @IBAction func alertButtonClicked(_ sender: UIButton) {
        canSendCommand = false
        sendCommand(mov: manager.makeStopMovement())
        manager.isRunning = false
    }
    
    func sendCommand(mov:Movement) {
        
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            
            for direction in mov.directions {
                
                var value = direction.impulse
                switch direction.type {
                    case .forward : break
                    case .backward : value = value*(-1)
                }
                
                switch direction.axe {
                case .rightStickHorizontal:
                        mySpark.mobileRemoteController?.rightStickHorizontal = value
                        mySpark.mobileRemoteController?.rightStickVertical = 0.0
                case .rightStickVertical:
                        mySpark.mobileRemoteController?.rightStickVertical = value
                        mySpark.mobileRemoteController?.rightStickHorizontal = 0.0
                case .z: break
                }

                
            }
            
        }
        
        for dir in mov.directions {
         print("Move on axe \(dir.axe) \(dir.type) \(dir.impulse) : in \(mov.duration)s")
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
