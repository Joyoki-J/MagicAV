//
//  MAVBuffer.swift
//  MagicAV
//
//  Created by 姜世祺 on 2019/9/17.
//  Copyright © 2019 Joyoki. All rights reserved.
//

import Foundation
import Metal

struct MAVBuffer {
    
    var texture: MTLTexture
    var size: MTLSize
    
    init(texture: MTLTexture, size: MTLSize) {
        self.texture = texture
        self.size = size
    }
}
