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
        
        guard let defaultLibrary = try? MAVContext.shared.device.makeLibrary(filepath: Bundle.main.privateFrameworksPath! + "/MagicAV.framework/default.metallib"),
              let kernelFunction = defaultLibrary.makeFunction(name: "rosyEffect"),
              let computePipelineState = try? MAVContext.shared.device.makeComputePipelineState(function: kernelFunction) else {
            MAVPrint("MAVLUTFilter computePipelineState error")
            return
        }
        self.computePipelineState = computePipelineState
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
            let dataSize = width * height * 4
            let data = UnsafeMutablePointer<UInt8>.allocate(capacity: dataSize)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            guard let context = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 4 * width, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                    return nil
            }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
       
            let texDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
            let texture = MAVContext.shared.device.makeTexture(descriptor: texDesc)
            texture?.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: context.data!, bytesPerRow: 4 * width)
            free(data)
            return texture
        }
        return nil
    }
    
    override func render(_ texture: MTLTexture, size: MTLSize) -> MTLTexture {
        
        guard let lutTexture = self.lutTexture,
              let commandBuffer = MAVContext.shared.commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
                return texture
        }
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: size.width, height: size.height, mipmapped: false)
      
        guard let outTexture = MAVContext.shared.device.makeTexture(descriptor: descriptor) else {
            return texture
        }
        
        commandEncoder.label = "Metal LUT Filter"
        commandEncoder.setComputePipelineState(computePipelineState!)
        commandEncoder.setTexture(lutTexture, index: 0)
        commandEncoder.setTexture(texture, index: 1)
        commandEncoder.setTexture(outTexture, index: 2)
        
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
        return outTexture
    }
}

