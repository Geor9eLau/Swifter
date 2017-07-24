//
//  GLGameViewController.swift
//  Swifter
//
//  Created by George on 2017/6/16.
//  Copyright © 2017年 George. All rights reserved.
//

import Foundation
import UIKit

class GLGameViewController: GLBaseViewController {
    fileprivate var centralManager: GLCentralManager?
    fileprivate var peripheralManager: GLPeripheralManager?
    fileprivate var myPlayer: GLPlayer?
    fileprivate var playerData: [GLPlayer] = []
    fileprivate var timer: Timer?
    var isRoomCreater: Bool = false
    
    
    
    
    @IBAction func leftBtnDidTapped(_ sender: UIButton) {
        myPlayer!.currentFinishRate += 1
    }
    
    @IBAction func rightBtnDidTapped(_ sender: UIButton) {
        myPlayer!.currentFinishRate += 1
    }
    
}


// MARK: - Life cycle
extension GLGameViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        if isRoomCreater {
            centralManager = GLCentralManager.default
        } else {
            peripheralManager = GLPeripheralManager.default
        }
        timer = Timer(timeInterval: 0.1, target: self, selector: #selector(sendMyPlayerData), userInfo: nil, repeats: true)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(playerDataDidUpdate(_:)), name: NotificationPlayerDataUpdate, object: nil)
        if isRoomCreater{
            NotificationCenter.default.addObserver(self, selector: #selector(otherPlayerQuit(_:)), name: NotificationPeripheralUpdateSubscriber, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(quit(_:)), name: NotificationPeripheralDeviceChangedToUnavailable, object: nil)
        } else{
            NotificationCenter.default.addObserver(self, selector: #selector(quit(_:)), name: NotificationCentralStateChangedToUnavailable, object: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NotificationPlayerDataUpdate, object: nil)
        if isRoomCreater{
            NotificationCenter.default.removeObserver(self, name: NotificationPeripheralUpdateSubscriber, object: nil)
            NotificationCenter.default.removeObserver(self, name: NotificationPeripheralDeviceChangedToUnavailable, object: nil)
        } else{
            NotificationCenter.default.removeObserver(self, name: NotificationCentralStateChangedToUnavailable, object: nil)
        }
    }
}

// MARK: - Notification call-back method
extension GLGameViewController{
    func playerDataDidUpdate(_ notification: Notification){
        if let players = notification.userInfo?[NotificationPlayerDataUpdateKey] as? [GLPlayer] {
            playerData = players
            
        }
    }
    
    func otherPlayerQuit(_ notification: Notification) {
        
    }
    
    func quit(_ notification: Notification) {
        if isRoomCreater{
            peripheralManager!.stopAdvertising()
        }
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Private
extension GLGameViewController {
    @objc fileprivate func sendMyPlayerData() {
        if isRoomCreater {
            centralManager?.updateFinishRate((myPlayer?.currentFinishRate)!)
        } else {
            peripheralManager?.updateFinishRate((myPlayer?.currentFinishRate)!)
        }
    }
    
    fileprivate func drawPlayerInScreen() {
        
    }
}



