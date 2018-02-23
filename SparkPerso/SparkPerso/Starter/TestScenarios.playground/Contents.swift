//: Playground - noun: a place where people can play
import PlaygroundSupport
import UIKit

PlaygroundPage.current.needsIndefiniteExecution = true

public struct Movement {
    
    public struct Direction {
        var impulse:Float = 0.5
        
        enum MovementType {
            case forward,backward
        }
        
        enum Axes {
            case x,y,z
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
    
    var emitMovement:((Movement)->())? = nil
    
    public func createScenario() -> [Movement] {
        
        var scenario = [Movement]()
        
        for i in 0...5 {
            
            let direction1 = Movement.Direction(impulse: 0.3, axe: Movement.Direction.Axes.x, type: Movement.Direction.MovementType.forward)
            let direction2 = Movement.Direction(impulse: 0.3, axe: Movement.Direction.Axes.y, type: Movement.Direction.MovementType.forward)
            
            let mov = Movement(directions: [direction1,direction2], start: nil, end: nil, duration: 0.2)
            
            scenario.append(mov)
        }
        
        return scenario
        
    }
    
    
    public func launchProcess() {
        
        self.scenario = createScenario()
        
        loop()
        
    }
    
    // Recursive loop
    public func loop() {
        
        if let move = scenario.first {
            
            self.emitMovement?(move)
            
            let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(move.duration), repeats: false) { (timerDansLeCallBack) in
                
                if self.scenario.count != 0 {
                    self.loop()
                    self.scenario = Array(self.scenario.dropFirst())
                }
                
            }
            
        }
        
    }
    
    public func makeStopMovement() -> Movement {
        let direction1 = Movement.Direction(impulse: 0.0, axe: Movement.Direction.Axes.x, type: Movement.Direction.MovementType.forward)
        let direction2 = Movement.Direction(impulse: 0.0, axe: Movement.Direction.Axes.y, type: Movement.Direction.MovementType.forward)
        
        let mov = Movement(directions: [direction1,direction2], start: nil, end: nil, duration: 0.0001)
        
        return mov
    }
    
    
}


let manager = MovementManager()
manager.emitMovement = { mov in
    
    print("Move on axe \(mov.directions[0].axe) \(mov.directions[0].type) \(mov.directions[0].impulse) and Move on axe \(mov.directions[1].axe) \(mov.directions[1].type) \(mov.directions[1].impulse) : in \(mov.duration)s")
    
}
manager.launchProcess()

