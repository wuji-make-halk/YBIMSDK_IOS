//
//  SocketManager.swift
//  realtimechatios
//
//  Created by Lucas Jackson on 5/14/18.
//  Copyright © 2018 Lucas Jackson. All rights reserved.
//

import Foundation
import Starscream
import Reachability
import SVProgressHUD

class SocketManager:WebSocketDelegate {
    
    var reConnectTime = 0 //设置重连次数
    let reConnectMaxTimes = 10  //最大重连次数
    let reachability = Reachability.forInternetConnection()
    var timer:Timer = Timer.init()
    var fid:String!
   private(set) var  isConnected:Bool = false
    
   func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            isConnected = true
            NotificationCenter.default.post(name: Notification.Name("sockState"), object: 1)
        case .disconnected(let reason, let code):
            isConnected = false
            self.socketDisConnect()
            NotificationCenter.default.post(name: NSNotification.Name.init("sockState"),object:0)
         
        case .text(let string):
            NotificationCenter.default.post(name: NSNotification.Name("receivedMessage"), object:nil,userInfo: ["message" : string ])
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            
            break
        case .pong(_):
            
            break
        case .viablityChanged(_):
            
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
             isConnected = false
            NotificationCenter.default.post(name: Notification.Name("sockState"), object: 2)
        case .error(let error):
             isConnected = false
            NotificationCenter.default.post(name: Notification.Name("sockState"), object: 3)
        }
    }
    
    static let shared = SocketManager()
    
    var sock:WebSocket!
    
    func connect(fid:String) {
        let request = NSMutableURLRequest(url: URL(string:"ws://192.168.31.188:9876")!)
        request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: HTTPCookieStorage.shared.cookies!)
        sock = WebSocket.init(request: request as URLRequest)
        sock.delegate = self
        sock.connect()
        self.fid = fid
        setHeartBeat()
        setReachability()
    }
    
    private func setReachability(){
        
        reachability?.reachableBlock = { reachabilty in
            self.socketReconnect()
            if (reachabilty?.isReachableViaWiFi())!{
                self.socketReconnect()
            }else if (reachabilty?.isReachableViaWWAN())!{
                self.socketReconnect()
            }else {
                //  self.socketReconnect()
            }
        }
        
        reachability?.unreachableBlock = {
            reachabilty in
            self.socketReconnect()
            
        }
        
        reachability?.startNotifier()
    }
    
    //重新连接
      func socketReconnect() {
          //如果socket正在连接，则取消
          if self.isConnected {
              return
          }
          
          //设置重连次数，解决无限重连问题
          reConnectTime =  reConnectTime + 1
          if reConnectTime < reConnectMaxTimes {
              //添加重连延时执行，防止某个时间段，全部执行
              let time: TimeInterval = 5.0
              DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time) {
                  if self.isConnected == false {
                      //重新连接，并且重新登录
                    self.connect(fid: self.fid)
                      
                  }
              }
          } else {
              //提示重连失败
              SVProgressHUD.show(withStatus: "websocket重连次数过多")
          }
      }
      
      //socket主动断开 终止定时器
      func socketDisConnect() {
          if self.isConnected {
            self.timer.invalidate()
            sock.disconnect()
          }
      }
    
    //设置心跳包
    private func setHeartBeat(){
        //定时器，7s维持心跳包
        timer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(heartBeat), userInfo: nil, repeats: true)
        //滑动timer失效是添加
        RunLoop.current.add(timer, forMode: .common)
    }
    
    //心跳
    @objc func heartBeat(){
        if self.isConnected {
            self.socketHeartBeat()
        }
    }
    
    

    //心跳包
    func socketHeartBeat()  {
       let registModel = ChatModel()
        registModel.fid = self.fid
        registModel.tid = ""
        registModel.sid = ""
        registModel.messageContentType = .heartBeat
        self.sendMessage(registModel)
    }
    
    //在线 消息
    func online(fid:String)  {
          let registModel = ChatModel()
          registModel.fid = fid
          registModel.tid = ""
          registModel.sid = ""
          registModel.messageContentType = .onLine
          self.sendMessage(registModel)
    }

    
    //普通消息
    func sendMessage(_ model:ChatModel) {
        if model.messageContentType != .onLine && model.messageContentType != .session && model.messageContentType != .heartBeat {
        
            realmManager.shared.insertChat(by: model)
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: model.toJSON(), options: [])
            print("sendMessage:" + model.toJSONString()!)
            self.sock.write(string: String(data: jsonData,encoding: .utf8)!)
        } catch {
            print(error.localizedDescription)
        }
    }
   
}
