//
//  ViewController.swift
//  SparkPerso
//
//  Created by AL on 14/01/2018.
//  Copyright © 2018 AlbanPerli. All rights reserved.
//

import UIKit
import DJISDK


class ConnectionViewController: UIViewController {
    
    @IBOutlet weak var connectionStateSpheroLabel: UILabel!
    @IBOutlet weak var connectionStateLabel: UILabel!
    let SSID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DJISDKManager.keyManager()?.stopAllListening(ofListeners: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func connectionButtonClicked(_ sender: UIButton) {
        trySparkConnection()
    }
    
    // SPHERO CONNECTION
    @IBAction func connectionSpheroButtonClicked(_ sender: Any) {
        SharedToyBox.instance.searchForBoltsNamed(["SB-A729","SB-92B2","SB-8630"]) { err in
            if err == nil {
                self.connectionStateSpheroLabel.text = "Connected"
            }
        }
    }
    
}


// SPARK CONNECTION
extension ConnectionViewController {
    func trySparkConnection() {
        
        guard let connectedKey = DJIProductKey(param: DJIParamConnection) else {
            NSLog("Error creating the connectedKey")
            return;
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            DJISDKManager.keyManager()?.startListeningForChanges(on: connectedKey, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue : DJIKeyedValue?) in
                if let newVal = newValue {
                    if newVal.boolValue {
                         DispatchQueue.main.async {
                            self.productConnected()
                        }
                    }
                }
            })
            DJISDKManager.keyManager()?.getValueFor(connectedKey, withCompletion: { (value:DJIKeyedValue?, error:Error?) in
                if let unwrappedValue = value {
                    if unwrappedValue.boolValue {
                        // UI goes on MT.
                        DispatchQueue.main.async {
                            self.productConnected()
                        }
                    }
                }
            })
        }
    }
    
   
    
    func productConnected() {
        guard let newProduct = DJISDKManager.product() else {
            NSLog("Product is connected but DJISDKManager.product is nil -> something is wrong")
            return;
        }
     
        if let model = newProduct.model {
            self.connectionStateLabel.text = "\(model) is connected \n"
            Spark.instance.airCraft = DJISDKManager.product() as? DJIAircraft
            
        }
        
        //Updates the product's firmware version - COMING SOON
        newProduct.getFirmwarePackageVersion{ (version:String?, error:Error?) -> Void in
            
            if let _ = error {
                self.connectionStateLabel.text = self.connectionStateLabel.text! + "Firmware Package Version: \(version ?? "Unknown")"
            }else{
                
            }
            
            print("Firmware package version is: \(version ?? "Unknown")")
        }
        
    }
    
    func productDisconnected() {
        self.connectionStateLabel.text = "Disconnected"
        print("Disconnected")
    }
}

