//
//  CECycleScrollView.swift
//  SwiftTestDemo
//
//  Created by 杨运 on 2024/6/13.
//

import UIKit

public protocol CECycleScrollViewDelegate: AnyObject {
    
    /// 返回自定义cell
    /// - Parameters:
    ///   - collectionView: collectionView
    ///   - indexPath: indexPath
    ///   - reuseIdentifier: 重用ID
    ///   - pageIndex: 原数据源index
    /// - Returns: cell
    func cycleScrollView(_ collectionView: UICollectionView,
                         indexPath: IndexPath,
                         reuseIdentifier: String,
                         pageIndex: Int) -> UICollectionViewCell
    /// 点击回调
    func cycleScrollView(cycleScrollView: CECycleScrollView, didSelectItem atIndex: Int)
    /// 图片滚动回调
    func cycleScrollView(cycleScrollView: CECycleScrollView, didScrollToIndex index: Int)
}

private let customCellID = "CECycleScrollViewCell"

public class CECycleScrollView: UIView {
    /// 轮播代理
    private weak var delegate: CECycleScrollViewDelegate?
    /// 注册cell类型
    private var customCellClass: AnyClass
    /// 原数据真实数量值
    private var numberOfItems: Int
    /// 滚动间隔时间,默认2s
    private var scrollTimeInterval: CGFloat
    /// 是否自动滚动,默认Yes
    private var autoScroll: Bool
    /// 是否无限循环,默认Yes
    private var infiniteLoop: Bool
    /// 列表滚动数值
    private var totalItemsCount: Int = 0
    /// 滚动定时器
    private var timer: Timer?
    /// 翻倍数
    private let multiple: Int = 100

    // MARK: - Life Cycle
    /// 实例化轮播视图
    /// - Parameters:
    ///   - frame: frame
    ///   - numberOfItems: 原数据数量值
    ///   - cellClass: 自定义cell类型
    ///   - delegate: 滚动代理
    ///   - scrollTimeInterval: 滚动时长，默认2s
    ///   - autoScroll: 自动滚动，默认true
    ///   - infiniteLoop: 无限轮播，默认true
    public required init(frame: CGRect,
                         numberOfItems: Int,
                         cellClass: AnyClass,
                         delegate: CECycleScrollViewDelegate?,
                         scrollTimeInterval: CGFloat = 2.0,
                         autoScroll: Bool = true,
                         infiniteLoop: Bool = true) {
        self.numberOfItems = numberOfItems
        self.customCellClass = cellClass
        self.delegate = delegate
        self.scrollTimeInterval = scrollTimeInterval
        self.autoScroll = autoScroll
        self.infiniteLoop = infiniteLoop
        super.init(frame: frame)
        setupUI()
        registerCell()
        configNumberOfItems()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        mainView.delegate = nil
        mainView.dataSource = nil
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        flowLayout.itemSize = self.frame.size
        mainView.frame = self.bounds
        
        if mainView.contentOffset.x == 0,
           totalItemsCount > 0 {
            var targetIndex = 0
            if infiniteLoop {
                // 无限循环，调整滚动至中间
                targetIndex = totalItemsCount / 2
            } else {
                // 普通滚动
                targetIndex = 0
            }
            let indexPath = IndexPath(row: targetIndex, section: 0)
            // 无动画，隐式切换
            mainView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
    }
    
    // MARK: - UI
    private func setupUI() {
        addSubview(mainView)
    }
    
    // MARK: - getter
    private lazy var flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        return layout
    }()
    
    private lazy var mainView: UICollectionView = {
        let collectionView = UICollectionView(frame: self.bounds, collectionViewLayout: self.flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.scrollsToTop = false
        collectionView.isPagingEnabled = true
        return collectionView
    }()
}

// MARK: - public method
extension CECycleScrollView {
    /// 解决viewWillAppear时出现时轮播图卡在一半的问题，在控制器viewWillAppear时调用此方法
    public func adjustWhenControllerViewWillAppera() {
        let targetIndex = currentIndex()
        if targetIndex < totalItemsCount {
            let indexPath = IndexPath(row: targetIndex, section: 0)
            // 无动画，隐式切换
            mainView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
    }
    
    /// 动控制滚动到哪一个index
    public func makeScrollTo(index: Int) {
        if autoScroll {
            invalidateTimer()
        }
        if totalItemsCount == 0 { return }
        
        let targetIndex = totalItemsCount / 2 + index
        scrollTo(index: targetIndex)
        
        if autoScroll {
            setupTimer()
        }
    }
}

// MARK: - private method
extension CECycleScrollView {
    /// 注册cell
    private func registerCell() {
        mainView.register(customCellClass, forCellWithReuseIdentifier: customCellID)
    }
    
