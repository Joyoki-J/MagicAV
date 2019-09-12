//
// MAVDevice.swift
// MagicAV
//
// Created by Joyoki on 2019/8/13.
// Copyright © 2019 Joyoki. All rights reserved.
//
// github:https://github.com/Joyoki-J/MagicAV
//


import AVFoundation

@available(iOS 10.0, *)
fileprivate func MAVGetDevice(with deviceTypes:[AVCaptureDevice.DeviceType], mediaType: AVMediaType, position: AVCaptureDevice.Position) -> AVCaptureDevice? {
    return AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: mediaType, position: position).devices.findElement{ $0.position == position }
}

fileprivate func MAVGetDevice(with mediaType: AVMediaType, position: AVCaptureDevice.Position) -> AVCaptureDevice? {
    return AVCaptureDevice.devices(for: mediaType).findElement{ $0.position == position }
}

protocol MAVDevice: NSObject {
    
    var rawDevice: AVCaptureDevice? { get }
    
}

class MAVVideoDevice: NSObject, MAVDevice {
    
    private(set) var rawDevice: AVCaptureDevice?
    
    @available(iOS 10.0, *)
    lazy private var deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera]
    
    init(position: AVCaptureDevice.Position) {
        super.init()
        if #available(iOS 10.0, *) {
            if #available(iOS 10.2, *) {
                self.deviceTypes.insert(.builtInDualCamera, at: 0)
            }
            self.rawDevice = MAVGetDevice(with: self.deviceTypes, mediaType: .video, position: position)
        } else {
            self.rawDevice = MAVGetDevice(with: .video, position: position)
        }
    }
    
    var position: AVCaptureDevice.Position {
        return self.rawDevice?.position ?? .unspecified
    }
    
    @discardableResult
    func switchPosition() -> Bool {
        let position = self.position == .back ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back
        if #available(iOS 10.0, *) {
            self.rawDevice = MAVGetDevice(with: self.deviceTypes, mediaType: .video, position: position)
        } else {
            self.rawDevice = MAVGetDevice(with: .video, position: position)
        }
        return self.rawDevice != nil ? true : false
    }
}

class MAVAudioDevice: NSObject, MAVDevice {
    
    private(set) var rawDevice: AVCaptureDevice?
    
    override init() {
        if #available(iOS 10.0, *) {
            self.rawDevice = MAVGetDevice(with: [.builtInMicrophone], mediaType: .audio, position: .unspecified)
        } else {
            self.rawDevice = MAVGetDevice(with: .audio, position: .unspecified)
        }
    }
}
