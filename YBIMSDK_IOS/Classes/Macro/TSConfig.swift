
//
//  TSConfig.swift
//  YBIMSDK
//
//  Created by apolla on 2020/1/19.
//  Copyright © 2016 Hilen. All rights reserved.
//

import Foundation

class TSConfig {
    static let testUserID = "wx1234skjksmsjdfwe234"
    static let ExpressionBundle = Bundle(url: Bundle(for: YBChatViewController.self).url(forResource: "Expression", withExtension: "bundle")!)
    static let ExpressionBundleName = "Expression.bundle"

    static let ExpressionPlist =  Bundle(for: YBChatViewController.self).path(forResource: "Expression", ofType: "plist")
//    Bundle.main.path(forResource: "Expression", ofType: "plist")
}
