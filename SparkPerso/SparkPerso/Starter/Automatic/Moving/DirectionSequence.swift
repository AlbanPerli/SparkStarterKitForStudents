//
//  Sequence.swift
//  SparkPerso
//
//  Created by AL on 10/01/2019.
//  Copyright © 2019 AlbanPerli. All rights reserved.
//

import Foundation

public class DirectionSequence {
    
    public static let instance = DirectionSequence()
    
    public enum ActionType:String {
        case TakeOff,Landing,MoveForward,Stop
    }
    
    public var content:[String] = [] {
        didSet{
            if let last = content.last {
                print(last)
            }
        }
    }
}
