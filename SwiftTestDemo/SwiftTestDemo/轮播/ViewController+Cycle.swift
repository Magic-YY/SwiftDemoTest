//
//  ViewController+Cycle.swift
//  SwiftTestDemo
//
//  Created by 杨运 on 2024/12/9.
//

import Foundation
import UIKit

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
        self.view.addSubview(self.cycleScrollView)
    }
}
