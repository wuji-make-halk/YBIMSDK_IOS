//
//  YBChatViewController.swift
//  YBIMSDK
//
//  Created by apolla on 2020/1/19.
//  Copyright © 2015 Hilen. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
//import BSImagePicker
import Photos
import SwiftyJSON
import Dollar

/*
 *   聊天详情的 ViewController
 */
private let kChatLoadMoreOffset: CGFloat = 30
public protocol  TSChatViewDelegate: NSObjectProtocol {
    func cellWillDisPlay(_ cell : TSChatBaseCell) ->ChatModel?
}
open class YBChatViewController: UIViewController {
    
    public weak var delegate : TSChatViewDelegate?
    var userInfo:[String:ChatModel]!
    var messageModel: MessageModel?
    @IBOutlet var refreshView: UIView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    lazy var listTableView: UITableView = {
        let listTableView = UITableView(frame: CGRect.zero, style: .plain)
        listTableView.dataSource = self
        listTableView.delegate = self
        listTableView.backgroundColor = UIColor.clear
        listTableView.separatorStyle = .none
        // This background image is stolen from Telegram App
        listTableView.backgroundView = UIImageView(image: TSAsset.Chat_background.image)
        return listTableView
    }()
    
    var chatActionBarView: TSChatActionBarView!  //action bar
    var actionBarPaddingBottomConstranit: Constraint? //action bar 的 bottom Constraint
    
    var keyboardHeightConstraint: NSLayoutConstraint?  //键盘高度的 Constraint
    var emotionInputView: TSChatEmotionInputView! //表情键盘
    var shareMoreView: TSChatShareMoreView!    //分享键盘
    var voiceIndicatorView: TSChatVoiceIndicatorView! //声音的显示 View
    let disposeBag = DisposeBag()
    var imagePicker: UIImagePickerController!   //照相机
    var itemDataSouce = [ChatModel]()
    var isReloading: Bool = false               //UITableView 是否正在加载数据, 如果是，把当前发送的消息缓存起来后再进行发送
    var currentVoiceCell: TSChatVoiceCell!     //现在正在播放的声音的 cell
    var isEndRefreshing: Bool = true            // 是否结束了下拉加载更多
    public   var fid:String!
    public  var tid:String!
    var sid:String?
    public  var messageType:MessageFromType!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.title = "message"
        self.view.backgroundColor = UIColor.viewBackgroundColor
        //  self.navigationController!.interactivePopGestureRecognizer!.isEnabled = true
        
        //TableView init
        self.listTableView.ts_registerCellNib(TSChatTextCell.self)
        self.listTableView.ts_registerCellNib(TSChatImageCell.self)
        self.listTableView.ts_registerCellNib(TSChatVoiceCell.self)
        self.listTableView.ts_registerCellNib(TSChatSystemCell.self)
        self.listTableView.ts_registerCellNib(TSChatTimeCell.self)
        self.listTableView.tableFooterView = UIView()
        self.listTableView.tableHeaderView = self.refreshView
        self.listTableView.estimatedRowHeight = 0;
        self.listTableView.estimatedSectionHeaderHeight = 0;
        self.listTableView.estimatedSectionFooterHeight = 0;
        
        //初始化子 View，键盘控制，动作 bar
        self.setupSubviews(self)
        self.keyboardControl()
        self.setupActionBarButtonInterAction()
        
