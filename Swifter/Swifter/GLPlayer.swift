//
//  GLPlayer.swift
//  Swifter
//
//  Created by George on 2017/6/29.
//  Copyright © 2017年 George. All rights reserved.
//

import Foundation
import HandyJSON

struct GLPlayer: HandyJSON, Equatable {
//    var uuid: String!
    var name: String = ""
    var currentFinishRate: Float = 0
    var isRoomCreater: Bool = false
    var isReady: Bool = false
    
    public static func ==(lhs: GLPlayer, rhs: GLPlayer) -> Bool{
        return lhs.name == rhs.name
    }
}
