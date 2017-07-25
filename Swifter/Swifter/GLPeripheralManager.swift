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
    fileprivate var playerDataService: CBMutableService!
    fileprivate var subscribedCenteral: [CBCentral] = []
    fileprivate var gameCreaterCharacteristic: CBMutableCharacteristic?
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
        playerDataCharacteristic = CBMutableCharacteristic(type: CBUUID(string: PlayerDataCharacteristicUUIDString), properties: [.notify ,.write, .read], value: nil, permissions: .writeable)
//        gameCreaterCharacteristic = CBMutableCharacteristic(type: CBUUID(string: GameCreaterCharacteristicUUIDString), properties: .read, value: [peripheralPlayer].transformPlayerDataToData() , permissions: .readable)
        playerDataService = CBMutableService(type: CBUUID(string: PlayerDataServiceUUIDString), primary: true)
        playerDataService.characteristics = [playerDataCharacteristic!]
    }
}


// MARK: - Public
extension GLPeripheralManager {
    func startAdvertising() {
        if manager.state == .poweredOn{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { 
                self.manager.startAdvertising([CBAdvertisementDataLocalNameKey: UIDevice.current.name, CBAdvertisementDataServiceUUIDsKey: [self.playerDataService.uuid]])
            })
            
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
            startAdvertising()
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
        
       
        if let request = requests.first,
            let data = request.value{
             peripheral.respond(to: request, withResult: .success)
            playerData = data.transformDataToPlayerData()
            if playerData.count == 1 {
                playerData.append(peripheralPlayer)
            self.manager.updateValue(self.playerData.transformPlayerDataToData()!, for: self.playerDataCharacteristic!, onSubscribedCentrals: self.subscribedCenteral)
            }
            NotificationCenter.default.post(name: NotificationPlayerDataUpdate, object: nil, userInfo: [NotificationPlayerDataUpdateKey: playerData])
        }
        
    }
    
    internal func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if error != nil {
            print(error!)
        }
        manager.add(playerDataService)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if error != nil {
            print(error!)
        }
    }
}
