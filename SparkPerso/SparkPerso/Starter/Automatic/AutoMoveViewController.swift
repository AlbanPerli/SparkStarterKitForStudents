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
        
        MovingManager.instance.restart()
        MovingManager.instance.appendMouvement(mouvement: Mouvement(direction: .top, duration: 3.0))
        MovingManager.instance.appendMouvement(mouvement: Mouvement(direction: .back, duration: 3.1))
        MovingManager.instance.appendMouvement(mouvement: Mouvement(direction: .topRight, duration: 5.2))
        MovingManager.instance.appendMouvement(mouvement: Mouvement(direction: .left, duration: 2.8))
        
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
