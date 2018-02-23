//
//  MovementManager.swift
//  SparkPerso
//
//  Created by AL on 23/02/2018.
//  Copyright © 2018 AlbanPerli. All rights reserved.
//

import Foundation

public struct Movement {
  
    public struct Direction {
        var impulse:Float = 0.5
        
        enum MovementType {
            case forward,backward
        }
        
        enum Axes {
            case rightStickVertical,rightStickHorizontal,z
        }
        
        var axe:Axes
        var type:MovementType
    }
    
    
    var directions = [Direction](){
        didSet{
            
        }
    }
    // Physics
    var start:Any?
    var end:Any?
   
    
    var duration:Float
    
//    // SDK
//    var rightStickVertical:Float
//    var rightStickHorizontal:Float
    
}

public class MovementManager {
    
    // Singleton
    static let shared = MovementManager()
    var scenario = [Movement]()
    var isRunning = false {
        didSet {
            stateChanged?(isRunning)
        }
    }
    
    var stateChanged:((Bool)->())? = nil
    var emitMovement:((Movement)->())? = nil
    
    public func createSquareScenario() -> [Movement] {
        
        var scenario = [Movement]()
        
        let forward = Movement(directions: [self.makeForwardDirection()], start: nil, end: nil, duration: 0.5)
        let right = Movement(directions: [self.makeRightDirection()], start: nil, end: nil, duration: 0.5)
        let backward = Movement(directions: [self.makeBackwardDirection()], start: nil, end: nil, duration: 0.5)
        let left = Movement(directions: [self.makeLeftDirection()], start: nil, end: nil, duration: 0.5)
        
        // Square
        scenario.append(forward)
        scenario.append(right)
        scenario.append(backward)
        scenario.append(left)
        scenario.append(forward)
        
        
        return scenario
        
    }
    
    
    public func launchProcess() {
        self.scenario = createSquareScenario()
        isRunning = true
        loop()
    }
    
    // Recursive loop
    public func loop() {
        
        if let move = scenario.first {
            self.scenario = Array(scenario.dropFirst())
            
            self.emitMovement?(move)
            
            let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(move.duration), repeats: false) { (timerDansLeCallBack) in
                
                if self.scenario.count != 0 {
                    self.loop()
                }else{
                    self.emitMovement?(self.makeStopMovement())
                    self.isRunning = false
                }
                
            }
            
        }else{
            isRunning = false
        }
    }
    
    public func makeStopMovement() -> Movement {
        let direction1 = Movement.Direction(impulse: 0.0, axe: Movement.Direction.Axes.rightStickVertical, type: Movement.Direction.MovementType.forward)
        let direction2 = Movement.Direction(impulse: 0.0, axe: Movement.Direction.Axes.rightStickHorizontal, type: Movement.Direction.MovementType.forward)
        
        let mov = Movement(directions: [direction1,direction2], start: nil, end: nil, duration: 0.0001)
        
        return mov
    }
    
    
}

extension MovementManager {
    func makeForwardDirection(_ impulse:Float = 0.1) -> Movement.Direction {
        return Movement.Direction(impulse: impulse, axe: Movement.Direction.Axes.rightStickVertical, type: Movement.Direction.MovementType.forward)
    }
    
    func makeBackwardDirection(_ impulse:Float = 0.1) -> Movement.Direction {
        return Movement.Direction(impulse: impulse, axe: Movement.Direction.Axes.rightStickVertical, type: Movement.Direction.MovementType.backward)
    }
    
    func makeLeftDirection(_ impulse:Float = 0.1) -> Movement.Direction {
        return Movement.Direction(impulse: impulse, axe: Movement.Direction.Axes.rightStickHorizontal, type: Movement.Direction.MovementType.forward)
    }
    
    func makeRightDirection(_ impulse:Float = 0.1) -> Movement.Direction {
        return Movement.Direction(impulse: impulse, axe: Movement.Direction.Axes.rightStickHorizontal, type: Movement.Direction.MovementType.backward)
    }
}
