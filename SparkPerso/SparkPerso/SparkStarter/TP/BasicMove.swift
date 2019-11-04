//
//  BasicMove.swift
//  SparkPerso
//
//  Created by AL on 18/10/2019.
//  Copyright © 2019 AlbanPerli. All rights reserved.
//

import Foundation

class BasicMove {
    var durationInSec:Float
    var speed:Float
    var heading:Double = 0.0
    
    enum Direction {
        case front,back,rotateLeft,rotateRight,up,down,translateLeft,translateRight,stop
    }
    var direction:Direction
    var description:String{
        get{
            return "Move \(direction) during \(durationInSec)s at speed \(speed)"
        }
    }
    
    init(direction:Direction,duration:Float, speed:Float) {
        self.direction = direction
        self.durationInSec = duration
        self.speed = speed
    }
}

class SpheroMove:BasicMove {
    init(heading:Double, duration: Float, speed: Float) {
        super.init(direction: .front, duration: duration, speed: speed)
        self.heading = heading
    }
}


class Rotate90Right:BasicMove {
    let duration:Float = 1.0
    init() {
        super.init(direction:.rotateRight , duration: duration, speed: 0.5)
    }
}

class Rotate90Left:BasicMove {
    let duration:Float = 1.0
    init() {
        super.init(direction:.rotateLeft , duration: duration, speed: 0.5)
    }
}


class RotateRight:BasicMove {
    init(duration:Float, speed:Float) {
        super.init(direction:.rotateRight , duration: duration, speed: speed)
    }
}

class RotateLeft:BasicMove {
    init(duration:Float, speed:Float) {
        super.init(direction:.rotateLeft , duration: duration, speed: speed)
    }
}


class Front:BasicMove {
    init(duration:Float, speed:Float) {
        super.init(direction:.front , duration: duration, speed: speed)
    }
}

class Stop:BasicMove {
    init() {
        super.init(direction:.stop , duration: 0.0, speed: 0.0)
    }
}
