//
//  SpheroDirectionViewController.swift
//  SparkPerso
//
//  Created by AL on 01/09/2019.
//  Copyright © 2019 AlbanPerli. All rights reserved.
//

import UIKit

class SpheroDirectionViewController: UIViewController {

    
    var currentSpeed:Double = 0 {
        didSet{
            displayCurrentState()
        }
    }
    var currentHeading:Double = 0 {
        didSet{
            displayCurrentState()
        }
    }
    
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var collisionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nbBolts = SharedToyBox.instance.bolts.count
        var boltCollision = [Bool]()
        
        SharedToyBox.instance.bolts.map{
            $0.setStabilization(state: SetStabilization.State.on)
            $0.setCollisionDetection(configuration: .enabled)
        }
        SharedToyBox.instance.bolts.map{
            $0.onCollisionDetected = { collisionData in
                boltCollision.append(true)
                DispatchQueue.main.sync {
                    if nbBolts == boltCollision.count {
                        print("Collision de 2 bolts")
                    }else{
                        delay(0.5) {
                            boltCollision = []
                        }
                    }
                    self.collisionLabel.text = "Aïe!!!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.collisionLabel.text = ""
                    }
                }
            }
        }
        
        SharedToyBox.instance.bolt?.sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .accelerometer))
        SharedToyBox.instance.bolt?.sensorControl.interval = 1
        SharedToyBox.instance.bolt?.setStabilization(state: SetStabilization.State.off)
        //SharedToyBox.instance.bolt?.sensorControl.onDataReady = { data in
           // print(data.accelerometer!)
        //}
    }
    
    func displayCurrentState() {
        stateLabel.text = "Current Speed: \(currentSpeed.rounded())\nCurrent Heading: \(currentHeading.rounded())"
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        currentSpeed = Double(sender.value)
    }
    
    @IBAction func headingValueChanged(_ sender: UISlider) {
        currentHeading = Double(sender.value)
        SharedToyBox.instance.bolts.map{ $0.stopRoll(heading: currentHeading) }
        //SharedToyBox.instance.bolt?.stopRoll(heading: currentHeading)
    }
    
    @IBAction func frontClicked(_ sender: Any) {
        SharedToyBox.instance.bolts.map{ $0.roll(heading: currentHeading, speed: currentSpeed) }
//        SharedToyBox.instance.bolt?.roll(heading: currentHeading, speed: currentSpeed)
    }
    
    @IBAction func leftClicked(_ sender: Any) {
        currentHeading += 30.0
        SharedToyBox.instance.bolts.map{ $0.roll(heading: currentHeading, speed: currentSpeed) }
//        SharedToyBox.instance.bolt?.roll(heading: currentHeading, speed: currentSpeed)
    }
    
    @IBAction func rightClicked(_ sender: Any) {
        currentHeading -= 30.0
        SharedToyBox.instance.bolts.map{ $0.roll(heading: currentHeading, speed: currentSpeed) }
//        SharedToyBox.instance.bolt?.roll(heading: currentHeading, speed: currentSpeed)
    }
    
    @IBAction func backClicked(_ sender: Any) {
        SharedToyBox.instance.bolts.map{ $0.roll(heading: currentHeading, speed: currentHeading, rollType: .roll, direction: .reverse) }
//         SharedToyBox.instance.bolt?.roll(heading: currentHeading, speed: currentHeading, rollType: .roll, direction: .reverse)
    }
    
    @IBAction func stopClicked(_ sender: Any) {
        SharedToyBox.instance.bolts.map{ $0.stopRoll(heading: currentHeading) }
//        SharedToyBox.instance.bolt?.stopRoll(heading: currentHeading)
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
