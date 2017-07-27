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
    
    fileprivate let queue = DispatchQueue(label: "PeripheralQueue")
    fileprivate var manager: CBPeripheralManager!
    fileprivate var playerDataService: CBMutableService!
    fileprivate var subscribedCenteral: [CBCentral] = []
    fileprivate var playerFinishRateCharacteristic: CBMutableCharacteristic!
    fileprivate var playerReadyStateCharacteristic: CBMutableCharacteristic!
    fileprivate var playerNameCharacteristic: CBMutableCharacteristic!
    var peripheralPlayer = GLPlayer(name: UIDevice.current.name, currentFinishRate: 0, isRoomCreater: true, isReady: false)
    var playerData: [GLPlayer] = []
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
        playerNameCharacteristic = CBMutableCharacteristic(type: CBUUID(string: PlayerNameCharacteristicUUIDString), properties: [.indicate, .read, .write], value:nil, permissions: [.readable ,.writeable])
        playerReadyStateCharacteristic = CBMutableCharacteristic(type: CBUUID(string: PlayerReadyStateCharacteristicUUIDString), properties: [.indicate, .write, .read] , value: nil, permissions: [.readable, .writeable])
        playerFinishRateCharacteristic = CBMutableCharacteristic(type: CBUUID(string: PlayerFinishRateCharacteristicUUIDString), properties: [.indicate, .write, .read], value: nil, permissions: [.readable, .writeable])
        
        playerDataService = CBMutableService(type: CBUUID(string: PlayerDataServiceUUIDString), primary: true)
        playerDataService.characteristics = [playerFinishRateCharacteristic, playerNameCharacteristic, playerReadyStateCharacteristic]
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
    
    func startGame() {
        peripheralPlayer.isReady = true
        
        if let data = "1".data(using: .utf8){
            manager.updateValue(data, for: playerReadyStateCharacteristic, onSubscribedCentrals: nil)
        }
    }
    
}


// MARK: - Private
extension GLPeripheralManager {
    fileprivate func updatePeripheralPlayerData() {
        if let data = "\(peripheralPlayer.currentFinishRate)".data(using: .utf8){
            manager.updateValue(data, for: playerFinishRateCharacteristic, onSubscribedCentrals: nil)
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
        
        for request in requests {
            if let data = request.value,
                let dataStr = String(data: data, encoding: .utf8){
                peripheral.respond(to: request, withResult: .success)
                
                switch request.characteristic.uuid.uuidString {
                case PlayerNameCharacteristicUUIDString:
                    NotificationCenter.default.post(name: NotificationDidReceiveOtherPlayerName, object: nil, userInfo:[NotificationOtherPlayerNameKey: dataStr])
                    peripheral.updateValue(peripheralPlayer.name.data(using: .utf8)!, for: playerNameCharacteristic, onSubscribedCentrals: subscribedCenteral)
                case PlayerFinishRateCharacteristicUUIDString:
                    NotificationCenter.default.post(name: NotificationOtherPlayerFinishRateDidChange, object: nil, userInfo:[NotificationOtherPlayerFinishRateKey: Float(dataStr) as Any])
                case PlayerReadyStateCharacteristicUUIDString:
                    NotificationCenter.default.post(name: NotificationOtherPlayerReadyStateDidChange, object: nil, userInfo: [NotificationOtherPlayerReadyStateKey: dataStr as Any])
                default:
                    return
                }
                
            }
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
