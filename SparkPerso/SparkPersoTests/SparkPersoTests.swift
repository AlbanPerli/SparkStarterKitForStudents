//
//  SparkPersoTests.swift
//  SparkPersoTests
//
//  Created by AL on 11/01/2019.
//  Copyright © 2019 AlbanPerli. All rights reserved.
//

import XCTest

class SparkPersoTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMovingManager() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        MovingManager.instance.restart()
        MovingManager.instance.appendMouvement(mouvement: Mouvement(direction: .top, duration: 1.0))
        MovingManager.instance.appendMouvement(mouvement: Mouvement(direction: .back, duration: 1.1))
        MovingManager.instance.appendMouvement(mouvement: Mouvement(direction: .topRight, duration: 0.2))
        MovingManager.instance.appendMouvement(mouvement: Mouvement(direction: .left, duration: 0.8))
        
        MovingManager.instance.play()

    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
