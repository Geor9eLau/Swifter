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
    
    
    @IBOutlet weak var currentPostionLbl: UILabel!
    @IBOutlet weak var otherPlayerView: UIImageView!
    
    
    @IBAction func leftBtnDidTapped(_ sender: UIButton) {
        myPlayer!.currentFinishRate += 1
        currentPostionLbl.text = "\(myPlayer!.currentFinishRate)"
    }
    
    @IBAction func rightBtnDidTapped(_ sender: UIButton) {
        myPlayer!.currentFinishRate += 1
        currentPostionLbl.text = "\(myPlayer!.currentFinishRate)"
    }
    
}


// MARK: - Life cycle
extension GLGameViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        if isRoomCreater {
            peripheralManager = GLPeripheralManager.default
        } else {
            centralManager = GLCentralManager.default
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
            if let otherPlayer = players.filter({$0.name != myPlayer?.name}).first,
                otherPlayer.currentFinishRate == 100 {
                let finishView = UIView(frame: UIScreen.main.bounds)
                finishView.backgroundColor = UIColor.red
                finishView.alpha = 0.5
                UIApplication.shared.keyWindow?.addSubview(finishView)
            }
        }
    }
    
    func otherPlayerQuit(_ notification: Notification) {
        let finishView = UIView(frame: UIScreen.main.bounds)
        finishView.backgroundColor = UIColor.red
        finishView.alpha = 0.5
        UIApplication.shared.keyWindow?.addSubview(finishView)
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
            peripheralManager?.updateFinishRate((myPlayer?.currentFinishRate)!)
        } else {
            centralManager?.updateFinishRate((myPlayer?.currentFinishRate)!)
        }
    }
    
    fileprivate func checkIfFinish() {
        if myPlayer?.currentFinishRate == 100 {
            let finishView = UIView(frame: UIScreen.main.bounds)
            finishView.backgroundColor = UIColor.green
            finishView.alpha = 0.5
            UIApplication.shared.keyWindow?.addSubview(finishView)
        }
    }
    
    fileprivate func drawPlayerInScreen() {
        
    }
}



