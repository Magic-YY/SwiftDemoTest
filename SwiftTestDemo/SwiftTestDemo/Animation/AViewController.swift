//
//  AViewController.swift
//  SwiftTestDemo
//
//  Created by 杨运 on 2024/8/14.
//

import UIKit

class AViewController: UIViewController {
    
    let transitionAnimator = PresentViewControllerAnimation()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .red
        self.title = "A"
        
        view.addSubview(topView)
        view.addSubview(contentView)
        view.addSubview(bottomView)
        
        let topHeight: CGFloat = 84
        let bottomHeight: CGFloat = 56
        let contentHeight: CGFloat = view.bounds.height - topHeight - bottomHeight
        let width: CGFloat = view.bounds.width
        
        topView.frame = CGRect(x: 0, y: 0, width: width, height: topHeight)
        contentView.frame = CGRect(x: 0, y: topView.frame.maxY, width: width, height: contentHeight)
        bottomView.frame = CGRect(x: 0, y: contentView.frame.maxY, width: width, height: bottomHeight)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let bController = BViewController()
        bController.modalPresentationStyle = .fullScreen;
//        bController.transitioningDelegate = self
        self.present(bController, animated: true)
    }
    

    private lazy var topView: UIView = {
        let view = UIView()
        view.backgroundColor = .red
        return view
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .yellow
        return view
    }()

    private lazy var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = .blue
        return view
    }()
}

extension AViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionAnimator
    }
}
