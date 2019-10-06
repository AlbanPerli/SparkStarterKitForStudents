//
//  MovingManager.swift
//  SparkPerso
//
//  Created by AL on 11/01/2019.
//  Copyright © 2019 AlbanPerli. All rights reserved.
//

import UIKit

// Un manageur de Mouvement/Déplacement
// Qui liste les mouvements et permet de les afficher dans la console
class MovingManager {
    
    static let instance = MovingManager()
    var mouvements = [Movement]()
    var isTesting:Bool = false
    
    func restart() {
        DirectionSequence.instance.content.removeAll()
        mouvements = []
    }
    
    func appendMouvement(mouvement:Movement) {
        DirectionSequence.instance.content.append(mouvement.description())
        mouvements.append(mouvement)
    }
    
    func play() {
        
        print("*** Playing sequence ***")
        executeMove()
        
    }
    
    func executeMove() {
        if let move = mouvements.first {
            
            // Ici Envoyer la direction au drone == Remplir les sticks
            if isTesting {
                print(move.description())
            }else{
                Spark.instance.move(movement: move)
            }
            
            Timer.scheduledTimer(withTimeInterval: TimeInterval(move.duration), repeats: false) { (t) in
                // Code exécuté après move.duration seconds
                self.mouvements.remove(at: 0)
                self.executeMove()
            }
            
        }else{
            // Envoyer stop au drone == Remplir les sticks avec des 0
            print("SEND STOP!!!!!")
            Spark.instance.stop()
        }
    }
    
}
