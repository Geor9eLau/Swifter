//
//  GLCentralManager.swift
//  Swifter
//
//  Created by George on 2017/6/14.
//  Copyright © 2017年 George. All rights reserved.
//

import Foundation
import CoreBluetooth

let ServiceUUIDString = "69C88932-A2FD-4FB0-B74E-917ADEFFAF04"
let CharacteristicsUUIDString = "2B9437B4-D3DA-4ED2-9CD1-59AFD2BB593F"

protocol GLCentralManagerDelegate: class {
    func centralManager(_ manager: GLCentralManager, update playerData: Data)
    func centralManager(_ manager: GLCentralManager, didFail error: GLError)
    
}


class GLCentralManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let `default`: GLCentralManager = {
        return GLCentralManager()
    }()
    
    private let queue = DispatchQueue(label: "CentralQueue")
    private var manager: CBCentralManager!
    private let uuid = UUID(uuidString: ServiceUUIDString)
    private var connectedPeripheral: CBPeripheral?
    private var targetCharacteristic: CBCharacteristic?
    private override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: queue)
    }
    
    weak var delegate: GLCentralManagerDelegate?
    var discoveredPeripherals: [CBPeripheral] {
        if let validUUID = uuid {
            return manager.retrievePeripherals(withIdentifiers: [validUUID])
        }
        return []
    }
    
    var connectedPeripherals: [CBPeripheral] {
        if let validUUID = uuid {
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
    
    func send(_ data: Data) {
        if let peripheral = connectedPeripheral,
            let characteristic = targetCharacteristic{
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        }
    }
}


// MARK: - Private
extension GLCentralManager {
    func scan() {
        manager.scanForPeripherals(withServices: [CBUUID(string: ServiceUUIDString)], options: nil)
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
        central.connect(peripheral, options: [CBConnectPeripheralOptionNotifyOnConnectionKey: true, CBConnectPeripheralOptionNotifyOnDisconnectionKey: true])
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: ServiceUUIDString)])
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let vaildDelegate = delegate {
            vaildDelegate.centralManager(self, didFail: .disconnect)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let vaildDelegate = delegate {
            vaildDelegate.centralManager(self, didFail: .failToConnect)
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
        if let characteritic = service.characteristics?.first {
            targetCharacteristic = characteritic
            peripheral.setNotifyValue(true, for: characteritic)
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print(error!)
            return
        }
        
        if let data = characteristic.value,
            let validDelegate = delegate{
            validDelegate.centralManager(self, update: data)
        }
    }
}

