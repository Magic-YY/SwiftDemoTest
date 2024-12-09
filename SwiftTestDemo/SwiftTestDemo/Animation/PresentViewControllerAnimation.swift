//
//  PresentViewControllerAnimation.swift
//  SwiftTestDemo
//
//  Created by 杨运 on 2024/8/14.
//

import UIKit

class PresentViewControllerAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        return 5
    }
    
    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as? AViewController,
              let toVC = transitionContext.viewController(forKey: .to) as? BViewController else {
            return
        }
    }
}
