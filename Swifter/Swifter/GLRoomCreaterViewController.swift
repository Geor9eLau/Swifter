//
//  GLRoomCreaterViewController.swift
//  Swifter
//
//  Created by George on 2017/6/16.
//  Copyright © 2017年 George. All rights reserved.
//

import Foundation
import UIKit

class GLRoomCreaterViewController: GLBaseViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var launchGameButton: UIButton!
    fileprivate var centralManager: GLCentralManager?
    fileprivate var peripheralManager: GLPeripheralManager?
    var isRoomCreater: Bool = false
    var isReadyToGo: Bool = false
    fileprivate var playerData: [GLPlayer] = []
    
    @IBAction func playGame(_ sender: Any) {
        if isRoomCreater {
            peripheralManager?.startGame()
            let gameVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GameViewController") as! GLGameViewController
            gameVC.isRoomCreater = true
            navigationController?.pushViewController(gameVC, animated: true)
        } else {
            if isReadyToGo {
                centralManager?.cancelReady()
            } else {
                centralManager?.getReady()
            }
            isReadyToGo = !isReadyToGo
            updateLaunchBtn()
        }
    }
    
}

// MARK: - Life cycle
extension GLRoomCreaterViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
        if isRoomCreater {
            peripheralManager = GLPeripheralManager.default
            playerData = (peripheralManager?.playerData)!
            collectionView.reloadData()
        } else{
            centralManager = GLCentralManager.default
            playerData = (centralManager?.playerData)!
            collectionView.reloadData()
        }
        
        updateLaunchBtn()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(playerReadyStateUpdate(_:)), name: NotificationOtherPlayerReadyStateDidChange, object: nil)
        if isRoomCreater{
            NotificationCenter.default.addObserver(self, selector: #selector(otherPlayerQuit(_:)), name: NotificationPeripheralUpdateSubscriber, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(otherPlayerDidJoin(_:)), name: NotificationDidReceiveOtherPlayerName, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(quit(_:)), name: NotificationPeripheralDeviceChangedToUnavailable, object: nil)
        } else{
            NotificationCenter.default.addObserver(self, selector: #selector(quit(_:)), name: NotificationCentralStateChangedToUnavailable, object: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NotificationOtherPlayerReadyStateDidChange, object: nil)
        if isRoomCreater{
            NotificationCenter.default.removeObserver(self, name: NotificationPeripheralUpdateSubscriber, object: nil)
            NotificationCenter.default.removeObserver(self, name: NotificationPeripheralDeviceChangedToUnavailable, object: nil)
            NotificationCenter.default.removeObserver(self, name: NotificationDidReceiveOtherPlayerName, object: nil)
        } else{
            NotificationCenter.default.removeObserver(self, name: NotificationCentralStateChangedToUnavailable, object: nil)
        }
    }
}

// MARK: - Notification call-back method
extension GLRoomCreaterViewController{
    func otherPlayerDidJoin(_ notification: Notification) {
        if let name = notification.userInfo?[NotificationOtherPlayerNameKey] as? String{
            let otherPlayer = GLPlayer(name: name, currentFinishRate: 0, isRoomCreater: false, isReady: true)
            if playerData.contains(otherPlayer) == false {
                playerData.append(otherPlayer)
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    
    func playerReadyStateUpdate(_ notification: Notification){
        if let info = notification.userInfo,
            let otherPlayerIsReady = info[NotificationOtherPlayerReadyStateKey] as? String{
            let isReady = otherPlayerIsReady == "1" ? true : false
            if isRoomCreater {
                isReadyToGo = isReady
                DispatchQueue.main.async {
                    self.updateLaunchBtn()
                }
                
            } else {
                if isReady {
                    let gameVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GameViewController") as! GLGameViewController
                    gameVC.isRoomCreater = false
                    
                    DispatchQueue.main.async {
                        self.navigationController?.pushViewController(gameVC, animated: true)
                    }
                }
            }
        }
    }
    
    func otherPlayerQuit(_ notification: Notification) {
        playerData.removeLast()
        DispatchQueue.main.async {[weak self] in
            self?.collectionView.reloadData()
        }
    }
    
    func quit(_ notification: Notification) {
        if isRoomCreater{
            peripheralManager!.stopAdvertising()
        }
        DispatchQueue.main.async {[weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        
    }
}

// MARK: - Private
extension GLRoomCreaterViewController{
    func updateLaunchBtn() {
        if isRoomCreater {
            if isReadyToGo{
                launchGameButton.setTitle("Go", for: .normal)
                launchGameButton.backgroundColor = UIColor.green
                launchGameButton.isEnabled = true
            } else {
                launchGameButton.setTitle("Go", for: .normal)
                launchGameButton.backgroundColor = UIColor.gray
                launchGameButton.isEnabled = false
            }
        }
        else {
            if isReadyToGo{
                launchGameButton.setTitle("Cancel", for: .normal)
                launchGameButton.backgroundColor = UIColor.red
            } else {
                launchGameButton.setTitle("Ready", for: .normal)
                launchGameButton.backgroundColor = UIColor.green
            }
        }
    }
}

// MARK: - Event handler
extension GLRoomCreaterViewController {
    
}



// MARK: - UICollectionViewDataSource
extension GLRoomCreaterViewController{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return playerData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlayerInfoCellIdentifier, for: indexPath) as! GLPlayerInfoCell
        cell.avatar = nil
        let player = playerData[indexPath.row]
        cell.nameLbl.text = player.name
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension GLRoomCreaterViewController {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
