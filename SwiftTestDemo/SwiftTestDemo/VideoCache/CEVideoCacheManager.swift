//
//  CEVideoCacheManager.swift
//  SwiftTestDemo
//
//  Created by 杨运 on 2025/7/22.
//


import Foundation
import UIKit

// MARK: - 缓存结果回调
typealias VideoCacheCompletionHandler = (_ success: Bool, _ url: String, _ localPath: String?) ->
  Void

// MARK: - 视频缓存管理器
class CEVideoCacheManager {

  // MARK: - 单例
  static let shared = CEVideoCacheManager()

  // MARK: - 私有属性
  private let fileManager = FileManager.default
  private let cacheDirectory: URL
  private let downloadQueue = DispatchQueue(
    label: "com.ce.videocache.download", qos: .background, attributes: .concurrent)
  private let semaphore = DispatchSemaphore(value: 3)  // 限制最多3个并发下载
  private var downloadTasks: [String: URLSessionDownloadTask] = [:]
  private let lock = NSLock()

  // MARK: - 初始化
  private init() {
    // 创建缓存目录
    let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
      .first!
    cacheDirectory = URL(fileURLWithPath: cachesPath).appendingPathComponent("CEVideoCache")

    // 确保缓存目录存在
    if !fileManager.fileExists(atPath: cacheDirectory.path) {
      try? fileManager.createDirectory(
        at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
    }
  }

  // MARK: - 公共方法

  /// 缓存视频方法
  /// - Parameters:
  ///   - urls: 视频URL列表，内部自动控制最多3个并发下载
  ///   - completion: 完成回调，返回成功状态、原始URL和本地路径
  func cacheVideos(_ urls: [String], completion: @escaping VideoCacheCompletionHandler) {
    guard !urls.isEmpty else {
      print("videocache - ⚠️ URL列表为空")
      return
    }

    for urlString in urls {
      downloadVideo(urlString: urlString, completion: completion)
    }
  }

  /// 读取缓存视频路径
  /// - Parameter url: 视频原始URL
  /// - Returns: 本地缓存路径，如果没有缓存则返回nil
  func getCachedVideoPath(for url: String) -> String? {
    let fileName = generateFileName(from: url)
    let localPath = cacheDirectory.appendingPathComponent(fileName).path

    if fileManager.fileExists(atPath: localPath) {
      return localPath
    }

    return nil
  }

  // MARK: - 私有方法

  /// 下载视频
  private func downloadVideo(urlString: String, completion: @escaping VideoCacheCompletionHandler) {
    guard let url = URL(string: urlString) else {
      DispatchQueue.main.async {
        completion(false, urlString, nil)
      }
      return
    }

    // 检查是否已经缓存
    if let cachedPath = getCachedVideoPath(for: urlString) {
      DispatchQueue.main.async {
        completion(true, urlString, cachedPath)
      }
      return
    }

    // 检查是否正在下载
    lock.lock()
    if downloadTasks[urlString] != nil {
      lock.unlock()
      return
    }
    lock.unlock()

    downloadQueue.async { [weak self] in
      guard let self = self else { return }

      // 获取信号量，限制并发数
      self.semaphore.wait()

      let fileName = self.generateFileName(from: urlString)
      let destinationURL = self.cacheDirectory.appendingPathComponent(fileName)

      // 创建下载任务
      let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
        defer {
          // 释放信号量
          self?.semaphore.signal()
          // 清理下载任务记录
          self?.lock.lock()
          self?.downloadTasks.removeValue(forKey: urlString)
          self?.lock.unlock()
        }

        guard let self = self,
          let tempURL = tempURL,
          error == nil
        else {
          DispatchQueue.main.async {
            completion(false, urlString, nil)
          }
          return
        }

        do {
          // 如果文件已存在，先删除
          if self.fileManager.fileExists(atPath: destinationURL.path) {
            try self.fileManager.removeItem(at: destinationURL)
          }

          // 移动文件到缓存目录
          try self.fileManager.moveItem(at: tempURL, to: destinationURL)

          DispatchQueue.main.async {
            completion(true, urlString, destinationURL.path)
          }

        } catch {
          print("videocache - ❌ 移动文件失败: \(error)")
          DispatchQueue.main.async {
            completion(false, urlString, nil)
          }
        }
      }

      // 记录下载任务
      self.lock.lock()
      self.downloadTasks[urlString] = task
      self.lock.unlock()

      // 开始下载
      task.resume()
    }
  }

  /// 根据URL生成文件名
  private func generateFileName(from urlString: String) -> String {
    let hash = urlString.hash
    return "video_\(abs(hash)).mp4"
  }

  /// 清理缓存
  func clearCache() {
    do {
      let files = try fileManager.contentsOfDirectory(
        at: cacheDirectory, includingPropertiesForKeys: nil)
      for file in files {
        try fileManager.removeItem(at: file)
      }
      print("videocache - ✅ 缓存清理完成")
    } catch {
      print("videocache - ❌ 清理缓存失败: \(error)")
    }
  }

  /// 获取缓存大小
  func getCacheSize() -> Int64 {
    var totalSize: Int64 = 0

    do {
      let files = try fileManager.contentsOfDirectory(
        at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
      for file in files {
        let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
        totalSize += Int64(attributes.fileSize ?? 0)
      }
    } catch {
      print("videocache - ❌ 计算缓存大小失败: \(error)")
    }

    return totalSize
  }
}

// MARK: - 扩展方法
extension CEVideoCacheManager {

  /// 取消指定URL的下载任务
  func cancelDownload(for url: String) {
    lock.lock()
    if let task = downloadTasks[url] {
      task.cancel()
      downloadTasks.removeValue(forKey: url)
    }
    lock.unlock()
  }

  /// 取消所有下载任务
  func cancelAllDownloads() {
    lock.lock()
    downloadTasks.values.forEach { $0.cancel() }
    downloadTasks.removeAll()
    lock.unlock()
  }
}
