import Foundation
import UIKit

// MARK: - 视频缓存使用示例
class VideoCacheExample {

  // MARK: - 示例方法

  /// 缓存视频示例
  func cacheVideosExample() {
    let videoURLs = [
      "https://example.com/video1.mp4",
      "https://example.com/video2.mp4",
      "https://example.com/video3.mp4",
      "https://example.com/video4.mp4",
      "https://example.com/video5.mp4",
    ]

    // 使用缓存管理器下载视频，系统会自动控制最多3个并发下载
    CEVideoCacheManager.shared.cacheVideos(videoURLs) { success, url, localPath in
      if success {
        print("videocache - ✅ 视频下载成功")
        print("videocache - 原始URL: \(url)")
        print("videocache - 本地路径: \(localPath ?? "无")")
      } else {
        print("videocache - ❌ 视频下载失败: \(url)")
      }
    }
  }

  /// 读取缓存示例
  func getCachedVideoExample() {
    let videoURL = "https://example.com/video1.mp4"

    if let cachedPath = CEVideoCacheManager.shared.getCachedVideoPath(for: videoURL) {
      print("videocache - ✅ 找到缓存视频: \(cachedPath)")
      // 这里可以播放本地视频文件
      playLocalVideo(path: cachedPath)
    } else {
      print("videocache - ⚠️ 未找到缓存，需要先下载")
      // 开始下载
      downloadAndPlayVideo(url: videoURL)
    }
  }

  /// 下载并播放视频
  private func downloadAndPlayVideo(url: String) {
    CEVideoCacheManager.shared.cacheVideos([url]) { [weak self] success, urlString, localPath in
      if success, let path = localPath {
        self?.playLocalVideo(path: path)
      } else {
        print("videocache - ❌ 视频下载失败")
      }
    }
  }

  /// 播放本地视频（示例）
  private func playLocalVideo(path: String) {
    print("videocache - 🎬 开始播放本地视频: \(path)")
    // 这里可以集成你的视频播放器
    // 例如: AVPlayerViewController, IJKMediaFramework 等
  }

  /// 管理缓存示例
  func manageCacheExample() {
    let cacheManager = CEVideoCacheManager.shared

    // 获取缓存大小
    let cacheSize = cacheManager.getCacheSize()
    let sizeInMB = Double(cacheSize) / (1024 * 1024)
    print("videocache - 💾 当前缓存大小: \(String(format: "%.2f", sizeInMB)) MB")

    // 如果缓存太大，可以清理
    if sizeInMB > 100 {  // 超过100MB
      cacheManager.clearCache()
      print("videocache - 🧹 缓存已清理")
    }
  }
}

// MARK: - 在ViewController中的使用示例
extension ViewController {

  /// 集成到ViewController的示例
  func integrateVideoCacheExample() {
    let example = VideoCacheExample()

    // 预缓存一些视频
    example.cacheVideosExample()

    // 检查缓存状态
    example.getCachedVideoExample()

    // 管理缓存
    example.manageCacheExample()
  }
}
