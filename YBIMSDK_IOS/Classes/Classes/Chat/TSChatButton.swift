//
//  UIButton+Chat.swift
//  YBIMSDK
//
//  Created by apolla on 2020/1/19.
//  Copyright © 2015 Hilen. All rights reserved.
//

import Foundation

class TSChatButton: UIButton {
    var showTypingKeyboard: Bool
    
    required init(coder aDecoder: NSCoder) {
        self.showTypingKeyboard = true
        super.init(coder: aDecoder)!
    }
}
