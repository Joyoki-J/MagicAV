//
//  MAVQueue.swift
//  MagicAV
//
//  Created by 姜世祺 on 2019/9/9.
//  Copyright © 2019 Joyoki. All rights reserved.
//

import UIKit

final class MAVQueue: NSObject {
    
    
    typealias Identifier = String
    
    private let queueKey = DispatchSpecificKey<Int>()
    private let queueValue: Int
    
    private let identifier: Identifier
    
    private(set) var rawQueue: DispatchQueue
    
    init(identifier: MAVQueue.Identifier) {
        self.identifier = identifier
        self.rawQueue = DispatchQueue(label: identifier)
        self.queueValue = identifier.hash
        super.init()
        self.rawQueue.setSpecific(key: self.queueKey, value: self.queueValue)
    }
    
    var isCurrentQueue: Bool {
        guard let queueValue = self.rawQueue.getSpecific(key: self.queueKey) else {
            return false
        }
        return queueValue == self.queueValue
    }
    
    deinit {
        self.rawQueue.setSpecific(key: self.queueKey, value: nil)
        MAVPrint("deinit \(self.identifier)")
    }
    
}

private extension MAVQueue.Identifier {
    static let SessionQueue = "com.MagicAV.Queue.Session"
    static let VideoQueue   = "com.MagicAV.Queue.Video"
    static let AudioQueue   = "com.MagicAV.Queue.Audio"
}

extension MAVQueue {

    static var SessionQueue: MAVQueue = {
        let sessionQueue = MAVQueue(identifier: .SessionQueue)
        return sessionQueue
    }()
    
    static var VideoQueue: MAVQueue = {
        let videoQueue = MAVQueue(identifier: .VideoQueue)
        return videoQueue
    }()
    
    static var AudioQueue: MAVQueue = {
        let audioQueue = MAVQueue(identifier: .AudioQueue)
        return audioQueue
    }()
    
}


typealias MAVQueueBlock = () -> Void

extension MAVQueue {
    static func runAsynchronously(on queue: MAVQueue, execute work: @escaping MAVQueueBlock) {
        queue.isCurrentQueue ? work() : DispatchQueue.main.async { work() }
    }
    
    static func runSynchronously(on queue: MAVQueue, execute work: @escaping MAVQueueBlock) {
        queue.isCurrentQueue ? work() : DispatchQueue.main.sync { work() }
    }
    
    static func runAsynchronouslyOnSessionQueue(execute work: @escaping MAVQueueBlock) {
        runAsynchronously(on: .SessionQueue, execute: work)
    }
    
    static func runSynchronouslyOnSessionQueue(execute work: @escaping MAVQueueBlock) {
        runSynchronously(on: .SessionQueue, execute: work)
    }
    
    static func runAsynchronouslyOnVideoQueue(execute work: @escaping MAVQueueBlock) {
        runAsynchronously(on: .VideoQueue, execute: work)
    }
    
    static func runSynchronouslyOnVideoQueue(execute work: @escaping MAVQueueBlock) {
        runSynchronously(on: .VideoQueue, execute: work)
    }
    
    static func runAsynchronouslyOnAudioQueue(execute work: @escaping MAVQueueBlock) {
        runAsynchronously(on: .AudioQueue, execute: work)
    }
    
    static func runSynchronouslyOnAudioQueue(execute work: @escaping MAVQueueBlock) {
        runSynchronously(on: .AudioQueue, execute: work)
    }
    
    static func runAsynchronouslyOnMainQueue(execute work: @escaping MAVQueueBlock) {
        Thread.isMainThread ? work() : DispatchQueue.main.async { work() }
    }
    
    static func runSynchronouslyOnMainQueue(execute work: @escaping MAVQueueBlock) {
        Thread.isMainThread ? work() : DispatchQueue.main.sync { work() }
    }
}
