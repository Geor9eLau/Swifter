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

class GLCentralManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let `default`: GLCentralManager = {
       return GLCentralManager()
    }()
    
    
    private let queue = DispatchQueue(label: "CentralQueue")
    private var manager: CBCentralManager!
    private let uuid = UUID(uuidString: ServiceUUIDString)
    private var connectedPeripheral: CBPeripheral?
    private override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: queue)
    }
    
    
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
    
}


// MARK: - Private
extension GLCentralManager {
    func scan() {
        manager.scanForPeripherals(withServices: [CBUUID(string: ServiceUUIDString)], options: nil)
    }
}

extension GLCentralManager{
    @available(iOS 5.0, *)
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn{
            scan()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
    }
}

extension GLCentralManager {
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
    }
}

