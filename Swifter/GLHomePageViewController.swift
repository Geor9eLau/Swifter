//
//  GLHomePageViewController.swift
//  Swifter
//
//  Created by George on 2017/6/16.
//  Copyright © 2017年 George. All rights reserved.
//

import Foundation
import UIKit

class GLHomePageViewController: UIViewController {
    let createRoomSegueIdentifier = "CreateRoom"
    let joinGameSegueIdentifier = "JoinGame"
    
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }
    
    override func performSegue(withIdentifier identifier: String, sender: Any?) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == createRoomSegueIdentifier {
            if let createRoomVc = segue.destination as? GLRoomCreaterViewController {
                createRoomVc.isRoomCreater = true
            }
        }
    }
    
    
    
}


// MARK: - Life cycle
extension GLHomePageViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}
