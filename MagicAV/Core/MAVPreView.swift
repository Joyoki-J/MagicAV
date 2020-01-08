//
//  MAVPreView.swift
//  MagicAV
//
//  Created by 姜世祺 on 2019/9/10.
//  Copyright © 2019 Joyoki. All rights reserved.
//

import Metal
import MetalKit
import simd

class MAVPreView: UIView, MAVPipeline {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupMetal()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupMetal()
    }
    
    lazy var metalView: MTKView! = MTKView(frame: self.bounds)

    var device: MTLDevice!
    var vertexCoordBuffer: MTLBuffer!
    var textCoordBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!
    var sampler: MTLSamplerState!
    var commandQueue: MTLCommandQueue!
    var texture: MTLTexture?
    var numVertices: Int = 0
    
    func setupMetal() {
        guard self.setupDevice() else { return }

        self.metalView.device = self.device
        self.metalView.delegate = self
        self.metalView.isPaused = true
        self.metalView.enableSetNeedsDisplay = false
        self.metalView.colorPixelFormat = .bgra8Unorm
        self.metalView.drawableSize = CGSize(width: 1125, height: 2436)
        self.addSubview(self.metalView)
    }
    
    func setupDevice() -> Bool {
        
        self.device = MAVContext.shared.device
        guard self.device != nil else { return false }
        
        self.commandQueue = MAVContext.shared.commandQueue
        
        let vertexCoordData: [Float] = [
             1.0, -0.806, 0.0, 1.0,
            -1.0, -0.806, 0.0, 1.0,
            -1.0,  0.806, 0.0, 1.0,
            
             1.0, -0.806, 0.0, 1.0,
            -1.0,  0.806, 0.0, 1.0,
             1.0,  0.806, 0.0, 1.0
        ]
    
        self.vertexCoordBuffer = self.device.makeBuffer(bytes: vertexCoordData, length: vertexCoordData.count * MemoryLayout<Float>.size, options: [])
        self.numVertices = vertexCoordData.count
        
        let textCoordData: [Float] = [
            1.0, 1.0,
            0.0, 1.0,
            0.0, 0.0,
            
            1.0, 1.0,
            0.0, 0.0,
            1.0, 0.0
        ]
        self.textCoordBuffer = self.device.makeBuffer(bytes: textCoordData, length: textCoordData.count * MemoryLayout<Float>.size, options: [])
        
        guard let defaultLibrary = try? self.device.makeLibrary(filepath: Bundle.main.privateFrameworksPath! + "/MagicAV.framework/default.metallib") else { return false }
        let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibrary.makeFunction(name: "samplingShader")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        guard let pipelineState = try? self.device.makeRenderPipelineState(descriptor: pipelineStateDescriptor) else { return false }
        self.pipelineState = pipelineState
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        guard let sampler = self.device.makeSamplerState(descriptor: samplerDescriptor) else { return false }
        self.sampler = sampler
        
        return true
    }
    
    var nextPipe: MAVPipeline?
    
}

extension MAVPreView: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {

        defer { self.texture = nil }
        
        guard let texture = self.texture,
            let drawable = view.currentDrawable,
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let commandBuffer = self.commandQueue.makeCommandBuffer() else { return }
        
        commandBuffer.label = "MyCommand"
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        renderEncoder.label = "MyRenderEncoder"
        renderEncoder.setRenderPipelineState(self.pipelineState)
        renderEncoder.setVertexBuffer(self.vertexCoordBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(self.textCoordBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.setFragmentSamplerState(self.sampler, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: self.numVertices)
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        
        commandBuffer.commit()
        
    }
}

extension MAVPreView: MAVRenderExecutable {
    
    func render(_ texture: MTLTexture, size: MTLSize) -> MTLTexture {
        self.texture = texture
        self.metalView.draw()
        return texture
    }
    
}
