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
    
    var taskGroup: TaskGroup<TestModel?>?  // 声明一个变量来存储任务组
    
    var cancle: Bool = false
    
    var images: [String] = ["img1", "img2", "img3", "img4"]
    
    var task: Task<(), Never>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .gray
        print("test")
        
        //        streamAction()
        
        //        gcdTestAction()
        //        operationAction()
        //        configCycleView()
        //      playVideo()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let vc = WriteDataDemoViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - getter
    private(set) lazy var cycleScrollView: CECycleScrollView = {
        let view = CECycleScrollView(
            frame: CGRect(x: 50, y: 200, width: 200, height: 300), numberOfItems: images.count,
            cellClass: CycleCollectionViewCell.self, delegate: self, autoScroll: false)
        view.backgroundColor = .yellow
        return view
    }()
}

// MARK: - 视频播放
extension ViewController {
    func playVideo() {
        let videoView = CEADMediaView()
        videoView.frame = view.bounds
        view.addSubview(videoView)
        
        // 读取缓存
        var url: URL?
        let mp4 = "https://www.w3schools.com/html/mov_bbb.mp4"
        if let cacheUrl = CEVideoCacheManager.shared.getCachedVideoPath(for: mp4) {
            print("videocache - 读取缓存")
            //            url = URL(filePath: cacheUrl)
            url = URL(fileURLWithPath: cacheUrl)
        } else {
            print("videocache - 读取远端")
            url = URL(string: mp4)
            // 下载
            CEVideoCacheManager.shared.cacheVideos([mp4]) { success, url, localPath in
                print("videocache 缓存\(success), url=\(url), localPath=\(localPath)")
            }
        }
        
        if let url {
            videoView.contentURL = url
        }
        videoView.videoCycleOnce = false
        videoView.fetchVideoSize { videoSize in
            print("videocache - videoSize=\(videoSize)")
        }
        videoView.muted = true
        videoView.play()
    }
}

// MARK: - AsyncStream
extension ViewController {
    func streamAction() {
        let t = Task {
            let timer = timerStream
            for await v in timer {
                print("await v \(String(describing: v))")
            }
            
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            t.cancel()
        }
    }
    
    var timerStream: AsyncStream<Date?> {
        // Timer驱动
        AsyncStream<Date?> { continuation in
            let initial = Date()
            Task {
                let cusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                    let now = Date()
                    print("Call yield")
                    continuation.yield(Date())
                    let diff = now.timeIntervalSince(initial)
                    if diff > 10 {
                        print("Call finish")
                        continuation.finish()
                        timer.invalidate()
                    }
                }
                continuation.onTermination = { @Sendable state in
                    // 同步取消定时器，否则会在diff > 10条件中取消
                    //                    cusTimer.invalidate()
                    print("onTermination: \(state)")
                }
            }
        }
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
