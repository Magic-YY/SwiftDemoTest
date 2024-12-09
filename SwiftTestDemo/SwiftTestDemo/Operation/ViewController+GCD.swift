//
//  ViewController+GCD.swift
//  SwiftTestDemo
//
//  Created by 杨运 on 2024/12/9.
//

import Foundation

// MARK: - GCD任务测试
extension ViewController {
    func gcdTestAction() {
        let queue = DispatchQueue(label: "xyz")
        let backgroundWorkItem = DispatchWorkItem {
            self.backAction { text in
                print(text)
            }
            print("backgroundWorkItem")
        }
        let updateUIWorkItem = DispatchWorkItem {
            print("updateUIWorkItem")
        }
        backgroundWorkItem.notify(queue: DispatchQueue.main,
                                  execute: updateUIWorkItem)
        queue.async(execute: backgroundWorkItem)
    }
    
    func backAction(completion: ((String) -> Void)?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            completion?("backAction")
        }
    }
}
