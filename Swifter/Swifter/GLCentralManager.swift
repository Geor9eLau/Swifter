//
//  GLCentralManager.swift
//  Swifter
//
//  Created by George on 2017/6/14.
//  Copyright © 2017年 George. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

let GameConnectUUIDString = "8D50AD4E-E058-404C-8DD6-E116C8376D43"

let PlayerDataServiceUUIDString = "69C88932-A2FD-4FB0-B74E-917ADEFFAF04"
let PlayerDataCharacteristicUUIDString = "2B9437B4-D3DA-4ED2-9CD1-59AFD2BB593F"
let GameCreaterCharacteristicUUIDString = "A853EEBC-481C-43AA-8589-515B196E7EB6"

//protocol GLCentralManagerDelegate: class {
//    func centralManager(_ manager: GLCentralManager, update playerData: Data)
//    func centralManager(_ manager: GLCentralManager, didFail error: GLError)
//    func centralManager(_ manager: GLCentralManager, didDiscoverPeripheral peripheralNameInfo: [String])
//    func centralManagerDidConectedToTarget(_ manager: GLCentralManager)
//}

class GLCentralManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let `default`: GLCentralManager = {
        return GLCentralManager()
    }()
    
    typealias ConnectHandler = (Bool) -> ()
    
    fileprivate var connectHandler: ConnectHandler?
    fileprivate let queue = DispatchQueue(label: "CentralQueue")
    fileprivate var manager: CBCentralManager!
    fileprivate let playerDataServiceUUID = UUID(uuidString: PlayerDataServiceUUIDString)
    fileprivate var connectedPeripheral: CBPeripheral?
    fileprivate var playerDataCharacteristic: CBCharacteristic?
    fileprivate var discoveredPeripheralNameInfo: [String] = []
    var playerData: [GLPlayer] = []
    override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: queue)
        playerData = [centralPlayer]
    }
    
    
    var centralPlayer = GLPlayer(name: UIDevice.current.name, currentFinishRate: 0, isRoomCreater: false, isReady: false)
    
    
    var discoveredPeripherals: [CBPeripheral]  = []
    
    var connectedPeripherals: [CBPeripheral] {
        if let validUUID = playerDataServiceUUID{
            return manager.retrieveConnectedPeripherals(withServices: [CBUUID(nsuuid: validUUID)])
        }
        return []
    }
}

// MARK: Public
extension GLCentralManager {
    func startScan() {
        if manager.state == .poweredOn{
            scan()
        }
    }
    
    func stopScan() {
        manager.stopScan()
    }
    
    
    func connect(with roomName: String, _ handler: @escaping ConnectHandler) {
        connectHandler = handler
        manager.connect(discoveredPeripherals.first!, options: [CBConnectPeripheralOptionNotifyOnConnectionKey: true, CBConnectPeripheralOptionNotifyOnDisconnectionKey: true])
        
//        if let targetPeripheral = self.discoveredPeripherals.filter({$0.name == roomName}).first{
//            manager.connect(targetPeripheral, options: [CBConnectPeripheralOptionNotifyOnConnectionKey: true, CBConnectPeripheralOptionNotifyOnDisconnectionKey: true])
//        }
    }
    
    func disconnect() {
        if let peripheral = self.connectedPeripheral{
            manager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func updateFinishRate(_ rate: Float) {
        centralPlayer.currentFinishRate = rate
        updateCentralPlayerData()
    }
    
    func cancelReady(){
        centralPlayer.isReady = false
        updateCentralPlayerData()
    }
    
    func getReady() {
        centralPlayer.isReady = true
        updateCentralPlayerData()
    }
}


// MARK: - Private
extension GLCentralManager {
    fileprivate func scan() {
        if manager.state == .poweredOn{
            manager.scanForPeripherals(withServices: [CBUUID(string: PlayerDataServiceUUIDString)], options: nil)
        }
    }
    
    fileprivate func updateCentralPlayerData() {
        if let peripheral = connectedPeripheral,
            let characteristic = playerDataCharacteristic{
            playerData = playerData.flatMap({ (player) -> GLPlayer in
                if player == centralPlayer{
                    return centralPlayer
                }else{
                    return player
                }
            })
            if let data = playerData.transformPlayerDataToData(){
                peripheral.writeValue(data, for: characteristic, type: .withResponse)
            }
        }
    }
}



// MARK: - CBCentralManagerDelegate
extension GLCentralManager{
    @available(iOS 5.0, *)
    internal func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn{
            print("Manager is ready to scan!")
            scan()
        }else{
        
            switch central.state {
            case .poweredOff:
                NotificationCenter.default.post(name: NotificationCentralStateChangedToUnavailable, object: nil, userInfo: ["reason": GLError.poweredOff])
            case .unauthorized:
                NotificationCenter.default.post(name: NotificationCentralStateChangedToUnavailable, object: nil, userInfo: ["reason": GLError.unauthorized])
            case .unsupported:
                NotificationCenter.default.post(name: NotificationCentralStateChangedToUnavailable, object: nil, userInfo: ["reason": GLError.unsupported])
            case .resetting:
                NotificationCenter.default.post(name: NotificationCentralStateChangedToUnavailable, object: nil, userInfo: ["reason": GLError.resetting])
            default:
                NotificationCenter.default.post(name: NotificationCentralStateChangedToUnavailable, object: nil, userInfo: ["reason": GLError.unknown])
            }
        }
        
    }
    
    internal func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String{
            if discoveredPeripheralNameInfo.contains(name) == false {
                discoveredPeripheralNameInfo.append(name)
                discoveredPeripherals.append(peripheral)
                NotificationCenter.default.post(name: NotificationCentralDidDiscoverPeripheral, object: nil, userInfo: [NotificationCentralDidDiscoverPeripheralKey: name])
            }
        }
    }
    
