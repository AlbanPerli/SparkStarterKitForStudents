//: [Previous](@previous)

import UIKit

let a = CGPoint(x: 0, y: 0)
let b = CGPoint(x: 0.0, y: 1.0)

// Outils de conversion
radiansToDegress(radians:a.angleToPoint(pointOnCircle: b))

CGPoint.pointOnCircle(center: a, radius: 1.0, angle: degreesToRadians(degrees: 90))

// Monde
// o -> drone
// x -> chemin à parcourir
// Revenir au point de départ
// Référentiel x = 0, y = 0 en bas à gauche
//   _ _ _ _ _ _ _ _
//  |x|x|_|_|_|_|_|_|
//  |_|_|x|_|_|_|_|_|
//  |_|_|_|x|x|_|_|_|
//  |_|_|_|_|_|x|_|_|
//  |_|_|x|x|x|_|_|_|
//  |_|x|_|_|_|_|_|_|
//  |x|_|_|_|_|_|_|_|
//  |o|_|_|_|_|_|_|_|

// En translation == sans rotation
var droneStartPos = CGPoint(x: 0, y: 0)
// Monte d'une case
droneStartPos.offset(dx: 0, dy: 1)
// Monte d'une case et se déplace d'une case à droite
droneStartPos.offset(dx: 1, dy: 1)
droneStartPos.offset(dx: 1, dy: 1)
droneStartPos.offset(dx: 1, dy: 0)
droneStartPos.offset(dx: 1, dy: 0)
droneStartPos.offset(dx: 1, dy: 0)
droneStartPos.offset(dx: 1, dy: 1)
droneStartPos.offset(dx: -1, dy: 1)
droneStartPos.offset(dx: -1, dy: 0)
droneStartPos.offset(dx: -1, dy: 0)
droneStartPos.offset(dx: -1, dy: 1)
droneStartPos.offset(dx: -1, dy: 1)
droneStartPos.offset(dx: -1, dy: 0)
droneStartPos.offset(dx: 0, dy: -1)
droneStartPos.offset(dx: 0, dy: -1)
droneStartPos.offset(dx: 0, dy: -1)
droneStartPos.offset(dx: 0, dy: -1)
droneStartPos.offset(dx: 0, dy: -1)
droneStartPos.offset(dx: 0, dy: -1)
droneStartPos.offset(dx: 0, dy: -1)

// En regardant toujours en direction du chemin
// https://www.geogebra.org/m/dQDZ7GGq
var droneStartPosHeading = CGPoint(x: 0, y: 0)
droneStartPosHeading =
    CGPoint.pointOnCircle(center: droneStartPosHeading, radius: 1.0, angle: degreesToRadians(degrees: 90))

droneStartPosHeading = CGPoint.CGPointRound(
    CGPoint.pointOnCircle(center: droneStartPosHeading, radius: 1.0, angle: degreesToRadians(degrees: 45)))

droneStartPosHeading = CGPoint.CGPointRound(
    CGPoint.pointOnCircle(center: droneStartPosHeading, radius: 1.0, angle: degreesToRadians(degrees: 45)))

droneStartPosHeading = CGPoint.CGPointRound(
    CGPoint.pointOnCircle(center: droneStartPosHeading, radius: 1.0, angle: degreesToRadians(degrees: 0)))

droneStartPosHeading = CGPoint.CGPointRound(
    CGPoint.pointOnCircle(center: droneStartPosHeading, radius: 1.0, angle: degreesToRadians(degrees: 0)))

droneStartPosHeading = CGPoint.CGPointRound(
    CGPoint.pointOnCircle(center: droneStartPosHeading, radius: 1.0, angle: degreesToRadians(degrees: 0)))

droneStartPosHeading = CGPoint.CGPointRound(
    CGPoint.pointOnCircle(center: droneStartPosHeading, radius: 1.0, angle: degreesToRadians(degrees: 45)))
droneStartPosHeading = CGPoint.CGPointRound(
    CGPoint.pointOnCircle(center: droneStartPosHeading, radius: 1.0, angle: degreesToRadians(degrees: 135)))
// etc...

// Mix des approches
droneStartPos = CGPoint(x: 0, y: 0)

var futurePos = droneStartPos.createWithOffset(dx: 0, dy: 1)

radiansToDegress(radians: droneStartPos.angleToPoint(pointOnCircle: futurePos)
)

droneStartPos = futurePos
futurePos = droneStartPos.createWithOffset(dx: 1, dy: 1)
radiansToDegress(radians: droneStartPos.angleToPoint(pointOnCircle: futurePos)
)
droneStartPos = futurePos

droneStartPos.offset(dx: 1, dy: 1)
droneStartPos.offset(dx: 1, dy: 0)
droneStartPos.offset(dx: 1, dy: 0)
droneStartPos.offset(dx: 1, dy: 0)
droneStartPos.offset(dx: 1, dy: 1)
droneStartPos.offset(dx: -1, dy: 1)
droneStartPos.offset(dx: -1, dy: 0)
droneStartPos.offset(dx: -1, dy: 0)
droneStartPos.offset(dx: -1, dy: 1)
droneStartPos.offset(dx: -1, dy: 1)
droneStartPos.offset(dx: -1, dy: 0)
droneStartPos.offset(dx: 0, dy: -1)
droneStartPos.offset(dx: 0, dy: -1)
droneStartPos.offset(dx: 0, dy: -1)
droneStartPos.offset(dx: 0, dy: -1)
droneStartPos.offset(dx: 0, dy: -1)
droneStartPos.offset(dx: 0, dy: -1)
droneStartPos.offset(dx: 0, dy: -1)

//: [Next](@next)
