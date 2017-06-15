//
//  GLPeripheralManager.swift
//  Swifter
//
//  Created by George on 2017/6/15.
//  Copyright © 2017年 George. All rights reserved.
//

import Foundation
import CoreBluetooth


class GLPeripheralManager: NSObject, CBPeripheralManagerDelegate {
    static let `default`: GLPeripheralManager = {
       return GLPeripheralManager()
    }()
    
    private let queue = DispatchQueue(label: "PeripheralQueue")
    private var manager: CBPeripheralManager!
    
    private var subscribedCenteral: [CBCentral] = []
    private override init() {
        super.init()
        manager = CBPeripheralManager(delegate: self, queue: queue)
        manager.add(CBMutableService(type: CBUUID(string: ServiceUUIDString), primary: true))
        
        
        
        var characteristics = CBMutableCharacteristic(type: CBUUID(string: ServiceUUIDString), properties: [.notify , .read] , value: nil, permissions: [.writeable, .readable])
    }
}


extension GLPeripheralManager {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
    }
    
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        if subscribedCenteral.contains(central) == false {
            subscribedCenteral.append(central)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        if subscribedCenteral.contains(central) {
            subscribedCenteral.remove(at: subscribedCenteral.index(of: central)!)
        }
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        
    }
    
    
    
    
}
