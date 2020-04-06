//
//  ApplicationManager.swift
//  YBIMSDK
//
//  Created by apolla on 2020/1/19.
//  Copyright © 2015 Hilen. All rights reserved.
//

import UIKit
import Foundation
import RxSwift

open class TSApplicationManager: NSObject {
 public   static func applicationConfigInit() {
        self.initNavigationBar()
        self.initNotifications()
        TSProgressHUD.ts_initHUD()
        LocationInstance.startLocation({}, failure: {})
    }

    /**
     Custom NavigationBar
     */
    static func initNavigationBar() {
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: true)
        UINavigationBar.appearance().barTintColor = UIColor.barTintColor
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().isTranslucent = true
        let attributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 19.0),
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        UINavigationBar.appearance().titleTextAttributes = attributes
    }
    
    /**
     Register remote notification
     */
    static func initNotifications() {
        
        let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)
        UIApplication.shared.registerForRemoteNotifications()
    }
}





