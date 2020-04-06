//
//  YBOSSInfo.swift
//  WanDeBao-Merchant
//
//  Created by 吴满乐 on 2018/5/26.
//  Copyright © 2018年 Hangzhou YunBao Technology Co., Ltd. All rights reserved.
//

import UIKit
import ObjectMapper

class YBOSSInfo: Mappable {
    
    var ossBucketName: String?
    var ossFileDir: String?
    var ossUrl: String?
    var cdnUrl: String?
    var ossKey: String?
    var ossSecret: String?
    
    required init?(map: Map) {
        
    }
    
     func mapping(map: Map) {
        
        ossBucketName <- map["bucketName"]
        ossFileDir <- map["dir"]
        ossUrl <- map["ossUrl"]
        ossKey <- map["accessKey"]
        ossSecret <- map["accessSecret"]
        cdnUrl <- map["cdnUrl"]
    }
    
}
