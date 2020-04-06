//
//  TSChatShareMoreCollectionViewCell.swift
//  YBIMSDK
//
//  Created by apolla on 2020/1/19.
//  Copyright © 2015 Hilen. All rights reserved.
//

import UIKit

class TSChatShareMoreCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var itemButton: UIButton!
    @IBOutlet weak var itemLabel: UILabel!
    override var isHighlighted: Bool { didSet {
        if self.isHighlighted {
            self.itemButton.setBackgroundImage(TSAsset.Sharemore_other_HL.image, for: .highlighted)
        } else {
            self.itemButton.setBackgroundImage(TSAsset.Sharemore_other.image, for: UIControl.State())
        }
    }}

    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
