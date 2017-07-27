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
    
    
    @IBOutlet weak var otherPlayerPositionLbl: UILabel!
    @IBOutlet weak var currentPostionLbl: UILabel!
    @IBOutlet weak var otherPlayerView: UIImageView!
    
    
    @IBAction func leftBtnDidTapped(_ sender: UIButton) {
        myPlayer!.currentFinishRate += 1
        currentPostionLbl.text = "\(myPlayer!.currentFinishRate)"
        checkIfFinish()
        
    }
    
    @IBAction func rightBtnDidTapped(_ sender: UIButton) {
        myPlayer!.currentFinishRate += 1
        currentPostionLbl.text = "\(myPlayer!.currentFinishRate)"
        checkIfFinish()
    }
    
}


// MARK: - Life cycle
extension GLGameViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        if isRoomCreater {
            peripheralManager = GLPeripheralManager.default
            myPlayer = peripheralManager?.peripheralPlayer
        } else {
            centralManager = GLCentralManager.default
            myPlayer = centralManager?.centralPlayer
        }
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(sendMyPlayerData), userInfo: nil, repeats: true)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(playerFinishRateDidUpdate(_:)), name: NotificationOtherPlayerFinishRateDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(errorDidOccur(_ :)), name: NotificationErrorDidOccur, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NotificationOtherPlayerFinishRateDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: NotificationErrorDidOccur, object: nil)
    }
}

// MARK: - Notification call-back method
extension GLGameViewController{
    @objc fileprivate func playerFinishRateDidUpdate(_ notification: Notification){
        if let otherPlayerRate = notification.userInfo?[NotificationOtherPlayerFinishRateKey] as? Float {
            DispatchQueue.main.async {[weak self] in
                self?.otherPlayerPositionLbl.text = "\(otherPlayerRate)"
                if otherPlayerRate == 100 {
                UIAlertView(title: "Boom", message: "You Lose!", delegate: nil, cancelButtonTitle: "Ok").show()
                self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    
    @objc fileprivate func errorDidOccur(_ notification: Notification) {
        if let error = notification.userInfo?[NotificationErrorKey] as? GLError {
            print(error)
            if isRoomCreater{
                peripheralManager!.stopAdvertising()
            }
            DispatchQueue.main.async {[weak self] in
                self?.navigationController?.popToRootViewController(animated: true)
            }
        }
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
            UIAlertView(title: "Boom", message: "You Lose!", delegate: nil, cancelButtonTitle: "Ok").show()
            timer?.invalidate()
            sendMyPlayerData()
            navigationController?.popViewController(animated: true)
        }
    }
    
    fileprivate func drawPlayerInScreen() {
        
    }
}



