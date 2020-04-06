//
//  AppDelegate.swift
//  YBIMSDK_IOS
//
//  Created by 宋明 on 02/07/2020.
//  Copyright (c) 2020 宋明. All rights reserved.
//

import UIKit
import YBIMSDK_IOS
import RealmSwift
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate ,TSChatViewDelegate{

    var window: UIWindow?
    
        func cellWillDisPlay(_ cell: TSChatBaseCell) -> ChatModel? {
    //        cell.avatarImageView
    //        cell.nicknameLabel
            let model = cell.model
    //        model?.avatarURL =
    //        model?.nickName =
            return model
        }

     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
              self.window = UIWindow(frame: UIScreen.main.bounds)
                self.window!.backgroundColor = UIColor.white
                let  root = YBChatViewController()
                root.delegate = self
                root.fid = "121"
                root.tid = "123"
                root.messageType = .Personal
//                self.tabbarController = root
        //        self.tabbarController?.messageModel = []
                self.window!.rootViewController = root
                self.window!.makeKeyAndVisible()
                TSApplicationManager.applicationConfigInit()
                
                self.configRealm()
        return true
    }
    
      func configRealm() {
        /// 如果要存储的数据模型属性发生变化,需要配置当前版本号比之前大
        let dbVersion : UInt64 = 5
        let docPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as String
        let dbPath = docPath.appending("/defaultDB.realm")
        let config = Realm.Configuration(fileURL: URL.init(string: dbPath), inMemoryIdentifier: nil, syncConfiguration: nil, encryptionKey: nil, readOnly: false, schemaVersion: dbVersion, migrationBlock: { (migration, oldSchemaVersion) in
            
        }, deleteRealmIfMigrationNeeded: false, shouldCompactOnLaunch: nil, objectTypes: nil)
        Realm.Configuration.defaultConfiguration = config
        Realm.asyncOpen { (realm, error) in
            if let _ = realm {
                print("Realm 服务器配置成功!")
            }else if let error = error {
                print("Realm 数据库配置失败：\(error.localizedDescription)")
            }
        }
    }
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

