//
//  SpheroHeadingViewController.swift
//  SparkPerso
//
//  Created by AL on 01/09/2019.
//  Copyright © 2019 AlbanPerli. All rights reserved.
//

import UIKit

class SpheroAimingViewController: UIViewController {

    @IBOutlet weak var aimingLabel: UILabel!
    @IBOutlet weak var statusTextField: UITextView!
    var timerRSSI:Timer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        displayCurrentStatus()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SharedToyBox.instance.bolts.map{ $0.startAiming() }
        //SharedToyBox.instance.bolt?.startAiming()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timerRSSI?.invalidate()
        timerRSSI = nil
        SharedToyBox.instance.bolts.map{ $0.stopAiming() }
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        aimingLabel.text = "Aiming: \(sender.value.rounded())"
        SharedToyBox.instance.bolts.map{ $0.rotateAim(Double(sender.value)) }
    }
    
    func displayCurrentStatus() {
        if let bolt = SharedToyBox.instance.bolt,
            let appVersion = bolt.appVersion {
            bolt.getPowerState()
            statusTextField.text = """
            AppVersion: \(appVersion)\n
            Battery Level: \(bolt.batteryLevel ?? -1.0)\n
            Peripheral Name: \(bolt.peripheral?.name ?? "")\n
            """
            
            timerRSSI = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (t) in
                bolt.core.peripheral.readRSSI()
            }
            timerRSSI?.fire()
            
            bolt.core.rssiListenerCallback = { rssiValue in
                self.statusTextField.text = """
                AppVersion: \(appVersion)\n
                Battery Level: \(bolt.batteryLevel ?? -1.0)\n
                Peripheral Name: \(bolt.peripheral?.name ?? "")\n
                RSSI:\(rssiValue)
                """
            }
            
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
