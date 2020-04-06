//
//  TSChatModel.swift
//  YBIMSDK
//
//  Created by apolla on 2020/1/19.
//  Copyright © 2015 Hilen. All rights reserved.
//

import Foundation
import ObjectMapper
import YYText
import RealmSwift

open class ChatModel: Object, TSModelProtocol {
    //发送人 ID
    @objc public dynamic  var fid : String?
    //接受人 ID
    @objc public dynamic var tid : String?
    
    @objc public dynamic var device : String? //设备类型，iPhone，Android
    
    public dynamic var sendSuccessType:MessageSendSuccessType = .sending //是否发送完成
    
    @objc dynamic var sendType: String?
    
    //消息序列
    @objc dynamic  var mid:String?
    
    /**
     * SESSION操作
     */
      var opt:optType?
    /**
     * CREATE 创建群组消息的用户数组 包括自己
     */
      var ids:Array<String>?
    /**
     * 会话内部添加用户
     */
     var adds:Array<String>?
    
    /**
     * 会话内部删除用户
     */
      var removes:Array<String>?
    
    
    @objc public dynamic  var sid : String?  //消息 ID
    var messageContentType : MessageContentType = .Text //消息内容的类型
    @objc public dynamic var sendTime : String? //同 publishTimestamp
    
    //文本信息
    @objc public dynamic var payload : String?
    
    //音频消息
    @objc public dynamic  var audioId : String?
    @objc public dynamic  var audioURL : String?
    @objc public dynamic  var bitRate : String?
    @objc public dynamic  var channels : String?
    @objc  public dynamic  var createTime : String?
    @objc  public dynamic  var duration : String?
    @objc  public dynamic var fileSize : String?
    @objc public dynamic var formatName : String?
    @objc public dynamic var keyHash : String?
    @objc public dynamic  var mimeType : String?
    
    //图片消息
    @objc public dynamic var imageHeight : String?
    @objc public dynamic var imageWidth : String?
    @objc  public dynamic var imageId : String?
    @objc  public dynamic var originalURL : String?
    @objc  public dynamic var thumbURL : String?
    @objc  public dynamic var localStoreName: String?  //拍照，选择相机的图片的临时名称
    public dynamic  var localThumbnailImage: UIImage?
    
    //以下是为了配合 UI 来使用
    var fromMe : Bool { return self.fid == "121" }
    var richTextLayout: YYTextLayout?
    var richTextLinePositionModifier: TSYYTextLinePositionModifier?
    var richTextAttributedString: NSMutableAttributedString?
    var avatarURL:String?
    var nickName:String?
    var cellHeight: CGFloat = 0 //计算的高度储存使用，默认0
    
    required public init?(map: Map) {
        
    }
    
    public func mapping(map: Map) {
        
        fid <- map["fid"]
        tid <- map["tid"]
        mid <- map["mid"]
        device <- map["device"]
        sid <- map["sid"]
        sendType <- map["sendType"]
        opt <- map["opt"]
        adds <- map["adds"]
        removes <- map["removes"]
        ids <- map["ids"]
        
        messageContentType <- (map["type"], EnumTransform<MessageContentType>())
        sendTime <- map["sendTime"]
        payload <- map["payload"]
        
        audioId <- map["audioId"]
        audioURL <- map["audioUrl"]
        bitRate <- map["bitRate"]
        channels <- map["channels"]
        createTime <- map["ctime"]
        duration <- map["duration"]
        fileSize <- map["fileSize"]
        formatName <- map["formatName"]
        keyHash <- map["keyHash"]
        mimeType <- map["mime_type"]
        
        imageHeight <- map["height"]
        imageWidth <- map["width"]
        originalURL <- map["originalUrl"]
        thumbURL <- map["thumbUrl"]
        imageId <- map["imageId"]
    }
    
    
    required public init() {
        super.init()
    }
    
    //自定义时间 model
    init(timestamp: String) {
        super.init()
        self.payload = timestamp
        self.payload = self.timeDate.chatTimeString
        self.messageContentType = .Time
    }
    
