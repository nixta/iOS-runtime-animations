//
//  AnimationDemoViewController.swift
//  MapAnimations
//
//  Created by Nicholas Furness on 3/5/18.
//  Copyright © 2018 Nicholas Furness. All rights reserved.
//

import UIKit

class AnimationDemoViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AnimationManager.reset()
    }
    override func viewWillDisappear(_ animated: Bool) {
        AnimationManager.forceStopAnimations()
        super.viewWillDisappear(animated)
    }
}
