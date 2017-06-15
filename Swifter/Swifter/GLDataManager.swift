//
//  GLDataManager.swift
//  Swifter
//
//  Created by George on 2017/6/15.
//  Copyright © 2017年 George. All rights reserved.
//

import Foundation


class GLDataManager: NSObject {
    static let `default`: GLDataManager = {
       return GLDataManager()
    }()
    
    override private init() {
        super.init()
    }
}

extension GLDataManager {
    
    func transformDataToPlayerData(_ data: Data) -> [Player] {
        if let tmpDataStr = String(data: data, encoding: .utf8){
            let tmpPlayerDataStrArr = tmpDataStr.components(separatedBy: ";")
            var tmpPlayerData: [Player] = []
            for playerDataStr in tmpPlayerDataStrArr {
                let playerPropertyDataArr = playerDataStr.components(separatedBy: ",")
                guard playerPropertyDataArr.count == 2 else {return []}
                let name = playerPropertyDataArr[0]
                let currentPosition = playerPropertyDataArr[1]
                let player = Player(name: name, currentPosition: UInt(currentPosition)!)
                tmpPlayerData.append(player)
            }
            return tmpPlayerData
        }
        return []
    }
    
    
    /// Generate the transport data
    ///
    /// - Parameters:
    ///   - player: self
    ///   - otherPlayers: other
    /// - Returns: transport data
    func generateData(with player:Player, and otherPlayers: [Player]) -> Data {
        var tmpPlayerDataStrArr: [String] = []
        var tmpPlayerArr = Array(otherPlayers)
        tmpPlayerArr.append(player)
        for player in tmpPlayerArr{
            tmpPlayerDataStrArr.append(player.description())
        }
        let tmpDataStr = tmpPlayerDataStrArr.joined(separator: ";")
        return tmpDataStr.data(using: .utf8)!
    }
}
