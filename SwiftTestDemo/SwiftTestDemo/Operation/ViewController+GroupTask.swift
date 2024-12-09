//
//  ViewController+GroupTask.swift
//  SwiftTestDemo
//
//  Created by 杨运 on 2024/12/9.
//

import Foundation

// MARK: - GroupTask 任务取消测试
extension ViewController {
    
    func groupTastTest() {
        let task = Task {
            let list = await testGroupHandle()
            print("list=\(list.count)")
        }
        
//        let task1 =  Task {
//            do {
//                let list = try await testGroupHandleThrows()
//                print("list=\(list.count)")
//            } catch {
//                print("异常处理： \(error)")
//            }
//        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.cancle = true
            task.cancel()
//            task1.cancel()
        }
    }
    
    // 无异常取消处理
    func testGroupHandle() async -> [TestModel] {
        print("开始处理")
        let models = await withTaskGroup(of: TestModel?.self, returning: [TestModel].self) { group in
            for index in 0...10 {
                group.addTask {
                    await self.handleTest1(delay: TimeInterval(index))
//                    await self.handleTest2(delay: TimeInterval(index))
                }
            }

            var resultArray: [TestModel] = []
            for await pageModel in group {
                if Task.isCancelled {
                    print("task 取消")
                    break
                }
                // 解包
                if let model = pageModel {
                    resultArray.append(model)
                }
            }
            
            print("await  任务处理完成")
            return resultArray
        }
        print("处理完成")
        return models
    }
    
    /// task取消异常处理
    func testGroupHandleThrows() async throws -> [TestModel] {
        
        print("开始处理")
        let models = try await withThrowingTaskGroup(of: TestModel?.self, returning: [TestModel].self) { group in
            
            for index in 0...10 {
                group.addTask {
                    try Task.checkCancellation()
                    return await self.handleTest1(delay: TimeInterval(index))
                }
            }
            
            try Task.checkCancellation()
            
            var resultArray: [TestModel] = []
            for try await pageModel in group {
                
                try Task.checkCancellation()
                
                if let model = pageModel {
                    resultArray.append(model)
                }
            }
            return resultArray
        }
        print("处理完成")
        return models
    }
    
    
    func handleTest1(delay: TimeInterval) async -> TestModel? {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if self.cancle {
                    continuation.resume(returning: nil)
                    print("处理 - 取消: \(delay)")
                } else {
                    let model = TestModel()
                    print("处理 - index: \(delay)")
                    continuation.resume(returning: model)
                }
            }
        }
    }
    
    func handleTest2(delay: TimeInterval) async -> TestModel? {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                do {
                    let model = TestModel()
                    print("处理 - index: \(delay)")
                    try Task.checkCancellation()
                    continuation.resume(returning: model)
                } catch {
                    print("处理 - 取消index: \(delay)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
