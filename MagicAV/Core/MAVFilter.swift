//
//  MAVFilter.swift
//  MagicAV
//
//  Created by 姜世祺 on 2019/9/16.
//  Copyright © 2019 Joyoki. All rights reserved.
//

import Foundation
import Metal

public protocol MAVRenderExecutable {
    
    func render(_ texture: MTLTexture, size: MTLSize) -> MTLTexture
    
}

public protocol MAVPipeline: class {
    
    var nextPipe: MAVPipeline? { get set }
    
    func pipeline(_ texture: MTLTexture, size: MTLSize)
    
}

extension MAVPipeline where Self: MAVRenderExecutable {
    func pipeline(_ texture: MTLTexture, size: MTLSize) {
        let newTexture = self.render(texture, size: size)
        if let nextPipe = self.nextPipe {
            nextPipe.pipeline(newTexture, size: size)
        }
    }
}

class MAVFilter: MAVPipeline,MAVRenderExecutable {
    
    var nextPipe: MAVPipeline?
    
    func render(_ texture: MTLTexture, size: MTLSize) -> MTLTexture {
        return texture
    }
}


infix operator >>> : AdditionPrecedence

@discardableResult
func >>><L: MAVPipeline, R: MAVPipeline>(left: L, right: R) -> R {
    left.nextPipe = right
    return right
}
