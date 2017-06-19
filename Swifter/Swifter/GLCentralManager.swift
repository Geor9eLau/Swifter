//
//  GLCentralManager.swift
//  Swifter
//
//  Created by George on 2017/6/14.
//  Copyright © 2017年 George. All rights reserved.
//

import Foundation
import CoreBluetooth

let GameSwitchServiceUUIDString = "8D50AD4E-E058-404C-8DD6-E116C8376D43"
let PlayerDataServiceUUIDString = "69C88932-A2FD-4FB0-B74E-917ADEFFAF04"
let PlayerDataCharacteristicUUIDString = "2B9437B4-D3DA-4ED2-9CD1-59AFD2BB593F"
let GameSwitchCharacteristicUUIDString = "A853EEBC-481C-43AA-8589-515B196E7EB6"

protocol GLCentralManagerDelegate: class {
    func centralManager(_ manager: GLCentralManager, update playerData: Data)
    func centralManager(_ manager: GLCentralManager, didFail error: GLError)
    func centralManager(_ manager: GLCentralManager, didDiscoverPeripheral peripheralNameInfo: [String])
    func centralManagerDidConectedToTarget(_ manager: GLCentralManager)
}

class GLCentralManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let `default`: GLCentralManager = {
        return GLCentralManager()
    }()
    
    fileprivate let queue = DispatchQueue(label: "CentralQueue")
    fileprivate var manager: CBCentralManager!
    fileprivate let playerDataUUID = UUID(uuidString: PlayerDataServiceUUIDString)
    fileprivate let gameSwitchUUID = UUID(uuidString: GameSwitchCharacteristicUUIDString)
    fileprivate var connectedPeripheral: CBPeripheral?
    fileprivate var gameSwitchCharacteristic: CBCharacteristic?
    fileprivate var playerDataCharacteristic: CBCharacteristic?
    override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: queue)
    }
    
    weak var delegate: GLCentralManagerDelegate?
    
    var discoveredPeripheralNameInfo: [String] = []
    
    var discoveredPeripherals: [CBPeripheral] {
        if let validPlayerDataUUID = playerDataUUID,
            let vaildGameSwitchUUID = gameSwitchUUID{
            return manager.retrievePeripherals(withIdentifiers: [validPlayerDataUUID, vaildGameSwitchUUID])
        }
        return []
    }
    
    var connectedPeripherals: [CBPeripheral] {
        if let validPlayerDataUUID = playerDataUUID,
            let vaildGameSwitchUUID = gameSwitchUUID{
            return manager.retrieveConnectedPeripherals(withServices: [CBUUID(nsuuid: validPlayerDataUUID), CBUUID(nsuuid: vaildGameSwitchUUID)])
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
    
    
    func connect(with name: String) {
        if let targetPeripheral = self.discoveredPeripherals.filter({$0.name == name}).first{
            manager.connect(targetPeripheral, options: [CBConnectPeripheralOptionNotifyOnConnectionKey: true, CBConnectPeripheralOptionNotifyOnDisconnectionKey: true])
        }
    }
    
    func disconnect() {
        if let peripheral = self.connectedPeripheral{
            manager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func send(_ data: Data) {
        if let peripheral = connectedPeripheral,
            let characteristic = playerDataCharacteristic{
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        }
    }
}


// MARK: - Private
extension GLCentralManager {
    fileprivate func scan() {
        if let validPlayerDataUUID = playerDataUUID,
            let vaildGameSwitchUUID = gameSwitchUUID{
            manager.scanForPeripherals(withServices: [CBUUID(nsuuid: validPlayerDataUUID), CBUUID(nsuuid: vaildGameSwitchUUID)], options: nil)
        }
    }
}



// MARK: - CBCentralManagerDelegate
extension GLCentralManager{
    @available(iOS 5.0, *)
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn{
            print("Manager is ready to scan!")
        }
        if let validDelegate = delegate {
            switch central.state {
            case .poweredOff:
                validDelegate.centralManager(self, didFail: .poweredOff)
            case .unauthorized:
                validDelegate.centralManager(self, didFail: .unauthorized)
            case .unsupported:
                validDelegate.centralManager(self, didFail: .unsupported)
            case .resetting:
                validDelegate.centralManager(self, didFail: .resetting)
            default:
                validDelegate.centralManager(self, didFail: .unknown)
            }
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String,
            let validDelegate = delegate{
            if discoveredPeripheralNameInfo.contains(name) == false {
                discoveredPeripheralNameInfo.append(name)
                validDelegate.centralManager(self, didDiscoverPeripheral: discoveredPeripheralNameInfo)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: PlayerDataServiceUUIDString), CBUUID(string: GameSwitchCharacteristicUUIDString)])
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let validDelegate = delegate {
            validDelegate.centralManager(self, didFail: .disconnect)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let validDelegate = delegate {
            validDelegate.centralManager(self, didFail: .failToConnect)
        }
    }
}


// MARK: - CBPeripheralDelegate
extension GLCentralManager {
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print(error!)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print(error!)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if service.uuid.uuidString == PlayerDataServiceUUIDString {
            if let characteritic = service.characteristics?.first {
                playerDataCharacteristic = characteritic as? CBMutableCharacteristic
                peripheral.setNotifyValue(true, for: characteritic)
            }
        }
        else if service.uuid.uuidString == GameSwitchServiceUUIDString {
            if let characteritic = service.characteristics?.first {
                gameSwitchCharacteristic = characteritic as? CBMutableCharacteristic
                peripheral.setNotifyValue(true, for: characteritic)
            }
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print(error!)
            return
        }
        
        if characteristic.service.uuid.uuidString == PlayerDataServiceUUIDString {
            if let data = characteristic.value,
                let validDelegate = delegate{
                validDelegate.centralManager(self, update: data)
            }
        }
        
    }
}