    //自定义发送文本的 ChatModel
    init(text: String) {
        super.init()
        self.payload = text
        self.messageContentType = .Text
        self.fid = "121"
    }
    
    
    
    
    var timeDate: Date {
        get {
            let seconds = Double(self.payload!)!/1000
            let timeInterval: TimeInterval = TimeInterval(seconds)
            return Date(timeIntervalSince1970: timeInterval)
        }
    }
    
//    override class func primaryKey() -> String? {
//        return "sid"
//    }
    
}



extension ChatModel {
    //后一条数据是否比前一条数据 多了 2 分钟以上
    func isLateForTwoMinutes(_ targetModel: ChatModel) -> Bool {
        //11是秒，服务器时间精确到毫秒，做一次判断
        guard self.sendTime!.count > 11 else {
            return false
        }
        
        guard targetModel.sendTime!.count > 11 else {
            return false
        }
        
        let nextSeconds = Double(self.sendTime!)!/1000
        let previousSeconds = Double(targetModel.sendTime!)!/1000
        return (nextSeconds - previousSeconds) > 120
    }
    
    
}



// MARK: - 聊天时间的 格式化字符串
extension Date {
    fileprivate var chatTimeString: String {
        get {
            let calendar = Calendar.current
            let now = Date()
            let unit: NSCalendar.Unit = [
                NSCalendar.Unit.minute,
                NSCalendar.Unit.hour,
                NSCalendar.Unit.day,
                NSCalendar.Unit.month,
                NSCalendar.Unit.year,
            ]
            let nowComponents:DateComponents = (calendar as NSCalendar).components(unit, from: now)
            let targetComponents:DateComponents = (calendar as NSCalendar).components(unit, from: self)
            
            let year = nowComponents.year! - targetComponents.year!
            let month = nowComponents.month! - targetComponents.month!
            let day = nowComponents.day! - targetComponents.day!
            
            if year != 0 {
                return String(format: "%zd年%zd月%zd日 %02d:%02d", targetComponents.year!, targetComponents.month!, targetComponents.day!, targetComponents.hour!, targetComponents.minute!)
            } else {
                if (month > 0 || day > 7) {
                    return String(format: "%zd月%zd日 %02d:%02d", targetComponents.month!, targetComponents.day!, targetComponents.hour!, targetComponents.minute!)
                } else if (day > 2) {
                    return String(format: "%@ %02d:%02d",self.week(), targetComponents.hour!, targetComponents.minute!)
                } else if (day == 2) {
                    if targetComponents.hour! < 12 {
                        return String(format: "前天上午 %02d:%02d",targetComponents.hour!, targetComponents.minute!)
                    } else if targetComponents.hour == 12 {
                        return String(format: "前天下午 %02d:%02d",targetComponents.hour!, targetComponents.minute!)
                    } else {
                        return String(format: "前天下午 %02d:%02d",targetComponents.hour! - 12, targetComponents.minute!)
                    }
                } else if (day == 1) {
                    if targetComponents.hour! < 12 {
                        return String(format: "昨天上午 %02d:%02d",targetComponents.hour!, targetComponents.minute!)
                    } else if targetComponents.hour == 12 {
                        return String(format: "昨天下午 %02d:%02d",targetComponents.hour!, targetComponents.minute!)
                    } else {
                        return String(format: "昨天下午 %02d:%02d",targetComponents.hour! - 12, targetComponents.minute!)
                    }
                } else if (day == 0){
                    if targetComponents.hour! < 12 {
                        return String(format: "上午 %02d:%02d",targetComponents.hour!, targetComponents.minute!)
                    } else if targetComponents.hour == 12 {
                        return String(format: "下午 %02d:%02d",targetComponents.hour!, targetComponents.minute!)
                    } else {
                        return String(format: "下午 %02d:%02d",targetComponents.hour! - 12, targetComponents.minute!)
                    }
                } else {
                    return ""
                }
            }
        }
    }
}







