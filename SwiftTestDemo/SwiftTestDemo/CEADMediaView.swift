//
//  CEADMediaView.swift
//  SwiftDemo_11
//
//  Created by 杨运 on 2025/7/18.
//


import Foundation
import UIKit
import AVKit
import AVFoundation

// 常量定义
private struct Constants {
    static let status = "status"
    static let loadedTimeRanges = "loadedTimeRanges"
    static let playbackLikelyToKeepUp = "playbackLikelyToKeepUp"
}

class CEADMediaView: UIView {
    
    // MARK: - Properties
    
    /// 播放器状态观察回调
    var playerStatusObserverBlock: ((AVPlayerItem.Status) -> Void)?
    
    /// 周期性时间观察回调
    var periodicTimeBlock: ((TimeInterval, TimeInterval) -> Void)?
    
    /// 缓冲时间观察回调
    var bufferTimeObserverBlock: ((TimeInterval, TimeInterval) -> Void)?
    
    /// 播放可能保持流畅性观察回调
    var playbackLikelyToKeepUpObserverBlock: ((Bool) -> Void)?
    
    /// 内容URL
    var contentURL: URL?
    
    /// 是否静音
    var muted: Bool = false {
        didSet {
            videoPlayer.player?.isMuted = muted
        }
    }
    
    /// 视频重力模式
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill {
        didSet {
            videoPlayer.videoGravity = videoGravity
        }
    }
    
    /// 是否只播放一次
    var videoCycleOnce: Bool = false
    
    // MARK: - Private Properties
    
    private var playerItem: AVPlayerItem?
    private var videoOutput: AVPlayerItemVideoOutput?
    private var timeObserver: Any?
    private var itemStatus: AVPlayerItem.Status = .unknown
    private var totalTime: TimeInterval = 0
    
