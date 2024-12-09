//
//  ViewController.swift
//  SwiftTestDemo
//
//  Created by 杨运 on 2024/4/28.
//

import UIKit

struct TestModel {
    var value1: String = ""
    var value2: String = ""
}


class ViewController: UIViewController {
    
    var taskGroup: TaskGroup<TestModel?>? // 声明一个变量来存储任务组
    
    var cancle: Bool = false
    
    var images: [String] = ["img1", "img2", "img3", "img4"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .gray
        print("test")
        
//        gcdTestAction()
//        operationAction()
//        configCycleView()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let aController = AViewController()
        self.navigationController?.pushViewController(aController, animated: true)
    }

    // MARK: - getter
    private(set) lazy var cycleScrollView: CECycleScrollView = {
        let view = CECycleScrollView(frame: CGRect(x: 50, y: 200, width: 200, height: 300), numberOfItems: images.count, cellClass: CycleCollectionViewCell.self, delegate: self, autoScroll: false)
        view.backgroundColor = .yellow
        return view
    }()
}

// MARK: - AsyncStream
extension ViewController {
    
}
