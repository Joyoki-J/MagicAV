//
//  MAVRecorder.swift
//  MagicAV
//
//  Created by 姜世祺 on 2019/9/10.
//  Copyright © 2019 Joyoki. All rights reserved.
//

import UIKit
import MetalKit
import AVFoundation
import CoreFoundation

private let kVideoProcessingQueueIdentifier = "com.MagicAV.Queue.VideoProcessing"

public class MAVRecorder: NSObject {
    
    private var preView: MAVPreView!
    private var videoProcessingQueue: MAVQueue!
    private var videoDevice: MAVVideoDevice!
    
    private var captureSession: AVCaptureSession!
    private var videoInput: AVCaptureDeviceInput!
    private var videoOutput: AVCaptureVideoDataOutput!
    let semaphore: DispatchSemaphore = DispatchSemaphore(value: 3)
    
    var textureCachePool: [CVMetalTextureCache] = []
    var textureCaches: [CVMetalTextureCache] = []
    
    var pipeline: MAVPipeline?
    
    public init?(preView: UIView) {
        super.init()
        
        guard self.createTextureCache(3) else { return nil }
        
        self.preView = MAVPreView(frame: preView.bounds)
        preView.addSubview(self.preView)
        self.pipeline = self.createPipeline(with: self.preView)
        
        self.videoDevice = MAVVideoDevice(position: .back)
        guard self.videoDevice.rawDevice != nil else {
            return nil
        }
        
        self.captureSession = AVCaptureSession()
        self.captureSession.beginConfiguration()
        do {
            self.videoInput = try AVCaptureDeviceInput(device: self.videoDevice.rawDevice!)
        } catch {
            return nil
        }
        
        guard self.captureSession.canAddInput(self.videoInput) else {
            return nil
        }
        self.captureSession.addInput(self.videoInput)
        
        self.videoOutput = AVCaptureVideoDataOutput()
        self.videoOutput.alwaysDiscardsLateVideoFrames = false
        
        self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        
        self.videoProcessingQueue = MAVQueue(identifier: kVideoProcessingQueueIdentifier)
        self.videoOutput.setSampleBufferDelegate(self, queue: self.videoProcessingQueue.rawQueue)
        guard self.captureSession.canAddOutput(self.videoOutput) else {
            return nil
        }
        self.captureSession.addOutput(self.videoOutput)
        
        
        
        if let captureConnection = self.videoOutput.connection(with: .video),
            captureConnection.isVideoOrientationSupported {
            captureConnection.videoOrientation = self.getCaptureVideoOrientation()
        }
        self.captureSession.sessionPreset = .hd1920x1080
        
        self.captureSession.commitConfiguration()
    }
    
    func createTextureCache(_ num: Int) -> Bool {
        for _ in 0 ..< num {
            var cvTextureCache: CVMetalTextureCache?
            guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, MAVContext.shared.device, nil, &cvTextureCache) == kCVReturnSuccess, let textureCache = cvTextureCache else {
                return false
            }
            self.textureCachePool.append(textureCache)
        }
        return true
    }
    
    func getTextureCache() -> CVMetalTextureCache? {
        guard self.textureCachePool.count > 0 else { return nil }
        let textureCache = self.textureCachePool.first!
        self.textureCaches.append(textureCache)
        return textureCache
    }
    
    func freeTextureCache(_ textureCache: CVMetalTextureCache) {
        if let index = self.textureCaches.firstIndex(of: textureCache) {
            self.textureCaches.remove(at: index)
        }
        if !self.textureCachePool.contains(textureCache) {
            self.textureCachePool.append(textureCache)
        }
    }
    
    var lutFilter: MAVLUTFilter?
    func createPipeline(with preView: MAVPreView) -> MAVPipeline {
        self.lutFilter = MAVLUTFilter()
        
        self.lutFilter! >>> preView
        
        return self.lutFilter!
    }
    
    deinit {
        self.stopCamera()
        self.videoOutput.setSampleBufferDelegate(nil, queue: DispatchQueue.main)
        self.removeInputsAndOutputs()
        MAVPrint("MAVRecorder deinit")
    }
    
    @available(*, unavailable, message:"请使用init(preView:)方法初始化")
    public override init() {}
    
}

//MARK: - Public
extension MAVRecorder {
    
    @discardableResult
    public func startCamera() -> Bool {
        guard AVCaptureDevice.authorizationStatus(for: AVMediaType.video) != .denied,
              AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) != .denied else {
            return false
        }
        if !self.captureSession.isRunning {
            self.captureSession.startRunning()
        }
        return true
    }
    
    public func stopCamera() {
        if self.captureSession.isRunning {
            self.captureSession.stopRunning()
        }
    }
    
    public func setLUTImage(_ image: UIImage?) {
        self.lutFilter?.lutImage = image
    }
}

//MARK: - Private
extension MAVRecorder {
    func getCaptureVideoOrientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .portrait,.faceUp,.faceDown:
            return .portrait
        case .portraitUpsideDown:
            //如果这里设置成AVCaptureVideoOrientation.portraitUpsideDown，则视频方向和拍摄时的方向是相反的。
            return .portrait
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .portrait
        }
    }
    
    func removeInputsAndOutputs() {
        self.captureSession.beginConfiguration()
        if self.videoInput != nil {
            self.captureSession.removeInput(self.videoInput)
            self.captureSession.removeOutput(self.videoOutput)
            self.videoInput = nil
            self.videoOutput = nil
        }
        self.captureSession.commitConfiguration()
    }
}

extension MAVRecorder: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard self.captureSession.isRunning,
              let pipeline = self.pipeline,
              self.semaphore.wait(timeout: .distantFuture) == .success,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
       
        guard let textureCache = self.getTextureCache() else {
            self.semaphore.signal()
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let w = CVPixelBufferGetWidth(pixelBuffer)
        let h = CVPixelBufferGetHeight(pixelBuffer)
        
        guard let texture = self.loadTexture(using: pixelBuffer, with: textureCache, width: w, height: h) else {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            self.semaphore.signal()
            return
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        MAVQueue.runAsynchronouslyOnVideoQueue { [weak self] in
            pipeline.pipeline(texture, size: MTLSize(width: w, height: h, depth: 1))
            self?.freeTextureCache(textureCache)
            self?.semaphore.signal()
        }
    }
    
    func loadTexture(using pixelBuffer: CVPixelBuffer, with textureCache: CVMetalTextureCache, width: Int, height: Int) -> MTLTexture? {
        var cvTextureOut: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvTextureOut)
        guard let cvTexture = cvTextureOut, let texture = CVMetalTextureGetTexture(cvTexture) else {
            return nil
        }
        return texture
    }
    
}
