//
//  GLRoomInfoCell.swift
//  Swifter
//
//  Created by George on 2017/6/16.
//  Copyright © 2017年 George. All rights reserved.
//

import Foundation
import UIKit


public let GLRoomInfoCellIdentifier = "GLRoomInfoCell"
class GLRoomInfoCell: UITableViewCell {
    
    @IBOutlet weak var roomNumerLbl: UILabel!
    @IBOutlet weak var roomCreaterLbl: UILabel!
    
    override func awakeFromNib() {
        contentView.backgroundColor = UIColor.randomFlat()
    }
}
