//
//  AsynchronousOperation.swift
//  SwiftTestDemo
//
//  Created by 杨运 on 2024/5/30.
//

import Foundation
import UIKit

extension AsyncOperation {
    enum State: String {
        case ready, executing, finished
        fileprivate var keyPath: String {
            return "is\(rawValue.capitalized)"
        }
    }
}

class AsyncOperation: Operation {
    var state = State.ready {
        willSet {
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: state.keyPath)
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: state.keyPath)
        }
    }
    
    override var isReady: Bool {
        return super.isReady && state == .ready
    }
    
    override var isExecuting: Bool {
        return state == .executing
    }
    
    override var isFinished: Bool {
        return state == .finished
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override func start() {
        if isCancelled {
            state = .finished
            return
        }
        main()
        state = .executing
    }
}

// MARK: - 测试
protocol IntDataProvider {
  var intValue: Int? { get }
}

class testOperation1: AsyncOperation {
    
    var intValue: Int?
    
    init(intValue: Int? = nil) {
        self.intValue = intValue
    }
    
    override func main() {
        print("testOperation1处理开始")
        Thread.sleep(until: Date().addingTimeInterval(4))
        print("testOperation1处理完成")
        state = .finished
//        intValue = 9
    }
}

extension testOperation1: IntDataProvider { }

class testOperation2: AsyncOperation {
    
    private let value: Int
    init(intValue: Int) {
        self.value = intValue
    }
    
    override func main() {
        print("testOperation2处理开始")
        Thread.sleep(until: Date().addingTimeInterval(4))
        
        // 通过协议进行依赖项传值
//        let dependencyInt = dependencies.compactMap { ($0 as? IntDataProvider)?.intValue }.first ?? intValue
        
        let dependencyInt = self.value
        print("testOperation2处理完成, value-=\(dependencyInt)")
        state = .finished
    }
}

extension testOperation2: IntDataProvider {
    var intValue: Int? { 999 }
}
