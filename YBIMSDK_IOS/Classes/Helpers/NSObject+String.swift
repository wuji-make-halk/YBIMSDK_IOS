//
//  NSObject+String.swift
//  YBIMSDK
//
//  Created by apolla on 2020/1/19.
//  Copyright © 2015 Hilen. All rights reserved.
//

import Foundation
import UIKit

extension NSObject {
    class var nameOfClass: String {
        return NSStringFromClass(self).components(separatedBy: ".").last! as String
    }
    
    //用于获取 cell 的 reuse identifier
    class var identifier: String {
        return String(format: "%@_identifier", self.nameOfClass)
    }
}
