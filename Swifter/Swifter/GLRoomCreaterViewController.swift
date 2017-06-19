//
//  GLRoomCreaterViewController.swift
//  Swifter
//
//  Created by George on 2017/6/16.
//  Copyright © 2017年 George. All rights reserved.
//

import Foundation
import UIKit


class GLRoomCreaterViewController: GLBaseViewController, UICollectionViewDelegate, UICollectionViewDataSource, GLPeripheralManagerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var launchGameButton: UIButton!
    
    
    var isRoomCreater: Bool = false
    fileprivate var peripheralManager: GLPeripheralManager?
    fileprivate var playerCount: Int = 1
}


// MARK: - Life Cycle
extension GLRoomCreaterViewController {
    override func viewDidLoad() {
        if isRoomCreater {
            peripheralManager = GLPeripheralManager.default
            peripheralManager?.delegate = self
            peripheralManager?.startAdvertising()
        }
    }
}


// MARK: - GLPeripheralManagerDelegate
extension GLRoomCreaterViewController {
    func peripheralManager(_ manager: GLPeripheralManager, update playerData: Data) {
        
    }
    
    func peripheralManager(_ manager: GLPeripheralManager, didFail error: GLError) {
        
    }
    
    func peripheralManager(_ manager: GLPeripheralManager, didGetNewSubscriber subscriberCount: Int) {
        playerCount = 1 + subscriberCount
        collectionView.reloadData()
    }
}


// MARK: - UICollectionViewDataSource
extension GLRoomCreaterViewController{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return playerCount
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
