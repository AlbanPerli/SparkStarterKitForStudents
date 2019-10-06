//
//  SensorControlViewController.swift
//  SparkPerso
//
//  Created by AL on 01/09/2019.
//  Copyright © 2019 AlbanPerli. All rights reserved.
//

import UIKit
import simd

class SpheroSensorControlViewController: UIViewController {

    @IBOutlet weak var gyroChart: GraphView!
    @IBOutlet weak var acceleroChart: GraphView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        SharedToyBox.instance.bolt?.sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .accelerometer,.gyro))
        SharedToyBox.instance.bolt?.sensorControl.interval = 1
        SharedToyBox.instance.bolt?.setStabilization(state: SetStabilization.State.off)
        
        SharedToyBox.instance.bolt?.sensorControl.onDataReady = { data in
            DispatchQueue.main.async {
                if let acceleration = data.accelerometer?.filteredAcceleration {
                    // PAS BIEN!!!
                    let dataToDisplay: double3 = [acceleration.x!, acceleration.y!, acceleration.z!]
                    
                    self.acceleroChart.add(dataToDisplay)
                }
                
                if let gyro = data.gyro?.rotationRate {
                    // TOUJOURS PAS BIEN!!!
                    let rotationRate: double3 = [Double(gyro.x!), Double(gyro.y!), Double(gyro.z!)]
                    self.gyroChart.add(rotationRate)
                }
            }
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        SharedToyBox.instance.bolt?.sensorControl.disable()
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
