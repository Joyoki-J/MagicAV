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
        
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        btn.setTitle("开始", for: .normal)
        btn.setTitleColor(UIColor.blue, for: .normal)
        btn.layer.borderColor = UIColor.blue.cgColor
        btn.layer.borderWidth = 1.0 / UIScreen.main.scale
        btn.center = CGPoint(x: view.center.x, y: view.center.y - 200)
        btn.addTarget(self, action: #selector(onClickAction(sender:)), for: .touchUpInside)
        view.addSubview(btn)
    }
    
    @objc
    func onClickAction(sender: UIButton) {
        let vc = MAVRecordViewController()
        self.present(vc, animated: true, completion: nil)
    }

}

