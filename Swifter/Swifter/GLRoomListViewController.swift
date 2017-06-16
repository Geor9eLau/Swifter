//
//  GLRoomListViewController.swift
//  Swifter
//
//  Created by George on 2017/6/16.
//  Copyright © 2017年 George. All rights reserved.
//

import Foundation
import UIKit

class GLRoomListViewController: GLBaseViewController, UITableViewDelegate, UITableViewDataSource {
    
}


extension GLRoomListViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GLRoomInfoCellIdentifier, for: indexPath) as! GLRoomInfoCell
        cell.roomNumerLbl.text = "Room-001"
        cell.roomCreaterLbl.text = "George"
        return cell
    }
}

extension GLRoomListViewController {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
