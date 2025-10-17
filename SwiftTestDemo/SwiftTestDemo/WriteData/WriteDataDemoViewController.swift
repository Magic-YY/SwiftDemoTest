//
//  WriteDataDemoViewController.swift
//  SwiftTestDemo
//
//  Created by 杨运 on 2025/10/17.
//

import UIKit

class WriteDataDemoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "文件保存测试"
        
        // 添加清理按钮
        setupCleanupButton()
        
        // 延迟执行测试，确保界面加载完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.runAllTests()
        }
    }
    
    // MARK: - UI Setup
    
    /// 设置清理按钮
    private func setupCleanupButton() {
        let cleanupButton = UIBarButtonItem(title: "清理文件", style: .plain, target: self, action: #selector(cleanupAllTestFiles))
        navigationItem.rightBarButtonItem = cleanupButton
    }
    
    /// 清理所有测试文件
    @objc private func cleanupAllTestFiles() {
        print("\n🗑️ 开始清理所有测试文件...")
        print("============================================================")
        
        let testFiles = [
            "test_filemanager.txt",
            "test_datawrite.txt",
            "image_filemanager.png",
            "image_datawrite.png"
        ]
        
        var cleanedCount = 0
        for fileName in testFiles {
            if cleanupTestFile(fileName: fileName) {
                cleanedCount += 1
            }
        }
        
        print("============================================================")
        print("✅ 清理完成，共清理 \(cleanedCount) 个文件\n")
        
        // 显示提示
        let alert = UIAlertController(title: "清理完成", message: "已清理 \(cleanedCount) 个测试文件", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - 主测试入口
    
    /// 运行所有测试
    private func runAllTests() {
        print("\n============================================================")
        print("开始文件保存测试")
        print("============================================================\n")
        
        // 测试1: 使用文本数据测试两种保存方法
        testWithTextData()
        
        print("\n------------------------------------------------------------\n")
        
        // 测试2: 使用图片数据测试两种保存方法
        testWithImageData()
        
        print("\n============================================================")
        print("所有测试完成")
        print("============================================================\n")
    }
    
    // MARK: - 测试方法
    
    /// 使用文本数据测试
    private func testWithTextData() {
        print("📝 测试1: 使用文本数据测试")
        print("------------------------------------------------------------")
        
        let testContent1 = "第一次保存的测试文本内容"
        let testContent2 = "第二次保存的测试文本内容（用于测试覆盖）"
        
        guard let data1 = testContent1.data(using: .utf8),
              let data2 = testContent2.data(using: .utf8) else {
            print("❌ 文本数据转换失败")
            return
        }
        
        // 测试 FileManager.createFile
        print("\n1️⃣ 测试 FileManager.createFile 方法:")
        testFileManagerCreateFile(fileName: "test_filemanager.txt", data1: data1, data2: data2)
        
        // 测试 Data.write
        print("\n2️⃣ 测试 Data.write 方法:")
        testDataWrite(fileName: "test_datawrite.txt", data1: data1, data2: data2)
    }
    
    /// 使用图片数据测试
    private func testWithImageData() {
        print("🖼️ 测试2: 使用图片数据测试")
        print("------------------------------------------------------------")
        
        // 创建两个不同颜色的图片数据
        guard let image1 = createColorImage(color: .red, size: CGSize(width: 100, height: 100)),
              let image2 = createColorImage(color: .blue, size: CGSize(width: 100, height: 100)),
              let data1 = image1.pngData(),
              let data2 = image2.pngData() else {
            print("❌ 图片数据创建失败")
            return
        }
        
        print("✅ 成功创建图片数据 (红色图片: \(data1.count) 字节, 蓝色图片: \(data2.count) 字节)")
        
        // 测试 FileManager.createFile
        print("\n1️⃣ 测试 FileManager.createFile 方法:")
        testFileManagerCreateFile(fileName: "image_filemanager.png", data1: data1, data2: data2)
        
        // 测试 Data.write
        print("\n2️⃣ 测试 Data.write 方法:")
        testDataWrite(fileName: "image_datawrite.png", data1: data1, data2: data2)
    }
    
    // MARK: - FileManager.createFile 测试
    
    /// 测试 FileManager.createFile 方法的行为
    /// - Parameters:
    ///   - fileName: 文件名
    ///   - data1: 第一次保存的数据
    ///   - data2: 第二次保存的数据（用于测试覆盖）
    private func testFileManagerCreateFile(fileName: String, data1: Data, data2: Data) {
        // 第一次保存
        print("\n   📌 第一次保存文件...")
        let firstResult = saveWithFileManager(fileName: fileName, data: data1)
        printSaveResult(method: "FileManager.createFile", isFirstSave: true, success: firstResult)
        
        // 第二次保存（测试已存在文件）
        print("\n   📌 第二次保存文件（文件已存在）...")
        let secondResult = saveWithFileManager(fileName: fileName, data: data2)
        printSaveResult(method: "FileManager.createFile", isFirstSave: false, success: secondResult)
    }
    
    /// 使用 FileManager.createFile 保存文件
    /// - Parameters:
    ///   - fileName: 文件名
    ///   - data: 要保存的数据
    /// - Returns: 是否保存成功
    private func saveWithFileManager(fileName: String, data: Data) -> Bool {
        guard let filePath = getFilePath(fileName: fileName) else {
            print("   ❌ 获取文件路径失败")
            return false
        }
        
        print("   📂 文件路径: \(filePath)")
        
        // 保存前打印文件大小
        printFileSizeBeforeSave(filePath: filePath)
        
        let fileManager = FileManager.default
        let success = fileManager.createFile(atPath: filePath, contents: data, attributes: nil)
        
        if success {
            // 保存后打印文件大小
            printFileSizeAfterSave(filePath: filePath)
        } else {
            // 保存失败提示
            print("   ❌ FileManager.createFile 保存失败")
            if fileManager.fileExists(atPath: filePath) {
                print("   ⚠️ 失败原因: 文件已存在，FileManager.createFile 不会覆盖已有文件")
            } else {
                print("   ⚠️ 失败原因: 未知错误")
            }
        }
        
        return success
    }
    
    // MARK: - Data.write 测试
    
    /// 测试 Data.write 方法的行为
    /// - Parameters:
    ///   - fileName: 文件名
    ///   - data1: 第一次保存的数据
    ///   - data2: 第二次保存的数据（用于测试覆盖）
    private func testDataWrite(fileName: String, data1: Data, data2: Data) {
        // 第一次保存
        print("\n   📌 第一次保存文件...")
        let firstResult = saveWithDataWrite(fileName: fileName, data: data1)
        printSaveResult(method: "Data.write", isFirstSave: true, success: firstResult)
        
        // 第二次保存（测试覆盖已存在文件）
        print("\n   📌 第二次保存文件（文件已存在）...")
        let secondResult = saveWithDataWrite(fileName: fileName, data: data2)
        printSaveResult(method: "Data.write", isFirstSave: false, success: secondResult)
    }
    
    /// 使用 Data.write 保存文件
    /// - Parameters:
    ///   - fileName: 文件名
    ///   - data: 要保存的数据
    /// - Returns: 是否保存成功
    private func saveWithDataWrite(fileName: String, data: Data) -> Bool {
        guard let filePath = getFilePath(fileName: fileName) else {
            print("   ❌ 获取文件路径失败")
            return false
        }
        
        print("   📂 文件路径: \(filePath)")
        
        // 保存前打印文件大小
        printFileSizeBeforeSave(filePath: filePath)
        
        do {
            try data.write(to: URL(fileURLWithPath: filePath))
            // 保存后打印文件大小
            printFileSizeAfterSave(filePath: filePath)
            return true
        } catch {
            // 保存失败提示
            print("   ❌ Data.write 保存失败")
            print("   ⚠️ 错误信息: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("   ⚠️ 错误代码: \(nsError.code)")
            }
            return false
        }
    }
    
    // MARK: - 辅助方法
    
    /// 获取文件的完整路径
    /// - Parameter fileName: 文件名
    /// - Returns: 文件的完整路径，如果目录创建失败则返回 nil
    private func getFilePath(fileName: String) -> String? {
        let fileManager = FileManager.default
        
        // 获取 Documents 目录
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.path else {
            print("   ❌ 获取 Documents 目录失败")
            return nil
        }
        
        // 创建自定义文件夹 "dataFile"
        let dataFilePath = (documentsPath as NSString).appendingPathComponent("dataFile")
        
        // 如果目录不存在，创建它
        if !fileManager.fileExists(atPath: dataFilePath) {
            do {
                try fileManager.createDirectory(atPath: dataFilePath, withIntermediateDirectories: true, attributes: nil)
                print("   📁 创建目录成功: \(dataFilePath)")
            } catch {
                print("   ❌ 创建目录失败: \(error.localizedDescription)")
                return nil
            }
        }
        
        return (dataFilePath as NSString).appendingPathComponent(fileName)
    }
    
    /// 打印保存结果
    /// - Parameters:
    ///   - method: 保存方法名称
    ///   - isFirstSave: 是否是第一次保存
    ///   - success: 是否成功
    private func printSaveResult(method: String, isFirstSave: Bool, success: Bool) {
        let saveType = isFirstSave ? "首次保存" : "再次保存"
        let resultIcon = success ? "✅" : "❌"
        let resultText = success ? "成功" : "失败"
        
        print("   \(resultIcon) \(method) - \(saveType): \(resultText)")
    }
    
    /// 打印保存前的文件大小
    /// - Parameter filePath: 文件路径
    private func printFileSizeBeforeSave(filePath: String) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath) {
            if let savedData = fileManager.contents(atPath: filePath) {
                print("   📊 保存前文件大小: \(savedData.count) 字节")
            } else {
                print("   ⚠️ 无法读取保存前文件大小")
            }
        } else {
            print("   📊 保存前文件大小: 文件不存在")
        }
    }
    
    /// 打印保存后的文件大小
    /// - Parameter filePath: 文件路径
    private func printFileSizeAfterSave(filePath: String) {
        let fileManager = FileManager.default
        if let savedData = fileManager.contents(atPath: filePath) {
            print("   📊 保存后文件大小: \(savedData.count) 字节")
        } else {
            print("   ❌ 无法读取保存后文件大小")
        }
    }
    
    /// 清理测试文件
    /// - Parameter fileName: 文件名
    /// - Returns: 是否清理成功
    @discardableResult
    private func cleanupTestFile(fileName: String) -> Bool {
        guard let filePath = getFilePath(fileName: fileName) else {
            return false
        }
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath) {
            do {
                try fileManager.removeItem(atPath: filePath)
                print("   ✅ 清理文件: \(fileName)")
                print("   📂 文件路径: \(filePath)")
                return true
            } catch {
                print("   ❌ 清理失败: \(fileName) - \(error.localizedDescription)")
                return false
            }
        } else {
            print("   ⚠️ 文件不存在: \(fileName)")
            return false
        }
    }
    
    /// 创建指定颜色的图片
    /// - Parameters:
    ///   - color: 图片颜色
    ///   - size: 图片尺寸
    /// - Returns: UIImage 对象
    private func createColorImage(color: UIColor, size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image
    }
}
