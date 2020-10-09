//
//  SocketExampleManager.swift
//  SparkPerso
//
//  Created by Alban on 08/10/2020.
//  Copyright © 2020 AlbanPerli. All rights reserved.
//

import Foundation
import SocketIO


class SocketExampleManager {
    
    static let instance = SocketExampleManager()
    
    struct Ctx {
        var ip:String
        var port:String
        var isHttps:Bool
        
        func fullIp() -> String {
            if isHttps {
                return "https://"+ip+":"+port
            }else{
                return "http://"+ip+":"+port
            }
            
        }
        
        static func defaultCtx() -> Ctx {
            return Ctx(ip: "127.0.0.1", port: "8080", isHttps: false)
        }
        
        static func prodCtx() -> Ctx {
            return Ctx(ip: "127.0.0.1", port: "8080", isHttps: true)
        }

        
    }
    
    
    func connect(context:Ctx) {
        
        
        
    }
    
    func disconnect() {
        
    }
    
    
    
}
