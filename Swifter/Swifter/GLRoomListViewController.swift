//
//  GLRoomListViewController.swift
//  Swifter
//
//  Created by George on 2017/6/16.
//  Copyright © 2017年 George. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

class GLRoomListViewController: GLBaseViewController, UITableViewDelegate, UITableViewDataSource {
    let joinRoomSegueIdentifier = "JoinRoom"
    fileprivate var centralManager: GLCentralManager?
    fileprivate var isRoomCreater: Bool = false
    @IBOutlet weak var tableView: UITableView!
    fileprivate var dataSource: [String] = []

}

// MARK: - Life cycle
extension GLRoomListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = GLCentralManager.default
        //        centralManager?.startScan()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(didDiscoverPeripheral(_:)), name: NotificationCentralDidDiscoverPeripheral, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveOtherPlayerName), name: NotificationDidReceiveOtherPlayerName, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NotificationCentralDidDiscoverPeripheral, object: nil)
    }
}

// MARK: - Notification call-back method
extension GLRoomListViewController {
    func didDiscoverPeripheral(_ notification: Notification) {
        if let roomCreaterName = notification.userInfo?[NotificationCentralDidDiscoverPeripheralKey] as? String{
            dataSource.append(roomCreaterName)
            DispatchQueue.main.async {[weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    
    func didReceiveOtherPlayerName(_ notification: Notification) {
        if let name = notification.userInfo?[NotificationOtherPlayerNameKey] as? String{
            let player = GLPlayer(name: name, currentFinishRate: 0, isRoomCreater: true, isReady: false)
            centralManager?.playerData.insert(player, at: 0)
            let roomVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GLRoomCreaterViewController") as! GLRoomCreaterViewController
            roomVC.isRoomCreater = false
            
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(roomVC, animated: true)
            }
        }
    }
}


// MARK: - UITableViewDataSource
extension GLRoomListViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GLRoomInfoCellIdentifier, for: indexPath) as! GLRoomInfoCell
        cell.roomNumerLbl.text = "Room-00" + "\(indexPath.row)"
        cell.roomCreaterLbl.text = dataSource[indexPath.row]
        return cell
    }
}


// MARK: - UITableViewDelegate
extension GLRoomListViewController {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        centralManager?.connect(with: dataSource[indexPath.row])
    }
}















