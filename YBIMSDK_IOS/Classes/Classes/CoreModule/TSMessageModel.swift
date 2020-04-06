//
//  TSMessageModel.swift
//  YBIMSDK
//
//  Created by apolla on 2020/1/19.
//  Copyright © 2016 Hilen. All rights reserved.
//

import Foundation
import ObjectMapper
import RealmSwift

class MessageModel: Object, TSModelProtocol {
    
    @objc dynamic var payload : String?
    dynamic var messageFromType : MessageFromType {switch self.sid == nil {
    case false :
        return .Personal
    default :
        return .Group
        }}
    dynamic  var messageContentType : String = "TEXT"
    dynamic  var sendSuccessType: String = "2" //发送消息的状态
    //发送人 ID
    @objc  dynamic  var fid : String?
    //接受人 ID
    @objc  dynamic var tid : String?
    //消息序列
    @objc dynamic var mid:String?
    @objc dynamic var  sendTime:String?
    @objc public dynamic var id: String?
    
    @objc  dynamic var sid: String?
    
    required init?(map: Map) {
        
    }
    
    required init() {
        super.init()
    }
    
    
    //以下是为了配合 UI 来使用
    @objc dynamic  var fromMe : Bool { return self.fid == "121" }
    
    func mapping(map: Map) {
        fid <- map["fid"]
        tid <- map["tid"]
        sid <- map["sid"]
        messageContentType <- map["type"]
        payload <- map["payload"]
        id <- map["id"]
        sendTime <- map["sendTime"]
    }
    
    
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    
}

