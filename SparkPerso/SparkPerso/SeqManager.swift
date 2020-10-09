//
//  SeqManager.swift
//  SparkPerso
//
//  Created by Alban on 25/09/2020.
//  Copyright © 2020 AlbanPerli. All rights reserved.
//

import Foundation


class SeqManager {
    struct Move {
        var duration:Double
        var speed:Float
    }
    static let instance = SeqManager()
    
    var moves = [Move]()
    
    func clear() {
        moves.removeAll()
    }
    
    func move(moves:[Move]) {
        
        var localMoves = moves
        print(localMoves)
        print(localMoves.first?.duration)
        if moves.count > 0 {
            if let currentMove = localMoves.first{
                print("Mouvement \(currentMove.duration)")
                DispatchQueue.main.asyncAfter(deadline: .now() + currentMove.duration) {
                    print("Stop")
                    localMoves.remove(at: 0)
                    self.move(moves: localMoves)
                }
            }
        }else{
            print("Finito")
        }
        
        
    }
    
}
