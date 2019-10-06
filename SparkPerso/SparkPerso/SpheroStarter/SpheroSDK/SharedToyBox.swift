//
//  SharedToyBox.swift
//  SpheroManager
//
//  Created by AL on 01/09/2019.
//  Copyright © 2019 AL. All rights reserved.
//

import Foundation

class SharedToyBox {
    
    static let instance = SharedToyBox()
    
    private var searchCallBack:((Error?)->())?
    
    let box = ToyBox()
    var boltsNames = [String]()
    var bolts:[BoltToy] = []
    
    var bolt:BoltToy? {
        get {
            return bolts.first
        }
    }
    
    init() {
        box.addListener(self)
    }
    
    func searchForBoltsNamed(_ names:[String], doneCallBack:@escaping (Error?)->()) {
        searchCallBack = doneCallBack
        boltsNames = names
        box.start()
    }
    
    func stopScan() {
        box.stopScan()
    }
    
}

extension SharedToyBox:ToyBoxListener{
    func toyBoxReady(_ toyBox: ToyBox) {
        box.startScan()
    }
    
    func toyBox(_ toyBox: ToyBox, discovered descriptor: ToyDescriptor) {
        print("discovered \(descriptor.name)")
        
        if bolts.count >= boltsNames.count {
            box.stopScan()
        }else{
            if boltsNames.contains(descriptor.name ?? "") {
                let bolt = BoltToy(peripheral: descriptor.peripheral, owner: toyBox)
                bolts.append(bolt)
                toyBox.connect(toy: bolt)
            }
        }
        
    }
    
    func toyBox(_ toyBox: ToyBox, readied toy: Toy) {
        print("readied")
        if let b = toy as? BoltToy {
            print(b.peripheral?.name ?? "")
            if let i = self.bolts.firstIndex(where: { (item) -> Bool in
                item.identifier == b.identifier
            }){
                self.bolts[i] = b
            }
            
            if bolts.count >= boltsNames.count {
                DispatchQueue.main.async {
                    self.searchCallBack?(nil)
                }
            }
            //b.setMainLed(color: .clear)
            //b.setBackLed(color: .clear)
            //b.setFrontLed(color: .clear)
            /*
            b.setCollisionDetection(configuration: CollisionConfiguration.enabled)
            b.onCollisionDetected = { collisionData in
                print(collisionData)
            }
            b.setStabilization(state: .on)
             */
            /*
             b.drawMatrix(fillFrom: Pixel(x: 0, y: 0), to: Pixel(x: 59, y: 59), color: .green)
             
             b.drawMatrix(pixel: Pixel(x: 1, y: 0), color: .red)
             b.drawMatrix(pixel: Pixel(x: 2, y: 0), color: .red)
             */
            
            //b.drawMatrix(pixel: Pixel(x: 30, y: 24), color: .red)
            //b.drawMatrix(pixel: Pixel(x: 30, y: 25), color: .red)
            //b.drawMatrix(pixel: Pixel(x: 30, y: 26), color: .red)
            
            /*
             b.sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .accelerometer,.gyro,.orientation,.locator))
             b.sensorControl.onDataReady = { data in
             if let acceleroDatas = data.accelerometer?.filteredAcceleration {
             print("Acceleration : x:\(acceleroDatas.x!), y:\(acceleroDatas.y!), z:\(acceleroDatas.z!)")
             }
             if let gyroDatas = data.gyro?.rotationRate {
             print("Gyro : x:\(gyroDatas.x!), y:\(gyroDatas.y!), z:\(gyroDatas.z!)")
             }
             if let orientation = data.orientation {
             print("Orientation : Roll:\(orientation.roll!), pitch:\(orientation.pitch!), yaw:\(orientation.yaw!)")
             }
             if let locator = data.locator {
             print("Locator : x:\(locator.position?.x!), y:\(locator.position?.y!), velocityX:\(locator.velocity?.x!), velocityY:\(locator.velocity?.y!)")
             }
             }
             */
        }
    }
    
    func toyBox(_ toyBox: ToyBox, putAway toy: Toy) {
        print("put away")
    }
    
    
}

