//
//  CycleCollectionViewCell.swift
//  SwiftTestDemo
//
//  Created by 杨运 on 2024/6/13.
//

import UIKit

class CycleCollectionViewCell: UICollectionViewCell {
    
    var imageName: String = "" {
        didSet {
            titleImageView.image = UIImage(named: imageName)
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI
    private func initUI() {
        contentView.addSubview(titleImageView)
        
        titleImageView.frame = contentView.bounds
    }
    
    private lazy var titleImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
}
