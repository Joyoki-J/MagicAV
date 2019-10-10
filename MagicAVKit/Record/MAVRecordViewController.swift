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
        
        let button = UIButton()
        button.setTitle("滤镜", for: .normal)
        button.sizeToFit()
        button.addTarget(self, action: #selector(onClickAction(btn:)), for: .touchUpInside)
        button.center = view.center
        view.addSubview(button)
        
        let sipder = UISlider(frame: CGRect(x: 0, y: 0, width: 375, height: 40))
        sipder.maximumValue = 1.0
        sipder.minimumValue = 0.0
        sipder.setValue(0.5, animated: false)
        sipder.addTarget(self, action: #selector(aaaa), for: .valueChanged)
        sipder.center = CGPoint(x: view.center.x, y: view.center.y + 200)
        view.addSubview(sipder)
    }
    
    @objc public func aaaa(sip: UISlider) {
        self.recorder?.setLUTIntensity(sip.value)
    }
    
    var test: Int = 0
    @objc private func onClickAction(btn: UIButton) {
        if test % 3 == 0 {
            self.recorder?.setLUTImage(UIImage(named: "huaijiu"))
            btn.setTitle("滤镜-激情", for: .normal)
        } else if test % 3 == 1 {
            self.recorder?.setLUTImage(UIImage(named: "qingliang"))
            btn.setTitle("滤镜-理性派", for: .normal)
        } else {
            self.recorder?.setLUTImage(nil)
            btn.setTitle("滤镜", for: .normal)
        }
        btn.sizeToFit()
        btn.center = view.center
        test += 1
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

