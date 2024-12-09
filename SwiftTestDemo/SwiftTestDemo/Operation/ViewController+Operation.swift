//
//  ViewController+Operation.swift
//  SwiftTestDemo
//
//  Created by 杨运 on 2024/12/9.
//

import Foundation

// MARK: - Operation测试
extension ViewController {
    func operationAction() {
        let opQueue = OperationQueue()
        opQueue.maxConcurrentOperationCount = 2
        // 依赖传值
        let op1 = testOperation1(intValue: 999999)
        let op2 = testOperation2(intValue: op1.intValue ?? -9999)
        op2.addDependency(op1)
        
        opQueue.addOperation(op1)
        opQueue.addOperation(op2)
    }
}
