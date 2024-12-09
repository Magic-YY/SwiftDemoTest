//
//  BViewController.swift
//  SwiftTestDemo
//
//  Created by 杨运 on 2024/8/14.
//

import UIKit

class BViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .gray
        self.title = "B"
        
        view.addSubview(contentView)
        view.addSubview(bottomView)
        
        let topHeight: CGFloat = 84
        let bottomHeight: CGFloat = 56
        let contentHeight: CGFloat = view.bounds.height - topHeight - bottomHeight
        let width: CGFloat = view.bounds.width
        
        contentView.frame = CGRect(x: 0, y: topHeight, width: width, height: contentHeight)
        bottomView.frame = CGRect(x: 0, y: contentView.frame.maxY, width: width, height: bottomHeight)
    }
    
//    func <#name#>(<#parameters#>) -> <#return type#> {
//        <#function body#>
//    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismiss(animated: true)
    }
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .yellow
        return view
    }()

    private lazy var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = .red
        return view
    }()
}
