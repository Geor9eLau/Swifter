//
//  Player.swift
//  Swifter
//
//  Created by George on 2017/6/15.
//  Copyright © 2017年 George. All rights reserved.
//

import Foundation


struct Player {
    var name: String
    var currentPosition: UInt
    
    func description() -> String {
        return "\(name),\(currentPosition)"
    }
}
