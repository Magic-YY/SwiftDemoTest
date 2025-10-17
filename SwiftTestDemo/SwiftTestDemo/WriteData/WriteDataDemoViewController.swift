//
//  WriteDataDemoViewController.swift
//  SwiftTestDemo
//
//  Created by 杨运 on 2025/10/17.
//
//  测试说明：
//  本文件测试 FileManager.createFile 和 Data.write 两种文件保存方法的差异
//
//  📖 Apple 官方文档说明：
//  FileManager.createFile(atPath:contents:attributes:)
//  "If a file already exists at path, this method overwrites the contents of that 
//   file if the current process has the appropriate privileges to do so."
//  
//  翻译：如果文件已存在于指定路径，此方法会覆盖该文件的内容（前提是当前进程有相应权限）
//
//  ┌──────────────────────────────────────────────────────────────────────────────────┐
//  │                    FileManager.createFile vs Data.write 差异对比                   │
//  ├─────────────────────────┬──────────────────────────┬──────────────────────────────┤
//  │        对比项           │   FileManager.createFile │        Data.write            │
//  ├─────────────────────────┼──────────────────────────┼──────────────────────────────┤
//  │ 创建新文件              │          ✅ 支持          │          ✅ 支持              │
//  ├─────────────────────────┼──────────────────────────┼──────────────────────────────┤
//  │ 覆盖已存在文件          │          ✅ 支持          │          ✅ 支持              │
//  ├─────────────────────────┼──────────────────────────┼──────────────────────────────┤
//  │ 错误处理机制            │   Bool返回值(true/false)  │  throws 机制                 │
//  ├─────────────────────────┼──────────────────────────┼──────────────────────────────┤
//  │ 失败时错误信息          │      ❌ 无详细信息        │  ✅ 提供详细错误信息          │
//  ├─────────────────────────┼──────────────────────────┼──────────────────────────────┤
//  │ 错误代码                │          ❌ 无            │  ✅ 提供 NSError.code        │
//  ├─────────────────────────┼──────────────────────────┼──────────────────────────────┤
//  │ 调用方式                │   直接调用，检查返回值    │  需要 do-catch 或 try?       │
//  ├─────────────────────────┼──────────────────────────┼──────────────────────────────┤
//  │ 设置文件属性            │   ✅ 支持(attributes参数) │      ❌ 不支持                │
//  ├─────────────────────────┼──────────────────────────┼──────────────────────────────┤
//  │ 原子性写入              │ ❌ 不直接支持(需手动实现) │  ✅ 直接支持(.atomic选项)    │
//  ├─────────────────────────┼──────────────────────────┼──────────────────────────────┤
//  │ 其他写入选项            │          ❌ 无            │  ✅ 支持(权限、保护等)        │
//  ├─────────────────────────┼──────────────────────────┼──────────────────────────────┤
//  │ API 归属                │       FileManager         │          Data                │
//  ├─────────────────────────┼──────────────────────────┼──────────────────────────────┤
//  │ 推荐使用场景            │ 需要设置文件属性、        │ 需要详细错误信息、           │
//  │                         │ 不关心详细错误信息        │ 需要原子性写入               │
//  └─────────────────────────┴──────────────────────────┴──────────────────────────────┘
//
//  核心差异总结：
//  1. 错误处理：Data.write 提供详细的错误信息，FileManager.createFile 只返回成功/失败
//  2. 灵活性：Data.write 支持更多写入选项（原子性、权限等）
//  3. 功能：FileManager.createFile 可以设置文件属性（创建时间、权限等）
//
//  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  📚 什么是原子性写入 (Atomic Write)？
//  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
//  原子性写入是一种文件写入策略，确保文件写入操作要么完全成功，要么完全失败，不会出现中间状态。
//
//  ┌─────────────────────────────────────────────────────────────────────────┐
//  │ 非原子性写入 (atomically: false)                                         │
//  └─────────────────────────────────────────────────────────────────────────┘
//
//  过程：直接写入目标文件
//  ┌──────────┐       写入数据        ┌──────────┐
//  │ 原始文件  │  ─────────────────> │ 目标文件  │
//  │ (100KB)  │   (如果中途失败)      │ (50KB)   │ ⚠️ 文件损坏！
//  └──────────┘                      └──────────┘
//
//  风险：
//  ❌ 如果写入过程中出现错误（断电、磁盘满、程序崩溃等）
//  ❌ 文件会处于不完整状态（部分写入）
//  ❌ 原始数据丢失，新数据不完整 → 文件损坏
//
//  ┌─────────────────────────────────────────────────────────────────────────┐
//  │ 原子性写入 (atomically: true)                                            │
//  └─────────────────────────────────────────────────────────────────────────┘
//
//  过程：先写临时文件，再替换原文件
//  步骤1: 写入临时文件
//  ┌──────────┐                      ┌──────────────┐
//  │ 原始文件  │                      │ 临时文件.tmp  │
//  │ (100KB)  │                      │ (写入新数据)  │
//  └──────────┘                      └──────────────┘
//
//  步骤2: 写入成功后，原子性替换
//  ┌──────────┐       替换操作        ┌──────────────┐
//  │ 原始文件  │  ←─────────────────  │ 临时文件.tmp  │
//  │ (100KB)  │   (系统级原子操作)     │ (150KB)      │
//  └──────────┘                      └──────────────┘
//           ↓
//  ┌──────────┐
//  │ 新文件    │ ✅ 写入成功！
//  │ (150KB)  │
//  └──────────┘
//
//  优势：
//  ✅ 如果写入临时文件失败 → 原始文件不受影响
//  ✅ 只有临时文件完全写入成功后，才会替换原文件
//  ✅ 替换操作是系统级原子操作，要么成功要么失败，不会出现中间状态
//  ✅ 保证数据完整性，不会出现损坏的文件
//
//  代价：
//  ⚠️ 需要额外的磁盘空间（临时文件 + 原文件）
//  ⚠️ 性能略低（需要额外的文件操作）
//  ⚠️ 适合中小型文件，大文件可能影响性能
//
//  ┌─────────────────────────────────────────────────────────────────────────┐
//  │ 使用示例                                                                 │
//  └─────────────────────────────────────────────────────────────────────────┘
//
//  // 非原子性写入（默认）
//  try data.write(to: fileURL)
//  try data.write(to: fileURL, options: [])
//
//  // 原子性写入
//  try data.write(to: fileURL, options: .atomic)
//  try data.write(to: fileURL, options: [.atomic])
//
//  // 原子性写入 + 数据保护
//  try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
//
//  ┌─────────────────────────────────────────────────────────────────────────┐
//  │ 何时使用原子性写入？                                                      │
//  └─────────────────────────────────────────────────────────────────────────┘
//
//  ✅ 推荐使用原子性写入：
//  • 配置文件、偏好设置文件
//  • 用户数据文件（如用户资料、存档）
//  • 数据库文件、JSON/XML 配置
//  • 关键业务数据
//  • 文件较小（< 10MB）
//
//  ❌ 不推荐使用原子性写入：
//  • 大文件（如视频、大图片）
//  • 临时文件、缓存文件
//  • 日志文件（追加写入场景）
//  • 对性能要求极高的场景
//  • 磁盘空间紧张的情况
//
//  ┌─────────────────────────────────────────────────────────────────────────┐
//  │ FileManager 如何实现原子性写入？                                          │
//  └─────────────────────────────────────────────────────────────────────────┘
//
//  ❌ FileManager.createFile 不支持原子性写入选项
//     func createFile(atPath path: String, 
//                     contents data: Data?, 
//                     attributes attr: [FileAttributeKey : Any]? = nil) -> Bool
//     → 没有 options 参数，无法指定 atomic
//
//  ✅ 手动实现原子性写入的方法：
//
//  方法1: 使用 Data.write (推荐)
//  ───────────────────────────────────────────────────────────────────────
//  let fileURL = URL(fileURLWithPath: filePath)
//  try data.write(to: fileURL, options: .atomic)
//
//  方法2: 手动实现临时文件 + 替换
//  ───────────────────────────────────────────────────────────────────────
//  let fileManager = FileManager.default
//  let tempPath = filePath + ".tmp"
//  
//  // 1. 写入临时文件
//  fileManager.createFile(atPath: tempPath, contents: data, attributes: nil)
//  
//  // 2. 原子性替换
//  try fileManager.replaceItemAt(URL(fileURLWithPath: filePath), 
//                                withItemAt: URL(fileURLWithPath: tempPath))
//
//  方法3: 使用 moveItem (简单场景)
//  ───────────────────────────────────────────────────────────────────────
//  // 1. 写入临时文件
//  fileManager.createFile(atPath: tempPath, contents: data, attributes: nil)
//  
//  // 2. 删除旧文件（如果存在）
//  if fileManager.fileExists(atPath: filePath) {
//      try fileManager.removeItem(atPath: filePath)
//  }
//  
//  // 3. 移动临时文件到目标位置
//  try fileManager.moveItem(atPath: tempPath, toPath: filePath)
//
//  💡 总结：
//  • FileManager.createFile 本身不支持原子性
//  • 需要原子性时，推荐直接使用 Data.write(options: .atomic)
//  • 或者手动实现：临时文件 + replaceItemAt/moveItem
//
//  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
        print("\n🗑️ 开始清理所有测试文件和目录...")
        print("============================================================")
        
        let testFiles = [
            "test_filemanager.txt",
            "test_datawrite.txt",
            "image_filemanager.png",
            "image_datawrite.png",
            "interchange_test1.txt",
            "interchange_test2.txt"
        ]
        
        var cleanedCount = 0
        for fileName in testFiles {
            if cleanupTestFile(fileName: fileName) {
                cleanedCount += 1
            }
        }
        
        // 清理整个 dataFile 目录
        let directoryResult = cleanupDataFileDirectory()
        
        print("============================================================")
        print("✅ 清理完成，共清理 \(cleanedCount) 个文件")
        if directoryResult {
            print("✅ 已删除 dataFile 目录\n")
        } else {
            print("⚠️ dataFile 目录清理失败或不存在\n")
        }
        
        // 显示提示
        let message = directoryResult 
            ? "已清理 \(cleanedCount) 个测试文件并删除 dataFile 目录" 
            : "已清理 \(cleanedCount) 个测试文件"
        let alert = UIAlertController(title: "清理完成", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    /// 清理整个 dataFile 目录
    /// - Returns: 是否清理成功
    private func cleanupDataFileDirectory() -> Bool {
        let fileManager = FileManager.default
        
        // 获取 Documents 目录
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.path else {
            print("   ❌ 获取 Documents 目录失败")
            return false
        }
        
        // dataFile 目录路径
        let dataFilePath = (documentsPath as NSString).appendingPathComponent("dataFile")
        
        // 检查目录是否存在
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: dataFilePath, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                do {
                    try fileManager.removeItem(atPath: dataFilePath)
                    print("   🗂️ 已删除目录: \(dataFilePath)")
                    return true
                } catch {
                    print("   ❌ 删除目录失败: \(error.localizedDescription)")
                    return false
                }
            } else {
                print("   ⚠️ dataFile 不是目录")
                return false
            }
        } else {
            print("   ℹ️ dataFile 目录不存在")
            return false
        }
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
        
        print("\n------------------------------------------------------------\n")
        
        // 测试3: 两种保存方法互换测试
        testMethodInterchange()
        
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
    
    /// 测试两种保存方法互换
    private func testMethodInterchange() {
        print("🔄 测试3: 两种保存方法互换测试")
        print("------------------------------------------------------------")
        
        let testContent1 = "FileManager保存的内容"
        let testContent2 = "Data.write保存的内容"
        
        guard let data1 = testContent1.data(using: .utf8),
              let data2 = testContent2.data(using: .utf8) else {
            print("❌ 文本数据转换失败")
            return
        }
        
        // 场景1: FileManager.createFile 先保存，Data.write 后保存
        print("\n1️⃣ 场景1: FileManager.createFile → Data.write")
        testFileManagerThenDataWrite(fileName: "interchange_test1.txt", data1: data1, data2: data2)
        
        // 场景2: Data.write 先保存，FileManager.createFile 后保存
        print("\n2️⃣ 场景2: Data.write → FileManager.createFile")
        testDataWriteThenFileManager(fileName: "interchange_test2.txt", data1: data1, data2: data2)
    }
    
    /// 测试先用 FileManager.createFile 保存，再用 Data.write 保存
    /// - Parameters:
    ///   - fileName: 文件名
    ///   - data1: 第一次保存的数据（FileManager）
    ///   - data2: 第二次保存的数据（Data.write）
    private func testFileManagerThenDataWrite(fileName: String, data1: Data, data2: Data) {
        print("   📝 说明: 先用 FileManager.createFile 保存，再用 Data.write 覆盖")
        
        // 第一步：使用 FileManager.createFile 保存
        print("\n   📌 步骤1: 使用 FileManager.createFile 保存文件...")
        let firstResult = saveWithFileManager(fileName: fileName, data: data1)
        printSaveResult(method: "FileManager.createFile", isFirstSave: true, success: firstResult)
        
        // 第二步：使用 Data.write 保存（覆盖）
        print("\n   📌 步骤2: 使用 Data.write 覆盖保存...")
        let secondResult = saveWithDataWrite(fileName: fileName, data: data2)
        printSaveResult(method: "Data.write", isFirstSave: false, success: secondResult)
        
        // 结论
        if firstResult && secondResult {
            print("\n   ✅ 结论: Data.write 成功覆盖了 FileManager.createFile 创建的文件")
            print("   💡 说明: Data.write 可以覆盖任何已存在的文件，无论该文件是用什么方法创建的")
        } else if !firstResult {
            print("\n   ❌ 结论: FileManager.createFile 首次保存失败")
        } else {
            print("\n   ❌ 结论: Data.write 覆盖保存失败")
        }
    }
    
    /// 测试先用 Data.write 保存，再用 FileManager.createFile 保存
    /// - Parameters:
    ///   - fileName: 文件名
    ///   - data1: 第一次保存的数据（Data.write）
    ///   - data2: 第二次保存的数据（FileManager）
    private func testDataWriteThenFileManager(fileName: String, data1: Data, data2: Data) {
        print("   📝 说明: 先用 Data.write 保存，再用 FileManager.createFile 覆盖")
        
        // 第一步：使用 Data.write 保存
        print("\n   📌 步骤1: 使用 Data.write 保存文件...")
        let firstResult = saveWithDataWrite(fileName: fileName, data: data1)
        printSaveResult(method: "Data.write", isFirstSave: true, success: firstResult)
        
        // 第二步：使用 FileManager.createFile 保存（尝试覆盖）
        print("\n   📌 步骤2: 使用 FileManager.createFile 覆盖保存...")
        let secondResult = saveWithFileManager(fileName: fileName, data: data2)
        printSaveResult(method: "FileManager.createFile", isFirstSave: false, success: secondResult)
        
        // 结论
        if firstResult && secondResult {
            print("\n   ✅ 结论: FileManager.createFile 成功覆盖了 Data.write 创建的文件")
            print("   💡 说明: FileManager.createFile 可以覆盖任何已存在的文件，无论该文件是用什么方法创建的")
        } else if !firstResult {
            print("\n   ❌ 结论: Data.write 首次保存失败")
        } else if !secondResult {
            print("\n   ❌ 结论: FileManager.createFile 覆盖保存失败")
        }
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
            print("   ⚠️ 失败原因: 未知错误（可能是权限问题或磁盘空间不足）")
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