    private lazy var videoPlayer: AVPlayerViewController = {
        let player = AVPlayerViewController()
        player.showsPlaybackControls = false
        player.videoGravity = .resizeAspectFill
        player.view.frame = UIScreen.main.bounds
        player.view.backgroundColor = .clear
        
        // 注册播放结束通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(runLoopTheMovie(_:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
        
        // 获取音频焦点
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        return player
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    convenience init() {
        self.init(frame: UIScreen.main.bounds)
    }
    
    deinit {
        removeObservers()
        if let timeObserver = timeObserver {
            videoPlayer.player?.removeTimeObserver(timeObserver)
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        isUserInteractionEnabled = true
        backgroundColor = .clear
        frame = UIScreen.main.bounds
        
        addSubview(videoPlayer.view)
        videoPlayer.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoPlayer.view.topAnchor.constraint(equalTo: topAnchor),
            videoPlayer.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            videoPlayer.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            videoPlayer.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Public Methods
    
    func play() {
        guard let contentURL = contentURL else {
            print("content url is invalid!")
            return
        }
        
        let movieAsset = AVURLAsset(url: contentURL, options: nil)
        videoOutput = AVPlayerItemVideoOutput()
        playerItem = AVPlayerItem(asset: movieAsset)
        
        if let playerItem = playerItem, let videoOutput = videoOutput {
            playerItem.add(videoOutput)
            videoPlayer.player = AVPlayer(playerItem: playerItem)
            videoPlayer.player?.isMuted = muted
            
            // 添加周期性时间观察器
            timeObserver = videoPlayer.player?.addPeriodicTimeObserver(
                forInterval: CMTime(value: 1, timescale: 10),
                queue: .main
            ) { [weak self] time in
                guard let self = self, self.itemStatus == .readyToPlay else { return }
                
                let current = CMTimeGetSeconds(time)
                let total = CMTimeGetSeconds(playerItem.duration)
                self.totalTime = total
                
                let adjustedCurrent = (total - current) <= 0.5 ? total : current
                self.periodicTimeBlock?(total, adjustedCurrent)
            }
            
            // 添加 KVO 观察者
            addObservers()
        }
    }
    
    func stop() {
        guard videoPlayer.player != nil else { return }
        
        videoPlayer.player?.pause()
        videoPlayer.view.removeFromSuperview()
        videoPlayer.player = nil
        
        // 恢复其他应用的音频播放
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }
    
    func stopCardRecommendPlayer() {
        guard videoPlayer.player != nil else { return }
        
        videoPlayer.player?.pause()
        videoPlayer.view.removeFromSuperview()
        videoPlayer.player = nil
    }
    
    func pause() {
        videoPlayer.player?.pause()
    }
    
    func replay() {
        videoPlayer.player?.play()
    }
    
    func fetchVideoSize(completion: @escaping (CGSize) -> Void) {
        DispatchQueue.global().async { [weak self] in
            let size = self?.videoSize ?? .zero
            DispatchQueue.main.async {
                completion(size)
            }
        }
    }
    
    var videoSize: CGSize {
        guard let contentURL = contentURL else { return .zero }
        
        let asset = AVURLAsset(url: contentURL)
        let tracks = asset.tracks
        
        for track in tracks where track.mediaType == .video {
            return track.naturalSize
        }
        
        return .zero
    }
    
    var videoDuration: Int {
        guard let contentURL = contentURL else { return 0 }
        
        let asset = AVURLAsset(url: contentURL)
        let time = asset.duration
        let seconds = CMTimeGetSeconds(time)
        
        return Int(ceil(seconds))
    }
    
    // MARK: - Private Methods
    
    @objc private func runLoopTheMovie(_ notification: Notification) {
        // 如果不需要循环播放，直接返回
        guard !videoCycleOnce,
              let playerItem = notification.object as? AVPlayerItem else { return }
        
        playerItem.seek(to: .zero, completionHandler: nil)
        videoPlayer.player?.play()
    }
    
    private func addObservers() {
        guard let playerItem = playerItem else { return }
        
        playerItem.addObserver(
            self,
            forKeyPath: Constants.status,
            options: .new,
            context: nil
        )
        
        playerItem.addObserver(
            self,
            forKeyPath: Constants.loadedTimeRanges,
            options: .new,
            context: nil
        )
        
        playerItem.addObserver(
            self,
            forKeyPath: Constants.playbackLikelyToKeepUp,
            options: .new,
            context: nil
        )
    }
    
    private func removeObservers() {
        guard let playerItem = playerItem else { return }
        
        playerItem.removeObserver(self, forKeyPath: Constants.status, context: nil)
        playerItem.removeObserver(self, forKeyPath: Constants.loadedTimeRanges, context: nil)
        playerItem.removeObserver(self, forKeyPath: Constants.playbackLikelyToKeepUp, context: nil)
    }
    
    private func availableDuration(with playerItem: AVPlayerItem) -> TimeInterval {
        let loadedTimeRanges = playerItem.loadedTimeRanges
        guard let timeRange = loadedTimeRanges.first?.timeRangeValue else { return 0 }
        
        let startSeconds = CMTimeGetSeconds(timeRange.start)
        let durationSeconds = CMTimeGetSeconds(timeRange.duration)
        
        return startSeconds + durationSeconds
    }
    
    private func shouldUseImageHandleOptimize() -> Bool {
        // 这里需要根据实际的 CSConfigCenter 实现来调整
        // return CSConfigCenter.imageHandleOptimize675()
        return false
    }
    
    // MARK: - KVO
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard let keyPath = keyPath, let change = change else { return }
        
        switch keyPath {
        case Constants.status:
            if let statusValue = change[.newKey] as? Int,
               let status = AVPlayerItem.Status(rawValue: statusValue) {
                itemStatus = status
                if status == .readyToPlay {
                    videoPlayer.player?.play()
                }
                playerStatusObserverBlock?(status)
            }
            
        case Constants.loadedTimeRanges:
            guard let playerItem = playerItem else { return }
            let timeInterval = availableDuration(with: playerItem)
            let total = CMTimeGetSeconds(playerItem.duration)
            print("buffer time: \(timeInterval), total: \(total)")
            bufferTimeObserverBlock?(timeInterval, total)
            
        case Constants.playbackLikelyToKeepUp:
            guard let playerItem = playerItem else { return }
            playbackLikelyToKeepUpObserverBlock?(playerItem.isPlaybackLikelyToKeepUp)
            
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: - Override
    
    override var frame: CGRect {
        didSet {
            videoPlayer.view.frame = frame
        }
    }
}

// MARK: - UIImage Extension (需要根据实际实现调整)

extension UIImage {
    static func cs_image(with pixelBuffer: CVPixelBuffer) -> UIImage? {
        // 这里需要根据实际的 CSUtils 实现来调整
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        
        let rect = CGRect(
            x: 0,
            y: 0,
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )
        
        guard let cgImage = context.createCGImage(ciImage, from: rect) else { return nil }
        return UIImage(cgImage: cgImage)
    }
} 
