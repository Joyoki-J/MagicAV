//
//  MAVLUTFilter.swift
//  MagicAV
//
//  Created by 姜世祺 on 2019/9/18.
//  Copyright © 2019 Joyoki. All rights reserved.
//

import Foundation
import Metal
import MetalKit
import UIKit

class MAVLUTFilter: MAVFilter {
    
    private var computePipelineState: MTLComputePipelineState?
    
    override init() {
        super.init()
        
        let defaultLibrary = MAVContext.shared.device.makeDefaultLibrary()!
        let kernelFunction = defaultLibrary.makeFunction(name: "rosyEffect")
        
        do {
            self.computePipelineState = try MAVContext.shared.device.makeComputePipelineState(function: kernelFunction!)
        } catch {
            MAVPrint("MAVLUTFilter computePipelineState error")
        }
    }
    
    var lutImage: UIImage? {
        didSet {
            self.lutTexture = self.createLUTTexture()
        }
    }
    private var lutTexture: MTLTexture?
    
    private func createLUTTexture() -> MTLTexture? {
        if let lutImage = self.lutImage,
           let cgImage = lutImage.cgImage {
            
            let width = cgImage.width
            let height = cgImage.height
            
            let bitsPerComponent = cgImage.bitsPerComponent
            let bitsPerPixel = cgImage.bitsPerPixel
            
            let colorSpace = cgImage.colorSpace!
            let alphaInfo = cgImage.alphaInfo
            
            guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bitsPerPixel / 8, space: colorSpace, bitmapInfo: alphaInfo.rawValue),
                  let imageData = context.data else {
                return nil
            }
            
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            
            let texDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
            let texture = MAVContext.shared.device.makeTexture(descriptor: texDesc)
            texture?.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: imageData, bytesPerRow: 4 * width)
            return texture
        }
        return nil
    }
    
    override func render(_ texture: MTLTexture, size: MTLSize) -> MTLTexture {
        
        guard let lutTexture = self.lutTexture,
              let commandBuffer = MAVContext.shared.commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
                MAVPrint("Failed to create a Metal command queue.")
                return texture
        }
        
        commandEncoder.label = "Metal LUT Filter"
        commandEncoder.setComputePipelineState(computePipelineState!)
        commandEncoder.setTexture(texture, index: 0)
        commandEncoder.setTexture(lutTexture, index: 1)
        
        // Set up the thread groups.
        let width = computePipelineState!.threadExecutionWidth
        let height = computePipelineState!.maxTotalThreadsPerThreadgroup / width
        let threadsPerThreadgroup = MTLSizeMake(width, height, 1)
        let threadgroupsPerGrid = MTLSize(width: (texture.width + width - 1) / width,
                                          height: (texture.height + height - 1) / height,
                                          depth: 1)
        commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        commandEncoder.endEncoding()
        commandBuffer.commit()
        return texture
    }
}

