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

    private var recorder: MAVRecorder?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.cyan
        
        self.recorder = MAVRecorder(preView: view)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.recorder?.startCamera()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.recorder?.stopCamera()
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismiss(animated: true, completion: nil)
    }
}

