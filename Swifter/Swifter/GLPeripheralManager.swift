//
//  GLPeripheralManager.swift
//  Swifter
//
//  Created by George on 2017/6/15.
//  Copyright © 2017年 George. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

//protocol GLPeripheralManagerDelegate: class {
//    func peripheralManager(_ manager: GLPeripheralManager, update playerData: Data)
//    func peripheralManager(_ manager: GLPeripheralManager, didFail error: GLError)
//    func peripheralManager(_ manager: GLPeripheralManager, didGetNewSubscriber subscriberCount: Int)
//}

class GLPeripheralManager: NSObject, CBPeripheralManagerDelegate {
    static let `default`: GLPeripheralManager = {
       return GLPeripheralManager()
    }()
    
    typealias StartGameHandler = (_ isSucceed: Bool) -> ()
    fileprivate var startHandler: StartGameHandler?
    fileprivate let queue = DispatchQueue(label: "PeripheralQueue")
    fileprivate var manager: CBPeripheralManager!
    fileprivate var subscribedCenteral: [CBCentral] = []
//    fileprivate var gameSwitchCharacteristic: CBMutableCharacteristic?
    fileprivate var playerDataCharacteristic: CBMutableCharacteristic?
    var peripheralPlayer = GLPlayer(name: UIDevice.current.name, currentFinishRate: 0, isRoomCreater: true, isReady: false)
    fileprivate var playerData: [GLPlayer] = []
    private override init() {
        super.init()
        manager = CBPeripheralManager(delegate: self, queue: queue)
        playerData.append(peripheralPlayer)
        setupService()
    }
}


// MARK: - Private
extension GLPeripheralManager {
    fileprivate func setupService(){
        playerDataCharacteristic = CBMutableCharacteristic(type: CBUUID(string: PlayerDataCharacteristicUUIDString), properties: [.notify , .read] , value: nil, permissions: [.writeable, .readable])
//        gameSwitchCharacteristic = CBMutableCharacteristic(type: CBUUID(string: GameSwitchCharacteristicUUIDString), properties: [.notify , .read] , value: nil, permissions: [.writeable, .readable])
        let playerDataService = CBMutableService(type: CBUUID(string: PlayerDataCharacteristicUUIDString), primary: true)
        playerDataService.characteristics = [playerDataCharacteristic!]
        
//        let gameSwitchService = CBMutableService(type: CBUUID(string: GameSwitchCharacteristicUUIDString), primary: true)
//        gameSwitchService.characteristics = [gameSwitchCharacteristic!]
        manager.add(playerDataService)
//        manager.add(gameSwitchService)
    }
}


// MARK: - Public
extension GLPeripheralManager {
    func startAdvertising() {
        if manager.state == .poweredOn{
            manager.startAdvertising([CBAdvertisementDataLocalNameKey: UIDevice.current.name, CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: PlayerDataServiceUUIDString)]])
        }
    }
    
    func stopAdvertising() {
        if manager.isAdvertising {
            manager.stopAdvertising()
        }
    }
    
    func updateFinishRate(_ rate: Float) {
        peripheralPlayer.currentFinishRate = rate
        updatePeripheralPlayerData()
        
    }
    
    func startGame(_ handler: @escaping StartGameHandler) {
        startHandler = handler
        guard playerData.filter({$0.isReady == false}).count == 1 else {
            print("Some player is not ready to go")
            return
        }
        peripheralPlayer.isReady = true
        updatePeripheralPlayerData()
    }
    
}


// MARK: - Private
extension GLPeripheralManager {
    fileprivate func updatePeripheralPlayerData() {
        if let characteristic = playerDataCharacteristic {
            playerData = playerData.flatMap({ (player) -> GLPlayer in
                if player == peripheralPlayer{
                    return peripheralPlayer
                }else{
                    return player
                }
            })
            if let data = playerData.transformPlayerDataToData(){
                manager.updateValue(data, for: characteristic, onSubscribedCentrals: subscribedCenteral)
            }
        }
        
    }
}


// MARK: - CBPeripheralManagerDelegate
extension GLPeripheralManager {
    internal func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn{
            print("Peripheral is powered on!")
        }else{
            switch peripheral.state {
            case .poweredOff:
                NotificationCenter.default.post(name: NotificationPeripheralDeviceChangedToUnavailable, object: nil, userInfo: ["reason": GLError.poweredOff])
            case .unauthorized:
                NotificationCenter.default.post(name: NotificationPeripheralDeviceChangedToUnavailable, object: nil, userInfo: ["reason": GLError.unauthorized])
            case .unsupported:
                NotificationCenter.default.post(name: NotificationPeripheralDeviceChangedToUnavailable, object: nil, userInfo: ["reason": GLError.unsupported])
            case .resetting:
                NotificationCenter.default.post(name: NotificationPeripheralDeviceChangedToUnavailable, object: nil, userInfo: ["reason": GLError.resetting])
            default:
                NotificationCenter.default.post(name: NotificationPeripheralDeviceChangedToUnavailable, object: nil, userInfo: ["reason": GLError.unknown])
            }

        }
    }
    
    
    internal func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {

    }
    
    internal func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        if subscribedCenteral.contains(central) {
            subscribedCenteral.remove(at: subscribedCenteral.index(of: central)!)
            NotificationCenter.default.post(name: NotificationPeripheralUpdateSubscriber, object: nil, userInfo: [NotificationUpdatedSubscriberUUIDStringKey: central.identifier.uuidString])
        }
    }
    
    
    internal func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        if let characteristic = requests.first,
            let data = characteristic.value{
            playerData = data.transformDataToPlayerData()
            NotificationCenter.default.post(name: NotificationPlayerDataUpdate, object: nil, userInfo: [NotificationPlayerDataUpdateKey: playerData])
            
        }
    }
    
    internal func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if error != nil {
            print(error!)
        }
    }
}
