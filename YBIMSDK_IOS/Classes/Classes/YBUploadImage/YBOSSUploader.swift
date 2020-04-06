//
//  YBOSSUploader.swift
//  WanDeBao-Merchant
//
//  Created by 吴满乐 on 2018/5/26.
//  Copyright © 2018年 Hangzhou YunBao Technology Co., Ltd. All rights reserved.
//

import UIKit
import AliyunOSSiOS

public class YBOSSUploader {
    
    public typealias progressBlock = (_ percent: Float) -> Void
    public var progress: progressBlock?
    
    public typealias resultBlock = (_ result: String) -> Void
    public var resultClourse: resultBlock?
    public var lastOperation:Operation?
    
    public var client = OSSClient()
    public let operationQueue = OperationQueue()
    public var sumPercent: Float = 0
    public var count = 0
    
    
    
    public var accessKey:String?
    public var secretKey:String?
    public var ossAliYunHost:String?
    public var ossBucketName:String?
    public var ossFileDir:String?
    public var ossCDNUrl:String?
    //public var ossInfo: YBOSSInfo?
    
    public static let manager = YBOSSUploader.init()
    
    init() {
        
        self.accessKey = "LTAI4FojvcMJke71Mv2nw7Kf"
        self.secretKey = "MK428ICWR1mZV8jtnbSvZX9ErwJB0K"
        self.ossAliYunHost = "oss-cn-hangzhou.aliyuncs.com"
        self.ossBucketName = "yunbaomain"
        self.ossFileDir = "im/temp/"
        self.ossCDNUrl = "https://cdn.happygets.com/"
        configClient()
    }
    
    //先配置OSSClient信息
    //    public func configureClientInfo(ossInfo: YBOSSInfo) {
    //
    //    }
    
    private func configClient(){
        
        let credential: OSSCredentialProvider = OSSCustomSignerCredentialProvider {(contentToSign, error: NSErrorPointer) -> String? in
            
            let signture = OSSUtil.calBase64Sha1(withData: contentToSign, withSecret: self.secretKey!)
            if signture == nil {
                print(error!)
                return nil
            }
            return "OSS \(String(describing: self.accessKey!)):\(signture!)"
            }!
        
        let aliYunHost = "https://" + self.ossAliYunHost!
        client = OSSClient(endpoint: aliYunHost, credentialProvider: credential)
    }
    
    private func performTask(data: Data,objectType: String) {
        
        print(data, objectType)
        
        let bucketName  = self.ossBucketName!
        
        let operation = YBOSSOperation(data, objectType, bucketName, client, result: {
            result in
            if let error = result as? NSError {
                self.resultClourse!("error")
            }else{
                //拼接图片链接
                let imageUrl:String = (self.ossCDNUrl ?? "https://cdnqf.cloudmloan.com/") + objectType
                self.resultClourse!(imageUrl)
            }
            
        })
        
        //        if lastOperation != nil {
        //            operation.addDependency(lastOperation!)
        //        }
        //        lastOperation = operation
        operationQueue.addOperation(operation)
    }
    
    private func calculateOperationCount(_ dataDic: NSDictionary) -> Int {
        
        var count = 0
        for key in dataDic.allKeys {
            let keyValue = key as! String
            switch keyValue {
            case "txt":
                
                count += 1
            case "image":
                
                let array = dataDic["image"] as! Array<Any>
                count += array.count
            case "video":
                
                count += 1
            default:
                break
            }
        }
        return count
    }
    
    public func upload(_ dataDic: NSDictionary, result: @escaping resultBlock) {
        
        //self.progress = progress
        self.resultClourse = result
        
        //count = calculateOperationCount(dataDic)
        
        for key in dataDic.allKeys {
            let keyValue = key as! String
            let data = dataDic[key]
            switch keyValue {
            case "txt":
                
                performTask(data: data as! Data, objectType: "Files/txt.txt")
            case "image":
                
                let imageArray = data as! Array<Any>
                if imageArray.count != 0 {
                    for imageData in imageArray {
                        
                        //let timeInterval = NSDate().timeIntervalSince1970 * 1000
                        
                        let identifierStr = UUID().uuidString
                        let  objectType = "\(String(describing: ossFileDir!))" + identifierStr  + ".jpg"
                        
                        print("rrrrrrr\(objectType)")
                        
                        let data: Data = (imageData as! UIImage).jpegData(compressionQuality: 1.0)!
                        
                        print("ttttttttt\(data)")
                        performTask(data: data, objectType: objectType)
                    }
                }
            case "video":
                
                performTask(data: data as! Data, objectType: "Files/video.mp4")
            case "voice":
                let identifierStr = UUID().uuidString
                let  objectType = "\(String(describing: ossFileDir!))" + identifierStr  + ".amr"
                let voicedatas:NSArray = data as! NSArray
                performTask(data: voicedatas.firstObject as! Data, objectType: objectType)
            default:
                break
            }
        }
    }
}





