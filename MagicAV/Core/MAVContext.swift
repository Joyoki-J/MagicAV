//
//  MAVContext.swift
//  MagicAV
//
//  Created by 姜世祺 on 2019/9/18.
//  Copyright © 2019 Joyoki. All rights reserved.
//

import Foundation
import Metal

class MAVContext {
    static let shared: MAVContext = MAVContext()
    
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    
    init() {
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = self.device.makeCommandQueue()!
    }
}
