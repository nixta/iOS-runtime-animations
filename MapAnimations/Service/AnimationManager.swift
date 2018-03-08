//
//  AnimationManager.swift
//  MapAnimations
//
//  Created by Nicholas Furness on 3/5/18.
//  Copyright © 2018 Nicholas Furness. All rights reserved.
//

import Foundation

private let _fps = 60.0

private class AnimationBlock:Hashable, Equatable {
    let key:UUID = UUID()
    private let block:()->Bool!
    private var completion:(()->Void)? = nil
    fileprivate var completed = false

    init(block: @escaping ()->Bool, completion:(()->Void)?) {
        self.block = block
        self.completion = completion
    }

    fileprivate func executeAsync() {
        DispatchQueue.main.async { [weak self] in
            guard let thisAnimBlock = self else {
                return
            }

            guard !thisAnimBlock.completed else {
                print("------- Trying to run completed animation block")
                return
            }

            if thisAnimBlock.block() {
                thisAnimBlock.completed = true
                AnimationManager.stopAnimating(animationBlock: thisAnimBlock)
                thisAnimBlock.completion?()
            }
        }
    }

    var hashValue: Int {
        return key.hashValue
    }

    static func ==(lhs:AnimationBlock, rhs:AnimationBlock) -> Bool {
        return lhs.key == rhs.key
    }
}

class AnimationManager {
    private enum AnimationState {
        case unstarted
        case animating
        case paused
        case forceStopped
    }

    private static var timer:Timer?

    private static var animationBlocks:Set<AnimationBlock> = Set()

    private static var state:AnimationState = .unstarted {
        didSet {
            switch state {
            case .unstarted, .forceStopped:
                for block in animationBlocks {
                    AnimationManager.stopAnimating(animationBlock: block)
                }
                animationBlocks.removeAll()
                fallthrough
            case .paused:
                timer?.invalidate()
                timer = nil
            default:
                break;
            }
        }
    }

    static func animate(animationBlock block:@escaping ()->Bool, completion completionHandler:(()->Void)?) {
        let animationBlock = AnimationBlock(block: block, completion: completionHandler)
        AnimationManager.animationBlocks.insert(animationBlock)
        if AnimationManager.timer == nil {
            AnimationManager.timer = getNewTimer()
        }
    }

    static func pauseAnimations() {
        AnimationManager.state = .paused
    }

    static func forceStopAnimations() {
        AnimationManager.state = .forceStopped
    }

    static func reset() {
        AnimationManager.state = .unstarted
    }

    static func resumeAnimations() {
        AnimationManager.timer = getNewTimer()
    }

    static var isPaused:Bool {
        return AnimationManager.state == .paused
    }

    private static func getNewTimer() -> Timer? {
        guard AnimationManager.state != .forceStopped else {
            return nil
        }

        AnimationManager.state = .animating
        return Timer.scheduledTimer(withTimeInterval: 1/_fps, repeats: true, block: { (theTimer) in
            for block in AnimationManager.animationBlocks {
                block.executeAsync()
            }
        })
    }

    fileprivate static func stopAnimating(animationBlock block:AnimationBlock) {
        block.completed = true
        AnimationManager.animationBlocks.remove(block)
        if AnimationManager.animationBlocks.count == 0 {
            print("Nothing to animate - destroying timer")
            AnimationManager.timer?.invalidate()
            AnimationManager.timer = nil
        }
    }
}
