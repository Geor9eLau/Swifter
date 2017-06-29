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
    
    
    @IBOutlet weak var tableView: UITableView!
    let centralManager = GLCentralManager.default
    
    fileprivate var dataSource: [String] = []
    fileprivate var isConnectedToRoomCreater: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager.startScan()
        
        NotificationCenter.default.addObserver(forName: NotificationCentralDidDiscoverPeripheral, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            if let info = notification.userInfo,
                let roomCreaterName = info[NotificationCentralDidDiscoverPeripheralKey] as? String{
                self?.dataSource.append(roomCreaterName)
                self?.tableView.reloadData()
            }
        }
        
        
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NotificationCentralDidDiscoverPeripheral, object: nil)
    }
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return isConnectedToRoomCreater
    }
}


//MARK: - Life Cycle
extension GLRoomCreaterViewController {
    
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
        if isConnectedToRoomCreater == false {
            centralManager.connect(with: dataSource[indexPath.row])
        }
    }
}















