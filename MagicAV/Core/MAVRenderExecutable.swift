//
//  MAVRenderExecutable.swift
//  MagicAV
//
//  Created by 姜世祺 on 2019/9/11.
//  Copyright © 2019 Joyoki. All rights reserved.
//

import CoreVideo

public protocol MAVRenderExecutable {
    func render(_ pixelBuffer: CVPixelBuffer)
}
