//
//  GLPlayerInfoCell.swift
//  Swifter
//
//  Created by George on 2017/6/16.
//  Copyright © 2017年 George. All rights reserved.
//

import Foundation
import UIKit

public let PlayerInfoCellIdentifier = "GLPlayerInfoCell"
class GLPlayerInfoCell: UICollectionViewCell {
    
    @IBOutlet weak var avatar: UIImageView!
    
    @IBOutlet weak var nameLbl: UILabel!
    
    
    override func awakeFromNib() {
        avatar.backgroundColor = UIColor.init(randomFlatColorOf: .dark)
    }
}
