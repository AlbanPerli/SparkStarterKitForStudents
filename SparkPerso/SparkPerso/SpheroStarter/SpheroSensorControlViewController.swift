//
//  SensorControlViewController.swift
//  SparkPerso
//
//  Created by AL on 01/09/2019.
//  Copyright © 2019 AlbanPerli. All rights reserved.
//

import UIKit
import simd
import AVFoundation

class SpheroSensorControlViewController: UIViewController {

    enum Classes:Int {
        case Carre,Triangle,Rond
        
        func neuralNetResponse() -> [Double] {
            switch self {
            case .Carre: return [1.0,0.0,0.0]
            case .Triangle: return [0.0,1.0,0.0]
            case .Rond: return [0.0,0.0,1.0]
            }
        }
        
    }
    
    var neuralNet:FFNN? = nil
    
    @IBOutlet weak var gyroChart: GraphView!
    @IBOutlet weak var acceleroChart: GraphView!
    var movementData = [Classes:[[Double]]]()
    var selectedClass = Classes.Carre
    var isRecording = false
    var isPredicting = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Do any additional setup after loading the view.
        neuralNet = FFNN(inputs: 3600, hidden: 20, outputs: 3, learningRate: 0.3, momentum: 0.2, weights: nil, activationFunction: .Sigmoid, errorFunction: .default(average: true))
        
        
        movementData[.Carre] = []
        movementData[.Rond] = []
        movementData[.Triangle] = []
        
        var currentAccData = [Double]()
        var currentGyroData = [Double]()
        
        SharedToyBox.instance.bolt?.sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .accelerometer,.gyro))
        SharedToyBox.instance.bolt?.sensorControl.interval = 1
        SharedToyBox.instance.bolt?.setStabilization(state: SetStabilization.State.off)
        SharedToyBox.instance.bolt?.sensorControl.onDataReady = { data in
            DispatchQueue.main.async {
                
                if self.isRecording || self.isPredicting {
                    if let acceleration = data.accelerometer?.filteredAcceleration {
                        // PAS BIEN!!!
                        currentAccData.append(contentsOf: [acceleration.x!, acceleration.y!, acceleration.z!])
                        
                        let dataToDisplay: double3 = [acceleration.x!, acceleration.y!, acceleration.z!]
                        self.acceleroChart.add(dataToDisplay)
                    }
                    
                    if let gyro = data.gyro?.rotationRate {
                        // TOUJOURS PAS BIEN!!!
                        let rotationRate: double3 = [Double(gyro.x!)/2000.0, Double(gyro.y!)/2000.0, Double(gyro.z!)/2000.0]
                        currentGyroData.append(contentsOf: [Double(gyro.x!), Double(gyro.y!), Double(gyro.z!)])
                        self.gyroChart.add(rotationRate)
                    }
                    
                    if currentAccData.count+currentGyroData.count >= 3600 {
                        print("Data ready for network!")
                        if self.isRecording {
                            self.isRecording = false
                            
                            // Normalisation
                            let minAcc = currentAccData.min()!
                            let maxAcc = currentAccData.max()!
                            let normalizedAcc = currentAccData.map { ($0 - minAcc) / (maxAcc - minAcc) }
                            
                            let minGyr = currentGyroData.min()!
                            let maxGyr = currentGyroData.max()!
                            let normalizedGyr = currentGyroData.map { ($0 - minGyr) / (maxGyr - minGyr) }
                            
                            self.movementData[self.selectedClass]?.append(normalizedAcc+normalizedGyr)
                            currentAccData = []
                            currentGyroData = []
                        }
                        if self.isPredicting {
                            self.isPredicting = false
                            
                            // Normalisation
                            let minAcc = currentAccData.min()!
                            let maxAcc = currentAccData.max()!
                            let normalizedAcc = currentAccData.map { Float(($0 - minAcc) / (maxAcc - minAcc)) }
                            let minGyr = currentGyroData.min()!
                            let maxGyr = currentGyroData.max()!
                            let normalizedGyr = currentGyroData.map { Float(($0 - minGyr) / (maxGyr - minGyr)) }
                            
                            let prediction = try! self.neuralNet?.update(inputs: normalizedAcc+normalizedGyr)
                            
                            let index = prediction?.index(of: (prediction?.max()!)!)! // [0.89,0.03,0.14]
                            
                            
                            let recognizedClass = Classes(rawValue: index!)!
                            print(recognizedClass)
                            print(prediction!)
                            
                            var str = "Je pense que c'est un "
                            switch recognizedClass {
                            case .Carre: str = str+"carré!"
                            case .Rond: str = str+"rond!"
                            case .Triangle: str = str+"triangle!"
                            }
                            let utterance = AVSpeechUtterance(string: str)
                            utterance.voice = AVSpeechSynthesisVoice(language: "fr-Fr")
                            utterance.rate = 0.4
                            
                            let synthesizer = AVSpeechSynthesizer()
                            synthesizer.speak(utterance)
                            currentAccData = []
                            currentGyroData = []
                        }
                    }
                }
            }
        }
        
    }
    
    
    @IBAction func trainButtonClicked(_ sender: Any) {
        
        trainNetwork()
        
    }
    
    
    @IBAction func predictButtonClicked(_ sender: Any) {
        self.isPredicting = true
    }
    
    func trainNetwork() {
        
        // --------------------------------------
        // TRAINING
        // --------------------------------------
        for i in 0...20 {
            print(i)
            if let selectedClass = movementData.randomElement(),
                let input = selectedClass.value.randomElement(){
                let expectedResponse = selectedClass.key.neuralNetResponse()
                
                let floatInput = input.map{ Float($0) }
                let floatRes = expectedResponse.map{ Float($0) }
                
                try! neuralNet?.update(inputs: floatInput) // -> [0.23,0.67,0.99]
                try! neuralNet?.backpropagate(answer: floatRes)
                
            }
        }
        
        // --------------------------------------
        // VALIDATION
        // --------------------------------------
        for k in movementData.keys {
            print("Inference for \(k)")
            let values = movementData[k]!
            for v in values {
                let floatInput = v.map{ Float($0) }
                let prediction = try! neuralNet?.update(inputs:floatInput)
                print(prediction!)
            }
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        SharedToyBox.instance.bolt?.sensorControl.disable()
    }

    @IBAction func segementedControlChanged(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        if let s  = Classes(rawValue: index){
            selectedClass = s
        }
    }
    
    @IBAction func startButtonClicked(_ sender: Any) {
        isRecording = true
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
