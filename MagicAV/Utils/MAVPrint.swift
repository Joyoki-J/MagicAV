//
//  MAVPrint.swift
//  MagicAV
//
//  Created by 姜世祺 on 2019/9/9.
//  Copyright © 2019 Joyoki. All rights reserved.
//

import Foundation

func MAVPrint(_ content: String) {
    #if DEBUG
    print("MagicAV: " + content)
    #endif
}

