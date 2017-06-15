//
//  GLPeripheralManager.swift
//  Swifter
//
//  Created by George on 2017/6/15.
//  Copyright © 2017年 George. All rights reserved.
//

import Foundation
import CoreBluetooth


protocol GLPeripheralManagerDelegate: class {
    func peripheralManager(_ manager: GLPeripheralManager, update playerData: Data)
    func peripheralManager(_ manager: GLPeripheralManager, didFail error: GLError)
}

class GLPeripheralManager: NSObject, CBPeripheralManagerDelegate {
    static let `default`: GLPeripheralManager = {
       return GLPeripheralManager()
    }()
    
    private let queue = DispatchQueue(label: "PeripheralQueue")
    private var manager: CBPeripheralManager!
    private var subscribedCenteral: [CBCentral] = []
    private var targetCharacteristic: CBMutableCharacteristic?
    weak var delegate: GLPeripheralManagerDelegate?
    private override init() {
        super.init()
        manager = CBPeripheralManager(delegate: self, queue: queue)
    }
}


// MARK: - Private
extension GLPeripheralManager {
    func setupService(){
        targetCharacteristic = CBMutableCharacteristic(type: CBUUID(string: CharacteristicsUUIDString), properties: [.notify , .read] , value: nil, permissions: [.writeable, .readable])
        let service = CBMutableService(type: CBUUID(string: ServiceUUIDString), primary: true)
        service.characteristics = [targetCharacteristic!]
        manager.add(service)
    }
}


// MARK: - Public
extension GLPeripheralManager {
    func startAdvertising() {
        if manager.state == .poweredOn{
            manager.startAdvertising([CBAdvertisementDataLocalNameKey: "George", CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: ServiceUUIDString)]])
        }
    }
    
    func stopAdvertising() {
        if manager.isAdvertising {
            manager.stopAdvertising()
        }
    }
    
    func send(_ data: Data) {
        if let characteristic = targetCharacteristic {
            manager.updateValue(data, for: characteristic, onSubscribedCentrals: subscribedCenteral)
        }
    }
}


// MARK: - CBPeripheralManagerDelegate
extension GLPeripheralManager {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn{
            setupService()
        }
        
        if let validDelegate = delegate {
            switch peripheral.state {
            case .poweredOff:
                validDelegate.peripheralManager(self, didFail: .poweredOff)
            case .unauthorized:
                validDelegate.peripheralManager(self, didFail: .unauthorized)
            case .unsupported:
                validDelegate.peripheralManager(self, didFail: .unsupported)
            case .resetting:
                validDelegate.peripheralManager(self, didFail: .resetting)
            default:
                validDelegate.peripheralManager(self, didFail: .unknown)
            }
        }
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
    
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        if let characteristic = requests.first,
            let data = characteristic.value,
            let validDelegate = delegate{
                validDelegate.peripheralManager(self, update: data)
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if error != nil {
            print(error!)
        }
    }
}
