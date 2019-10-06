//
//  ShouldActionCompleteResponse.swift
//  PlaygroundContent
//
//  Created by Jeff Payan on 2017-08-09.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation

class ShouldActionCompleteResponse: CommandResponseV2 {
    public let actionId: StanceCommand.StanceId
    
    public init?(_ data: Data) {
        if let actionId = StanceCommand.StanceId(rawValue: data[0]) {
            self.actionId = actionId
        } else {
            return nil
        }
    }
}
