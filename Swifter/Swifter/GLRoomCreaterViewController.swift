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
            peripheralManager?.startGame({[weak self] (isSucceed) in
                let gameVC = GLGameViewController(nibName: "GLGameViewController", bundle: nil)
                gameVC.isRoomCreater = true
                self?.navigationController?.pushViewController(gameVC, animated: true)
            })
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
//            peripheralManager!.startAdvertising()
            playerData.append(peripheralManager!.peripheralPlayer)
            collectionView.reloadData()
        } else{
            centralManager = GLCentralManager.default
            playerData = (centralManager?.playerData)!
            collectionView.reloadData()
        }
        
        updateLaunchBtn()
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
extension GLRoomCreaterViewController{
    func playerDataDidUpdate(_ notification: Notification){
        if let players = notification.userInfo?[NotificationPlayerDataUpdateKey] as? [GLPlayer] {
            DispatchQueue.main.async {[weak self] in
                self?.playerData = players
                self?.collectionView.reloadData()
                if (self?.isRoomCreater)! {
                    guard self?.playerData.filter({$0.isReady == false}).count == 1 else {
                        print("Some player is not ready to go")
                        self?.isReadyToGo = false
                        self?.updateLaunchBtn()
                        return
                    }
                    self?.isReadyToGo = true
                    self?.updateLaunchBtn()
                } else {
                    if self?.playerData.filter({$0.isReady == false}).count == 0 {
                        let gameVC = GLGameViewController(nibName: "GLGameViewController", bundle: nil)
                        gameVC.isRoomCreater = false
                        self?.navigationController?.pushViewController(gameVC, animated: true)
                    }
                }
            }
            
        }
    }
    
    func otherPlayerQuit(_ notification: Notification) {
        DispatchQueue.main.async {[weak self] in
            self?.playerData.append((self?.peripheralManager!.peripheralPlayer)!)
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
        if indexPath.row == 0 {
            cell.nameLbl.text = UIDevice.current.name
        }else{
            cell.nameLbl.text = "Player \(indexPath.row + 1)"
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension GLRoomCreaterViewController {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
