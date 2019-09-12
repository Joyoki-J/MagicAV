//
//  Array+MAV.swift
//  MagicAV
//
//  Created by 姜世祺 on 2019/9/10.
//  Copyright © 2019 Joyoki. All rights reserved.
//

import Foundation

extension Array {
    func findElement(with closure: (Element)->Bool) -> Element? {
        var iterator = self.enumerated().makeIterator()
        while let sequence = iterator.next() {
            if closure(sequence.element) {
                return sequence.element
            }
        }
        return nil
    }
}
