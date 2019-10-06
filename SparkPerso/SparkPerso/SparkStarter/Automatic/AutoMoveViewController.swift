//
//  AutoMoveViewController.swift
//  SparkPerso
//
//  Created by AL on 11/01/2019.
//  Copyright © 2019 AlbanPerli. All rights reserved.
//

import UIKit

// Créé une suite de mouvement (séquence)
// Puis "joue" cette séquence
// La durée est respectée lors de l'affichage dans la console

class AutoMoveViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
      
        
        //
        //   |     Screenshot    Camera DOWN     Action/Decision f(context) -> Image de chat? atterissage sinon retour au point 0.
        //     |   Screenshot    Camera FRONT
        //     |
        //   |
    }
    
    @IBAction func takeOff(_ sender: Any) {
        
        Spark.instance.airCraft?.flightController?.startTakeoff(completion: { (err) in
            print(err)
        })
        
    }
    
    @IBAction func landing(_ sender: Any) {
        Spark.instance.airCraft?.flightController?.startLanding(completion: { (err) in
            
        })
    }
    
    
    @IBAction func stop(_ sender: Any) {
        Spark.instance.stop()
    }
    
    
    @IBAction func start(_ sender: Any) {
        MovingManager.instance.isTesting = false
        MovingManager.instance.restart()
        let speed:CGFloat = 0.5
        MovingManager.instance.appendMouvement(mouvement: Movement(direction: .top, duration: 2.0, speed: speed))
        MovingManager.instance.appendMouvement(mouvement: Movement(direction: .right, duration: 2.0, speed: speed))
        MovingManager.instance.appendMouvement(mouvement: Movement(direction: .top, duration: 2.0, speed: speed))
        MovingManager.instance.appendMouvement(mouvement: Movement(direction: .left, duration: 2.0, speed: speed))
        
        MovingManager.instance.play()
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