    internal func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
        
        if peripheral.services == nil {
//            peripheral.discoverServices(nil)
            peripheral.discoverServices([CBUUID(string: PlayerDataServiceUUIDString)])
        }
    }
    
    internal func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        NotificationCenter.default.post(name: NotificationCentralStateChangedToUnavailable, object: nil, userInfo: ["reason": GLError.disconnect])
    }
    
    internal func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NotificationCenter.default.post(name: NotificationCentralStateChangedToUnavailable, object: nil, userInfo: ["reason": GLError.failToConnect])
        if let handler = connectHandler {
            handler(false)
        }
    }
}


// MARK: - CBPeripheralDelegate
extension GLCentralManager {
    
    internal func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print(error!)
        }
        if characteristic.service.uuid.uuidString == PlayerDataServiceUUIDString {
            if let data = characteristic.value{
                playerData = data.transformDataToPlayerData()
                NotificationCenter.default.post(name: NotificationPlayerDataUpdate, object: nil, userInfo: [NotificationPlayerDataUpdateKey: playerData])
                if playerData.count == 2 {
                    if connectHandler != nil {
                        connectHandler!(true)
                    }
                }
                
            }
        }
    }
    
    internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print(error!)
        }
        

    }
    
    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if service.uuid.uuidString == PlayerDataServiceUUIDString {
            for characteristic in service.characteristics! {
                if characteristic.uuid.uuidString == GameCreaterCharacteristicUUIDString {
                    playerData.append((characteristic.value?.transformDataToPlayerData().first)!)
                } else {
                    playerDataCharacteristic = characteristic
                    if let data = playerData.transformPlayerDataToData(){
                        peripheral.setNotifyValue(true, for: playerDataCharacteristic!)
                        peripheral.writeValue(data, for: playerDataCharacteristic!, type: .withResponse)
                    }
                }
            }
        }
    }
    
    internal func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print(error!)
            return
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print(error!)
            return
        }
        connectedPeripheral = peripheral
        if let service = peripheral.services?.first {
            peripheral.discoverCharacteristics(nil, for: service)
//            peripheral.discoverCharacteristics([CBUUID(string: PlayerDataCharacteristicUUIDString)], for:service)
        }
        
    }
}





extension Array where Element == GLPlayer {

    func transformPlayerDataToData() -> Data? {
        
        if let jsonStr = [GLPlayer].toJSONString(self)(prettyPrint: true){
            return jsonStr.data(using: .utf8)
        }
        return nil
        
        
        var tmpJson:[[String: Any]] = []
        for player in self{
            if let json = player.toJSON(){
                tmpJson.append(json)
            }
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: tmpJson, options: .prettyPrinted)
            return data
        }catch(let error){
            print(error)
        }
        return nil
    }
}


extension Data {
    func transformDataToPlayerData() -> [GLPlayer] {
        
        if let jsonStr = String(data: self, encoding: .utf8),
          let result = [GLPlayer].deserialize(from: jsonStr) as? [GLPlayer]{
            return result
        }
        return []

        
        var tmpPlayers:[GLPlayer] = []
        do {
            let playerDataArray = try JSONSerialization.jsonObject(with: self, options: .mutableContainers)
            
            

            for playerData in playerDataArray as! [[String: Any]]{
                if let player = GLPlayer.deserialize(from: playerData as NSDictionary){
                    tmpPlayers.append(player)
                }
            }
        } catch(let error){
            print(error)
        }
        return tmpPlayers
    }
}

