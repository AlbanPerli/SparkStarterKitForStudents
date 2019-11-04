//
//  SpheroTP1ViewController.swift
//  SparkPerso
//
//  Created by AL on 18/10/2019.
//  Copyright © 2019 AlbanPerli. All rights reserved.
//

import UIKit

class SpheroTP1ViewController: UIViewController {

     @IBOutlet weak var textView: UITextView!
     var spheroMovementManager:SpheroMovementManager? = nil
     
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
        
        SocketIOManager.instance.setup()
        SocketIOManager.instance.connect {
            print("Connection!")
            SocketIOManager.instance.writeValue("Toto", toChannel: "test") {
                
            }
            SocketIOManager.instance.listenToChannel(channel: "sphero-move") { receivedStr in
                if let str = receivedStr {
                    self.manageCommand(str: str)
                }else{
                    print("...Received wrong type...")
                }
            }
        }
    }
    
    func manageCommand(str:String) {
        switch str {
        case let t where t.contains("FRONT"):
            var components = t.split(separator: ":")
            var parameters = Array(components.dropFirst())
            if let h = Double(parameters[0]),
                let d = Float(parameters[1]),
                let s = Float(parameters[2]) {
                self.sequence.append(SpheroMove(heading: h, duration: d, speed: s))
            }
            
        case "LEFT":
        self.sequence.append(SpheroMove(heading: 90.0, duration: 0.0, speed: 0.0))
        case "RIGHT":
        self.sequence.append(SpheroMove(heading: 270.0, duration: 0.0, speed: 0.0))
        case "STOP": spheroMovementManager?.redAlert()
        default: break
        }
    }
     
     
     @IBAction func stopButtonClicked(_ sender: Any) {
         print("Stop")
         stop()
         spheroMovementManager?.redAlert()
     }
     
     @IBAction func startButtonClicked(_ sender: Any) {
         print("Start")
         spheroMovementManager?.playSequence()
     }
     
     func stop() {
        
     }
     
     @IBAction func rotateLeft(_ sender: Any) {
        self.sequence.append(SpheroMove(heading: 90.0, duration: 0.0, speed: 0.0))
     }
     
     @IBAction func frontButtonClicked(_ sender: Any) {
         self.askForDurationSpeedAndHeading { (speed, duration, heading) in
            self.sequence.append(SpheroMove(heading: Double(heading), duration: duration, speed: speed))
         }
     }
     
     @IBAction func rotateRightButtonClicked(_ sender: Any) {
        self.sequence.append(SpheroMove(heading: 270.0, duration: 0.0, speed: 0.0))
     }
     
     @IBAction func clearSequence(_ sender: Any) {
         sequence = []
         textView.text = ""
         spheroMovementManager?.clearSequence()
     }
     
     @IBAction func displaySequence(_ sender: Any) {
         displaySequenceOnTextView()
     }
     
     func displaySequenceOnTextView() {
         spheroMovementManager = SpheroMovementManager(sequence: sequence)
         if let desc = spheroMovementManager?.sequenceDescription() {
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
