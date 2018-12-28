//
//  TakeOffAndLandingViewController.swift
//  SparkPerso
//
//  Created by AL on 14/01/2018.
//  Copyright © 2018 AlbanPerli. All rights reserved.
//

import UIKit
import DJISDK

class TakeOffAndLandingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func landingButtonClicked(_ sender: UIButton) {
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            if let flightController = mySpark.flightController {
                flightController.startLanding(completion: { (err) in
                    print(err.debugDescription)
                })
            }
        }
    }
    
    @IBAction func takeOffButtonClicked(_ sender: UIButton) {
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            if let flightController = mySpark.flightController {
                flightController.startTakeoff(completion: { (err) in
                    print(err.debugDescription)
                })
            }
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
