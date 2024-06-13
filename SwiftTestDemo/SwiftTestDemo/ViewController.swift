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
        
        print("test")
        
//        gcdTestAction()
        
//        operationAction()
        
        configCycleView()
    }

    // MARK: - getter
    private lazy var cycleScrollView: CECycleScrollView = {
        let view = CECycleScrollView(frame: CGRect(x: 50, y: 200, width: 200, height: 300), numberOfItems: images.count, cellClass: CycleCollectionViewCell.self, delegate: self, autoScroll: false)
        return view
    }()
}

// MARK: - 轮播
extension ViewController: CECycleScrollViewDelegate {
    func cycleScrollView(_ collectionView: UICollectionView, indexPath: IndexPath, reuseIdentifier: String, pageIndex: Int) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? CycleCollectionViewCell else { return UICollectionViewCell() }
        cell.imageName = images[pageIndex]
        return cell
    }
    
    func cycleScrollView(cycleScrollView: CECycleScrollView, didSelectItem atIndex: Int) {
        print("didSelectItem =\(atIndex)")
    }
    
    func cycleScrollView(cycleScrollView: CECycleScrollView, didScrollToIndex index: Int) {
        print("didScrollToIndex =\(index)")
    }
    
    func configCycleView() {
        view.addSubview(cycleScrollView)
    }
}

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
