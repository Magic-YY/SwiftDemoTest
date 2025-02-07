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
        
        streamAction()
        
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
    func streamAction() {
        Task {
            let timer = timerStream
            let t = Task {
                for await v in timer {
                    print("await v \(String(describing: v))")
                }
            }
            try? await Task.sleep(nanoseconds: 5 * NSEC_PER_SEC)
//            t.cancel()
            cancle = true
        }
    }
    
    var timerStream: AsyncStream<Date?> {
//        // Timer驱动
//        AsyncStream<Date> { continuation in
//            let initial = Date()
//            Task {
//                let cusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
//                    let now = Date()
//                    print("Call yield")
//                    continuation.yield(Date())
//                    let diff = now.timeIntervalSince(initial)
//                    if diff > 10 {
//                        print("Call finish")
//                        continuation.finish()
//                        timer.invalidate()
//                    }
//                }
//                continuation.onTermination = { @Sendable state in
//                    // 同步取消定时器，否则会在diff > 10条件中取消
////                    cusTimer.invalidate()
//                    print("onTermination: \(state)")
//                }
//            }
//        }
        
        // return驱动产生值
        AsyncStream {
//            if self.cancle {
//                // 此时会取消继续迭代
//                print("return nil")
//                return nil
//            }
            try? await Task.sleep(nanoseconds: NSEC_PER_SEC)
            return Date()

        } onCancel: {
            print("取消 cancle")
        }
        // 打印
        /*
         await v Optional(2025-02-07 08:45:33 +0000)
         await v Optional(2025-02-07 08:45:34 +0000)
         await v Optional(2025-02-07 08:45:35 +0000)
         await v Optional(2025-02-07 08:45:36 +0000)
         取消 cancle
         await v Optional(2025-02-07 08:45:37 +0000)
         取消 cancle
         
         // return nil 打印,不会触发onCancel
         await v Optional(2025-02-07 08:57:05 +0000)
         await v Optional(2025-02-07 08:57:06 +0000)
         await v Optional(2025-02-07 08:57:07 +0000)
         await v Optional(2025-02-07 08:57:08 +0000)
         await v Optional(2025-02-07 08:57:09 +0000)
         return nil
         */
    }
}
