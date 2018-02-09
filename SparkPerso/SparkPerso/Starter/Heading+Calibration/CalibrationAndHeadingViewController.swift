//
//  CompassViewController.swift
//  SparkPerso
//
//  Created by AL on 14/01/2018.
//  Copyright © 2018 AlbanPerli. All rights reserved.
//

import UIKit
import DJISDK

class CalibrationAndHeadingViewController: UIViewController {

    var timer:Timer? = nil
    
    let locationDelegate = LocationDelegate()
    let locationManager: CLLocationManager = {
        $0.requestWhenInUseAuthorization()
        $0.desiredAccuracy = kCLLocationAccuracyBest
        $0.startUpdatingLocation()
        $0.startUpdatingHeading()
        return $0
    }(CLLocationManager())
    
    @IBOutlet weak var phoneHeadingImageView: UIImageView!
    
    @IBOutlet weak var sparkHeadingImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // ---------------------
        // Spark
        // ---------------------
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            if let flightController = mySpark.flightController {
                if let compass = flightController.compass {
                    print("Calibration state before start: \(compass.calibrationState.rawValue)")
                    compass.startCalibration(completion: { (err) in
                        print(err ?? "Calibration OK")
                        print("Updated calibration state: \(compass.calibrationState.rawValue)")
                        
                        self.timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true, block: { (t) in
                            self.readHeading()
                        })
                        
                    })
                }
            }
        }
        
        // ---------------------
        // iOS
        // ---------------------
        locationManager.delegate = locationDelegate
        
        locationDelegate.headingCallback = { heading in
            
            UIView.animate(withDuration: 0.5) {
                self.phoneHeadingImageView.transform = CGAffineTransform(rotationAngle: CGFloat(heading).degreesToRadians)
            }
            print("iOS \(CGFloat(heading).degreesToRadians)")
        }
    }
    
    func readHeading() {
        if let heading = (DJISDKManager.product() as? DJIAircraft)?.flightController?.compass?.heading {
            UIView.animate(withDuration: 0.5) {
                self.sparkHeadingImageView.transform = CGAffineTransform(rotationAngle: CGFloat(heading).degreesToRadians)
            }
            print("Spark: \(CGFloat(heading).degreesToRadians)")
            
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

// Useful tools... ;-)
extension CalibrationAndHeadingViewController {
    func orientationAdjustment() -> CGFloat {
        let isFaceDown: Bool = {
            switch UIDevice.current.orientation {
            case .faceDown: return true
            default: return false
            }
        }()
        
        let adjAngle: CGFloat = {
            switch UIApplication.shared.statusBarOrientation {
            case .landscapeLeft:  return 90
            case .landscapeRight: return -90
            case .portrait, .unknown: return 0
            case .portraitUpsideDown: return isFaceDown ? 180 : -180
            }
        }()
        return adjAngle
    }
}

extension Float {
    var degreesToRadians: Float { return self * .pi / 180 }
    var radiansToDegrees: Float { return self * 180 / .pi }
}

extension CGFloat {
    var degreesToRadians: CGFloat { return self * .pi / 180 }
    var radiansToDegrees: CGFloat { return self * 180 / .pi }
}
