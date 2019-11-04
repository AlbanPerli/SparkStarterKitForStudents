//
//  TP1ViewController.swift
//  SparkPerso
//
//  Created by AL on 17/10/2019.
//  Copyright © 2019 AlbanPerli. All rights reserved.
//

import UIKit
import DJISDK

class TP1ViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    var sparkMovementManager:SparkMovementManager? = nil
    
    var sequence = [BasicMove](){
        didSet{
            DispatchQueue.main.async {
                self.displaySequenceOnTextView()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func stopButtonClicked(_ sender: Any) {
        print("Stop")
        stop()
        sparkMovementManager?.redAlert()
    }
    
    @IBAction func startButtonClicked(_ sender: Any) {
        print("Start")
        sparkMovementManager?.playSequence()
    }
    
    func stop() {
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            mySpark.mobileRemoteController?.leftStickVertical = 0.0
            mySpark.mobileRemoteController?.leftStickHorizontal = 0.0
            mySpark.mobileRemoteController?.rightStickHorizontal = 0.0
            mySpark.mobileRemoteController?.rightStickVertical = 0.0
        }
    }
    
    @IBAction func rotateLeft(_ sender: Any) {
        self.askForDurationAndSpeed { (speed, duration) in
            self.sequence.append(RotateLeft(duration: duration,speed: speed))
        }
    }
    
    @IBAction func frontButtonClicked(_ sender: Any) {
        self.askForDurationAndSpeed { (speed, duration) in
            self.sequence.append(Front(duration: duration,speed: speed))
        }
    }
    
    @IBAction func rotateRightButtonClicked(_ sender: Any) {
        self.askForDurationAndSpeed { (speed, duration) in
            self.sequence.append(RotateRight(duration: duration,speed: speed))
        }
    }
    
    @IBAction func clearSequence(_ sender: Any) {
        sequence = []
        textView.text = ""
        sparkMovementManager?.clearSequence()
    }
    
    @IBAction func displaySequence(_ sender: Any) {
        displaySequenceOnTextView()
    }
    
    func displaySequenceOnTextView() {
        sparkMovementManager = SparkMovementManager(sequence: sequence)
        if let desc = sparkMovementManager?.sequenceDescription() {
            textView.text = desc
        }
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
