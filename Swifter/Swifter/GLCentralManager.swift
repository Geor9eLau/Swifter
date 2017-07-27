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

let PlayerReadyStateCharacteristicUUIDString = "8D50AD4E-E058-404C-8DD6-E116C8376D43"

let PlayerDataServiceUUIDString = "69C88932-A2FD-4FB0-B74E-917ADEFFAF04"
let PlayerNameCharacteristicUUIDString = "2B9437B4-D3DA-4ED2-9CD1-59AFD2BB593F"
let PlayerFinishRateCharacteristicUUIDString = "A853EEBC-481C-43AA-8589-515B196E7EB6"

class GLCentralManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let `default`: GLCentralManager = {
        return GLCentralManager()
    }()
    
    fileprivate let queue = DispatchQueue(label: "CentralQueue")
    fileprivate var manager: CBCentralManager!
    fileprivate let playerDataServiceUUID = UUID(uuidString: PlayerDataServiceUUIDString)
    fileprivate var connectedPeripheral: CBPeripheral?
    fileprivate var playerFinishRateCharacteristic: CBCharacteristic?
    fileprivate var playerReadyStateCharacteristic: CBCharacteristic?
    fileprivate var playerNameCharacteristic: CBCharacteristic?
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
    
    
    func connect(with roomName: String) {
        manager.connect(discoveredPeripherals.first!, options: [CBConnectPeripheralOptionNotifyOnConnectionKey: true, CBConnectPeripheralOptionNotifyOnDisconnectionKey: true])

    }
    
    func disconnect() {
        if let peripheral = self.connectedPeripheral{
            manager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func updateFinishRate(_ rate: Float) {
        centralPlayer.currentFinishRate = rate
        
        if let data = "\(rate)".data(using: .utf8),
            let peripheral = connectedPeripheral,
             let characteristic = playerFinishRateCharacteristic{
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
    
    func cancelReady(){
        centralPlayer.isReady = false
        
        if let data = "0".data(using: .utf8),
            let peripheral = connectedPeripheral,
            let characteristic = playerReadyStateCharacteristic{
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
    
    func getReady() {
        centralPlayer.isReady = true
        centralPlayer.currentFinishRate = 0
        if let data = "1".data(using: .utf8),
            let peripheral = connectedPeripheral,
            let characteristic = playerReadyStateCharacteristic{
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
}


// MARK: - Private
extension GLCentralManager {
    fileprivate func scan() {
        if manager.state == .poweredOn{
            manager.scanForPeripherals(withServices: [CBUUID(string: PlayerDataServiceUUIDString)], options: nil)
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
                NotificationCenter.default.post(name: NotificationErrorDidOccur, object: nil, userInfo: [NotificationErrorKey : GLError.poweredOff])
            case .unauthorized:
                NotificationCenter.default.post(name: NotificationErrorDidOccur, object: nil, userInfo: [NotificationErrorKey: GLError.unauthorized])
            case .unsupported:
                NotificationCenter.default.post(name: NotificationErrorDidOccur, object: nil, userInfo: [NotificationErrorKey: GLError.unsupported])
            case .resetting:
                NotificationCenter.default.post(name: NotificationErrorDidOccur, object: nil, userInfo: [NotificationErrorKey: GLError.resetting])
            default:
                NotificationCenter.default.post(name: NotificationErrorDidOccur, object: nil, userInfo: [NotificationErrorKey: GLError.unknown])
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
            peripheral.discoverServices([CBUUID(string: PlayerDataServiceUUIDString)])
        }
    }
    
    internal func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        NotificationCenter.default.post(name: NotificationErrorDidOccur, object: nil, userInfo: [NotificationErrorKey: GLError.disconnect])
    }
    
    internal func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NotificationCenter.default.post(name: NotificationErrorDidOccur, object: nil, userInfo: [NotificationErrorKey: GLError.failToConnect])
    }
}


// MARK: - CBPeripheralDelegate
extension GLCentralManager {
    
    internal func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print(error!)
        }
    
        if let data = characteristic.value,
            let dataStr = String(data: data, encoding: .utf8){
            switch characteristic.uuid.uuidString {
            case PlayerNameCharacteristicUUIDString:
                NotificationCenter.default.post(name: NotificationDidReceiveOtherPlayerName, object: nil, userInfo: [NotificationOtherPlayerNameKey: dataStr])
                
            case PlayerReadyStateCharacteristicUUIDString:
                NotificationCenter.default.post(name: NotificationOtherPlayerReadyStateDidChange, object: nil, userInfo: [NotificationOtherPlayerReadyStateKey: dataStr])
            case PlayerFinishRateCharacteristicUUIDString:
                let rate = Float(dataStr)
                NotificationCenter.default.post(name: NotificationOtherPlayerFinishRateDidChange, object: nil, userInfo: [NotificationOtherPlayerFinishRateKey: rate as Any])
            default:
                return
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
                switch characteristic.uuid.uuidString {
                case PlayerNameCharacteristicUUIDString:
                    playerNameCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                    if let myNameData = centralPlayer.name.data(using: .utf8){
                        peripheral.writeValue(myNameData, for: characteristic, type: .withResponse)
                    }
                case PlayerReadyStateCharacteristicUUIDString:
                    playerReadyStateCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                case PlayerFinishRateCharacteristicUUIDString:
                    playerFinishRateCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                default:
                    return
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
        }
        
    }
}