        //设置录音 delegate
        AudioRecordInstance.delegate = self
        //设置播放 delegate
        AudioPlayInstance.delegate = self
        
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(connectDidconnect), name: Notification.Name("sockState"), object: 1)
        NotificationCenter.default.addObserver(self, selector: #selector(socketDidReceivedMessage(userInfo:)), name: Notification.Name("receivedMessage"), object: nil)
    }
    
    
    @objc func socketDidReceivedMessage(userInfo:Notification)  {
        if let message = userInfo.userInfo?["message"] as? String {
            print("receiverMessage" + message)
            var messageDic:[String:Any] = self.getDictionaryFromJSONString(jsonString: message) as! [String : Any]
            messageDic["sendType"] = messageDic["type"]
            let model = TSMapper<ChatModel>().map(JSON: messageDic )
            
            switch model?.messageContentType {
            case .confirm :
                //我的消息 并且存在序列号 根据序列号找到行 更新发送状态
                if let mid = model?.mid  {
                    switch self.messageType {
                    case .Personal:
                        self.updateRow(mid: mid)
                    case .Group:
                        if model?.sid == self.sid {
                            self.updateRow(mid: mid)
                        }
                    default:
                        self.updateRow(mid: mid)
                    }
                    
                }
            case .session:
                
                if let sid = model?.sid {
                    self.sid = sid
                }
                switch model?.opt {
                case .create:
                    model?.payload = "create session"
                case .add:
                    model?.payload = "add preson in session"
                default:
                    model?.payload = "this is a system message"
                }
                self.itemDataSouce.append(model!)
                let insertIndexPath = IndexPath(row: self.itemDataSouce.count - 1, section: 0)
                self.listTableView.insertRowsAtBottom([insertIndexPath])
                
                
            default:
                
                let temp = self.itemDataSouce.last
                if temp?.sendTime == nil {
                    temp?.sendTime = "\(Date().timeIntervalSince1970)"
                }
                if model?.sendTime == nil {
                    model?.sendTime = "\(Date().timeIntervalSince1970)"
                }
                if temp == nil || model!.isLateForTwoMinutes(temp!) {
                    
                    let timeModel:ChatModel = ChatModel(timestamp: model!.sendTime!)
                    self.itemDataSouce.append(timeModel)
                    let insertIndexPath = IndexPath(row: self.itemDataSouce.count - 1, section: 0)
                    self.listTableView.insertRowsAtBottom([insertIndexPath])
                    
                }
                //不是我发的消息插入数组
                if model?.fid != self.fid ,model?.fid == self.tid{
                    self.itemDataSouce.append(model!)
                    let insertIndexPath = IndexPath(row: self.itemDataSouce.count - 1, section: 0)
                    self.listTableView.insertRowsAtBottom([insertIndexPath])
                    
                    realmManager.shared.insertChat(by: model!)
                    
                }else{
                    
                    // realmManager.shared.insertChat(by: model!)
                    //我的消息 并且存在序列号 根据序列号找到行 更新发送状态
                    if let mid = model?.mid  {
                        switch self.messageType {
                        case .Personal:
                            self.updateRow(mid: mid)
                        case .Group:
                            if model?.sid == self.sid {
                                self.updateRow(mid: mid)
                            }
                        default:
                            self.updateRow(mid: mid)
                        }
                        
                    }
                }
                
                
            }
            
            
        }
        
    }
    
    
    /// 更新行
    /// - Parameter mid: 行的标识
    func updateRow(mid:String)  {
        
        let reloadRow = self.itemDataSouce.firstIndex(where: { (item) -> Bool in
            item.mid == mid
        })
        if (reloadRow != nil) {
            self.itemDataSouce[reloadRow!].sendSuccessType = .success
            self.listTableView.reloadRows(at: [IndexPath(row: reloadRow!, section: 0)], with: .none)
        }
    }
    
    
    /// socket 建立了链接
    @objc func connectDidconnect()  {
        //发送在线消息
        SocketManager.shared.online(fid: self.fid)
        
        switch messageType {
        case .Group:
            //群组消息 存在sid 获取历史消息
            if (self.sid != nil)  {
                //获取第一屏的数据
                self.firstFetchMessageList()
                
            }else{
                //sessionId 不存在证明不存在会话 创建会话
                let model = ChatModel()
                model.messageContentType = .session
                model.fid = self.fid
                model.tid = self.tid
                model.mid = self.fid + "\(Date().timeIntervalSince1970)"
                model.opt = .create
                model.ids = [model.fid!,model.tid!]
                SocketManager.shared.sendMessage(model)
            }
            
        case .Personal:
            //个人消息 直接查询历史消息
            self.firstFetchMessageList()
        default:
            self.firstFetchMessageList()
        }
        
    }
    
    
    
    override public func viewDidAppear(_ animated: Bool) {
        AudioRecordInstance.checkPermissionAndSetupRecord()
        self.checkCameraPermission()
        SocketManager.shared.connect(fid: self.fid)
        
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        
        AudioPlayInstance.stopPlayer()
        
    }
    
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
        SocketManager.shared.socketDisConnect()
        log.verbose("deinit")
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getDictionaryFromJSONString(jsonString:String) ->NSDictionary{
        
        let jsonData:Data = jsonString.data(using: .utf8)!
        
        let dict = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
        if dict != nil {
            return dict as! NSDictionary
        }
        return NSDictionary()
        
        
    }
    
}


// MARK: - @protocol UITableViewDelegate
extension YBChatViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if var baseCell:TSChatBaseCell = cell as! TSChatBaseCell {
            if (self.delegate != nil) {
                if  let model = self.delegate?.cellWillDisPlay(baseCell),let fid:String = model.fid {
                    //                    if self.userInfo[fid] == nil {
                    self.userInfo[fid] == model
                    //                    }
                    self.itemDataSouce[indexPath.row] = model
                }
                
            }
        }
    }
}


// MARK: - @protocol UITableViewDataSource
extension YBChatViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.itemDataSouce.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let chatModel = Dollar.fetch(self.itemDataSouce, indexPath.row) else {return 0}
        let type: MessageContentType = chatModel.messageContentType
        return type.chatCellHeight(chatModel)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let chatModel = Dollar.fetch(self.itemDataSouce, indexPath.row) else {return TSChatBaseCell()}
        let type: MessageContentType = chatModel.messageContentType
        return type.chatCell(tableView, indexPath: indexPath, model: chatModel, viewController: self)!
    }
}


// MARK: - @protocol UIScrollViewDelegate
extension YBChatViewController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y < kChatLoadMoreOffset) {
            if self.isEndRefreshing {
                log.info("pull to refresh");
                self.pullToLoadMore()
            }
        }
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.hideAllKeyboard()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (scrollView.contentOffset.y - scrollView.contentInset.top < kChatLoadMoreOffset) {
            if self.isEndRefreshing {
                log.info("pull to refresh");
                self.pullToLoadMore()
            }
        }
    }
}









