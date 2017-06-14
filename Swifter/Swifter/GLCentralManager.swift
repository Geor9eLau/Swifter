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

class GLCentralManager: NSObject, CBCentralManagerDelegate {
    static let `default`: GLCentralManager = {
       return GLCentralManager()
    }()
    
    private var discoveredPeripherals: [CBPeripheral] = []
    private var connectedPeripherals: [CBPeripheral] = []
    private let queue = DispatchQueue(label: "CentralQueue")
    private var manager: CBCentralManager!
    private override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: queue)
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
        if !discoveredPeripherals.contains(peripheral){
            discoveredPeripherals.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if !connectedPeripherals.contains(peripheral) && discoveredPeripherals.contains(peripheral){
            connectedPeripherals.append(peripheral)
            discoveredPeripherals.remove(at: discoveredPeripherals.index(of: peripheral)!)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripherals.remove(at: connectedPeripherals.index(of: peripheral)!)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
    }
}


extension GLCentralManager {
    func scan() {
        manager.scanForPeripherals(withServices: [CBUUID(string: ServiceUUIDString)], options: nil)
    }
}
