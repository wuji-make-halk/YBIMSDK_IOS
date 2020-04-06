//
//  realmManager.swift
//  YBIMSDK
//
//  Created by apolla on 2020/1/19.
//  Copyright © 2020 Hilen. All rights reserved.
//

import UIKit
import RealmSwift
import ObjectMapper

class realmManager: NSObject {
    
    public static let shared = realmManager()
    
    let defaultRealm:Realm = { () -> Realm in
        
        let docPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as String
        let dbPath = docPath.appending("/defaultDB.realm")
        /// 传入路径会自动创建数据库
        let defaultRealm = try! Realm(fileURL: URL.init(string: dbPath)!)
        return defaultRealm
    }()
    
     func insertChat(by chat : ChatModel) -> Void {
         
        chat.sendType = chat.messageContentType.rawValue
        if chat.sid == nil {
            chat.sid = "-\(Int(chat.fid!)! + Int(chat.tid!)!)"
        }
        
        print("realm inser Model %@",chat.sid ?? "0")
        
        
        let tchatModel = Mapper<ChatModel>().map(JSON: chat.toJSON())
        let messModels = defaultRealm.objects(MessageModel.self).filter("sid = '\(chat.sid)'")
        
      //  do{
            try! defaultRealm.write {
    
                defaultRealm.add(tchatModel!, update: .error)
                
                
                //判断是否存在此对话的历史消息
                //存在就更新内容 不存在就创建对话
                if let message:[String : Any] = tchatModel!.toJSON() ,let messageM = Mapper<MessageModel>().map(JSON: message){
                    if messModels.count > 0 {
                        messModels.first?.payload = messageM.payload
                        messModels.first?.sendTime = messageM.sendTime
                        
                    }else{
                        defaultRealm.add( messageM, update: .modified)
                    }

                }
      
            }
        
        
        
      //  } catch let error as NSError {
            // handle error
      //  }

        
    }
    
    
    /// 获取 所保存的消息
     func getChats() -> Results<ChatModel> {
  
        return defaultRealm.objects(ChatModel.self).sorted(byKeyPath: "sendTime", ascending: false)
    }
    
    /// 根据消息列表获取所有本地消息
    func getChats(by message:MessageModel) -> Results<ChatModel> {

        let predicate = NSPredicate(format: "sid = '\(message.sid ?? "")'")
//        print("sid = '\(message.sid ?? "")'")
        return defaultRealm.objects(ChatModel.self).filter(predicate).sorted(byKeyPath: "sendTime", ascending: false)
    }
    
    
    /// 获取 所保存的消息
     func getMessages() -> Results<MessageModel> {

        return defaultRealm.objects(MessageModel.self).sorted(byKeyPath: "sendTime", ascending: false)
    }
    
    /// 删除消息
    func deleteMessage(messages : Results<MessageModel>) {

        try! defaultRealm.write {
            for item in messages {
                defaultRealm.delete(self.getChats(by: item))
                defaultRealm.delete(item)
            }
            
        }
    }
    
    
    
    
}
