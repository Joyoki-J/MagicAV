//
// ViewController.swift
// MagicAVDemo
//
// Created by Joyoki on 2019/8/13.
// Copyright © 2019 Joyoki. All rights reserved.
//
// github:https://github.com/Joyoki-J/MagicAV
//

import UIKit
import MagicAVKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let vc = MAVRecordViewController()
        self.present(vc, animated: true, completion: nil)
    }

}