    /// 根据真实数据量及条件配置滚动列表数值
    private func configNumberOfItems() {
        invalidateTimer()
        // 配置列表滚动值: 如果无限轮播，滚动值翻100倍，否则为原数值
        totalItemsCount = infiniteLoop ? numberOfItems * multiple : numberOfItems
        if numberOfItems > 1 {
            // 原数值大于1，开始轮播
            mainView.isScrollEnabled = true
            // 检查是否自动滚动
            configAutoScroll()
        } else {
            // 只有一个
            mainView.isScrollEnabled = false
            invalidateTimer()
        }
        mainView.reloadData()
    }
    
    // 配置自动轮播
    private func configAutoScroll() {
        invalidateTimer()
        if autoScroll {
            setupTimer()
        }
    }
    
    private func currentIndex() -> Int {
        if mainView.frame.size.width == 0 || mainView.frame.size.height == 0 {
            return 0
        }
        let index = (mainView.contentOffset.x + flowLayout.itemSize.width * 0.5) / flowLayout.itemSize.width
        return Int(max(0, index))
    }
    
    private func scrollTo(index: Int) {
        var targetIndex = index
        // 滚动下标超过列表数量
        if targetIndex >= totalItemsCount {
            if infiniteLoop {
                // 当前滚动处于无限循环状态，调整目标index
                targetIndex = totalItemsCount / 2
                let indexPath = IndexPath(row: targetIndex, section: 0)
                // 无动画，隐式切换
                mainView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            }
            return
        }
        // 正常滚动动画
        let indexPath = IndexPath(row: targetIndex, section: 0)
        mainView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    /// 将当前index映射为滚动下标
    private func pageControlIndexWith(currentIndex: Int) -> Int {
        if numberOfItems == 0 { return 0 }
        return currentIndex % numberOfItems
    }
    
    /// 手动滑动处理无限轮播下标
    private func manualInfiniteLoopWith(index: Int) {
        let targetIndex = totalItemsCount / 2 + index
        let indexPath = IndexPath(row: targetIndex, section: 0)
        mainView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension CECycleScrollView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalItemsCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let delegate = self.delegate else {
            return UICollectionViewCell()
        }
        let pageIndex = pageControlIndexWith(currentIndex: indexPath.item)
        let cell = delegate.cycleScrollView(collectionView, indexPath: indexPath, reuseIdentifier: customCellID, pageIndex: pageIndex)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension CECycleScrollView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let delegate = self.delegate else { return }
        let itemIndex = pageControlIndexWith(currentIndex: indexPath.item)
        delegate.cycleScrollView(cycleScrollView: self, didSelectItem: itemIndex)
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if autoScroll {
            invalidateTimer()
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if autoScroll {
            setupTimer()
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidEndScrollingAnimation(mainView)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if numberOfItems == 0 { return }
        let itemIndex = currentIndex()
        let pageIndex = pageControlIndexWith(currentIndex: itemIndex)
        if let delegate = self.delegate {
            delegate.cycleScrollView(cycleScrollView: self, didScrollToIndex: pageIndex)
        }
        if !autoScroll,
           infiniteLoop {
            // 非自动滚动 && 无限轮播，处理滚动下标
            manualInfiniteLoopWith(index: pageIndex)
        }
    }
}

// MARK: - timer
extension CECycleScrollView {
    private func setupTimer() {
        // 先停止定时器
        invalidateTimer()
        // 创建定时器
        let timer = Timer.scheduledTimer(withTimeInterval: self.scrollTimeInterval, repeats: true) { [weak self] _ in
            self?.automaticScroll()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    
    private func automaticScroll() {
        if totalItemsCount == 0 { return }
        let currentIndex = self.currentIndex()
        let targetIndex = currentIndex + 1
        scrollTo(index: targetIndex)
    }
    
    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
}
