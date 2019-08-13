//
// MAVRecordViewController.swift
// MagicAVKit
//
// Created by Joyoki on 2019/8/13.
// Copyright © 2019 Joyoki. All rights reserved.
//
// github:https://github.com/Joyoki-J/MagicAV
//


import UIKit
import MagicAV

public class MAVRecordViewController: UIViewController {

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.cyan
        
        let lab = UILabel()
        lab.text = MAVVideoInput().test
        lab.sizeToFit()
        lab.center = view.center
        view.addSubview(lab)
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismiss(animated: true, completion: nil)
    }
}

