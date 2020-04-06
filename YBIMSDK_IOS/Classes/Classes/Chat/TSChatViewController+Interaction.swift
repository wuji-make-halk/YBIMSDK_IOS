//
//  TSChatViewController+Interaction.swift
//  YBIMSDK
//
//  Created by apolla on 2020/1/19.
//  Copyright © 2015 Hilen. All rights reserved.
//

import Foundation
import Photos
import MobileCoreServices
import BSImagePicker
import JXPhotoBrowser

// MARK: - @protocol ChatShareMoreViewDelegate
// 分享更多里面的 Button 交互
extension YBChatViewController: ChatShareMoreViewDelegate {
    
    //选择打开相册
    func chatShareMoreViewPhotoTaped() {
        
        let viewController = BSImagePickerViewController()
        viewController.maxNumberOfSelections = 1
        viewController.albumButton.tintColor = UIColor.white
        viewController.cancelButton.tintColor = UIColor.white
        viewController.doneButton.tintColor = UIColor.white
        
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.default, animated: false)
        self.bs_presentImagePickerController(viewController, animated: true, select: nil, deselect: nil, cancel: nil, finish: { (assets) in
            
            if let image = assets[0].getUIImage() {
                self.resizeAndSendImage(image)
            }
        }, completion: nil)
        
        
    }
    
    //选择打开相机
    func chatShareMoreViewCameraTaped() {
        let authStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if authStatus == .notDetermined {
            self.checkCameraPermission()
        } else if authStatus == .restricted || authStatus == .denied {
            TSAlertView_show("无法访问您的相机", message: "请到设置 -> 隐私 -> 相机 ，打开访问权限" )
        } else if authStatus == .authorized {
            self.openCamera()
        }
    }
    
    
    func checkCameraPermission () {
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {granted in
            if !granted {
                TSAlertView_show("无法访问您的相机", message: "请到设置 -> 隐私 -> 相机 ，打开访问权限" )
            }
        })
    }
    
    func openCamera() {
        self.imagePicker =  UIImagePickerController()
        self.imagePicker.delegate = self
        self.imagePicker.sourceType = .camera
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    
    //处理图片，并且发送图片消息
    func resizeAndSendImage(_ theImage: UIImage) {
        let originalImage = UIImage.ts_fixImageOrientation(theImage)
        let storeKey = "send_image"+String(format: "%f", Date.milliseconds)
        let thumbSize = ChatConfig.getThumbImageSize(originalImage.size)
        
        //获取缩略图失败 ，抛出异常：发送失败
        guard let thumbNail = originalImage.ts_resize(thumbSize) else { return }
        ImageFilesManager.storeImage(thumbNail, key: storeKey, completionHandler: { [weak self] in
            guard let strongSelf = self else { return }
            //发送图片消息
            let sendImageModel = ChatModel()
            sendImageModel.imageHeight = "\(originalImage.size.height)"
            sendImageModel.imageWidth = "\(originalImage.size.width )"
            sendImageModel.localStoreName = storeKey
            sendImageModel.localThumbnailImage = originalImage
            //            sendImageModel.timestamp = String(format: "%f", Date.milliseconds)
            sendImageModel.payload = "[图片]"
            sendImageModel.fid = self?.fid
            sendImageModel.tid = self?.tid
            if let sid = self?.sid {
                sendImageModel.sid = sid
            }
            sendImageModel.sendTime = "\(CLongLong(round(Date().timeIntervalSince1970*1000)) )"
            sendImageModel.messageContentType = .Image
            strongSelf.chatSendImage(sendImageModel)
            
            /**
             *  异步上传原图, 然后上传成功后，把 model 值改掉
             *  但因为还没有找到上传的 API，所以这个函数会返回错误  T.T
             * //TODO: 原图尺寸略大，需要剪裁
             */
            let imageDic = NSDictionary.init(dictionary: ["image":[originalImage]])
            
            YBOSSUploader.manager.upload(imageDic, result: { (result) in
                if result == "error" {
                    
                    let tempModel = self?.itemDataSouce.last
                    tempModel?.sendSuccessType = .failed
                    self?.itemDataSouce[(self?.itemDataSouce.count)! - 1] = tempModel!
                    DispatchQueue.main.async {
                        self?.listTableView.reloadRows(at: [IndexPath(row: (self?.listTableView.ts_totalRows ?? 1) - 1, section: 0)], with: .none)
                    }
                    
                    
                }else{
                    let tempModel = self?.itemDataSouce.last
                    
                    tempModel?.thumbURL = result + "x-oss-process=image/resize,l_200"
                    tempModel?.originalURL = result
                    self?.itemDataSouce[(self?.itemDataSouce.count)! - 1] = tempModel!
                    SocketManager.shared.sendMessage(tempModel!)
                    DispatchQueue.main.async {
                        self?.listTableView.reloadRows(at: [IndexPath(row: (self?.listTableView.ts_totalRows ?? 1) - 1, section: 0)], with: .none)
                    }
                }
                
                
            })
            
        })
        
    }
}

// MARK: - @protocol UIImagePickerControllerDelegate
// 拍照完成，进行上传图片，并且发送的请求
extension YBChatViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        guard let mediaType = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaType)] as? NSString else { return }
        if mediaType.isEqual(to: kUTTypeImage as String) {
            guard let image: UIImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else { return }
            if picker.sourceType == .camera {
                self.resizeAndSendImage(image)
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}


// MARK: - @protocol RecordAudioDelegate
// 语音录制完毕后
extension YBChatViewController: RecordAudioDelegate {
    func audioRecordUpdateMetra(_ metra: Float) {
        self.voiceIndicatorView.updateMetersValue(metra)
    }
    
    func audioRecordTooShort() {
        self.voiceIndicatorView.messageTooShort()
    }
    
    func audioRecordFinish(_ uploadAmrData: Data, recordTime: Float, fileHash: String) {
        self.voiceIndicatorView.endRecord()
        
        //发送本地音频
        let audioModel = ChatModel()
        audioModel.keyHash = fileHash
        audioModel.audioURL = ""
        audioModel.duration = "\(recordTime)"
        audioModel.payload = "[声音]"
        audioModel.messageContentType = .Voice
        audioModel.fid = self.fid
        audioModel.tid = self.tid
        if let sid = self.sid {
            audioModel.sid = sid
        }
        audioModel.sendTime = "\(CLongLong(round(Date().timeIntervalSince1970*1000)) )"
        self.chatSendVoice(audioModel)
        
        /**
         *  异步上传音频文件, 然后上传成功后，把 model 值改掉
         *  因为还没有上传的 API，所以这个函数会返回错误  T.T
         */
        let imageDic = NSDictionary.init(dictionary: ["voice":[uploadAmrData]])
        
        YBOSSUploader.manager.upload(imageDic, result: { (result) in
            if result == "error" {
                
                let tempModel = self.itemDataSouce.last
                tempModel?.sendSuccessType = .failed
                self.itemDataSouce[self.itemDataSouce.count - 1] = tempModel!
                DispatchQueue.main.async {
                    self.listTableView.reloadRows(at: [IndexPath(row: (self.listTableView.ts_totalRows ?? 1) - 1, section: 0)], with: .none)
                }
                
                
            }else{
                let tempModel = self.itemDataSouce.last
                tempModel?.thumbURL = result
                tempModel?.originalURL = result
                self.itemDataSouce[self.itemDataSouce.count - 1] = tempModel!
                
                DispatchQueue.main.async {
                    SocketManager.shared.sendMessage(tempModel!)
                    self.listTableView.reloadRows(at: [IndexPath(row: self.listTableView.ts_totalRows  - 1, section: 0)], with: .none)
                }
            }
        })
    }
    
    func audioRecordFailed() {
        TSAlertView_show("录音失败，请重试")
    }
    
    func audioRecordCanceled() {
        
    }
}

// MARK: - @protocol PlayAudioDelegate
extension YBChatViewController: PlayAudioDelegate {
    /**
     播放完毕
     */
    func audioPlayStart() {
        
    }
    
    /**
     播放完毕
     */
    func audioPlayFinished() {
        self.currentVoiceCell.resetVoiceAnimation()
    }
    
    /**
     播放失败
     */
    func audioPlayFailed() {
        self.currentVoiceCell.resetVoiceAnimation()
    }
    
    
    /**
     播放被中断
     */
    func audioPlayInterruption() {
        self.currentVoiceCell.resetVoiceAnimation()
    }
}


// MARK: - @protocol ChatEmotionInputViewDelegate
// 表情点击完毕后
extension YBChatViewController: ChatEmotionInputViewDelegate {
    //点击表情
    func chatEmoticonInputViewDidTapCell(_ cell: TSChatEmotionCell) {
        self.chatActionBarView.inputTextView.insertText(cell.emotionModel!.text)
    }
    
    //点击撤退删除
    func chatEmoticonInputViewDidTapBackspace(_ cell: TSChatEmotionCell) {
        self.chatActionBarView.inputTextView.deleteBackward()
    }
    
    //点击发送文字，包含表情
    func chatEmoticonInputViewDidTapSend() {
        self.chatSendText()
    }
}


// MARK: - @protocol UITextViewDelegate
extension YBChatViewController: UITextViewDelegate {
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            //点击发送文字，包含表情
            self.chatSendText()
            return false
        }
        return true
    }
    
    
  public  func textViewDidChange(_ textView: UITextView) {
        let contentHeight = textView.contentSize.height
        guard contentHeight < kChatActionBarTextViewMaxHeight else {
            return
        }
        
        self.chatActionBarView.inputTextViewCurrentHeight = contentHeight + 17
        self.controlExpandableInputView(showExpandable: true)
    }
    
   public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        //设置键盘类型，响应 UIKeyboardWillShowNotification 事件
        self.chatActionBarView.inputTextViewCallKeyboard()
        
        //使 UITextView 滚动到末尾的区域
        UIView.setAnimationsEnabled(false)
        let range = NSMakeRange(textView.text.ts_length - 1, 1)
        textView.scrollRangeToVisible(range)
        UIView.setAnimationsEnabled(true)
        return true
    }
}


// MARK: - @protocol TSChatCellDelegate
extension YBChatViewController: TSChatCellDelegate {
    /**
     点击了 cell 本身
     */
    func cellDidTaped(_ cell: TSChatBaseCell) {
        
    }
    
    /**
     点击了 cell 的头像
     */
    func cellDidTapedAvatarImage(_ cell: TSChatBaseCell) {
        TSAlertView_show("点击了头像")
    }
    
    /**
     点击了 cell 的图片
     */
    func cellDidTapedImageView(_ cell: TSChatBaseCell) {
        let browser = JXPhotoBrowser()
        browser.numberOfItems = {1}
        browser.cellClassAtIndex = { index in
            LoadingImageCell.self
            
        }
        browser.reloadCellAtIndex = { context in
            let browserCell = context.cell as? LoadingImageCell
            if let url =  cell.model?.originalURL {
                browserCell?.reloadData(placeholder: nil, urlString:url )
            }else{
                browserCell?.imageView.image = cell.model?.localThumbnailImage
            }
            
        }
        
        browser.show()
    }
    
    /**
     点击了 cell 中文字的 URL
     */
    func cellDidTapedLink(_ cell: TSChatBaseCell, linkString: String) {
        let viewController = TSWebViewController(URLString: linkString)
        self.ts_pushAndHideTabbar(viewController)
    }
    
    /**
     点击了 cell 中文字的 电话
     */
    func cellDidTapedPhone(_ cell: TSChatBaseCell, phoneString: String) {
        TSAlertView_show("点击了电话")
    }
    
    /**
     点击了声音 cell 的播放 button
     */
    func cellDidTapedVoiceButton(_ cell: TSChatVoiceCell, isPlayingVoice: Bool) {
        //在切换选中的语音 cell 之前把之前的动画停止掉
        if self.currentVoiceCell != nil && self.currentVoiceCell != cell {
            self.currentVoiceCell.resetVoiceAnimation()
        }
        
        if isPlayingVoice {
            self.currentVoiceCell = cell
            guard let audioModel:ChatModel = cell.model  else {
                AudioPlayInstance.stopPlayer()
                return
            }
            AudioPlayInstance.startPlaying(audioModel)
        } else {
            AudioPlayInstance.stopPlayer()
        }
    }
}





// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}

import JXPhotoBrowser

class LoadingImageCell: JXPhotoBrowserImageCell {
    
    let progressView = JXPhotoBrowserProgressView()
    
    override func setup() {
        super.setup()
        addSubview(progressView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        progressView.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    }
    
    func reloadData(placeholder: UIImage?, urlString: String?) {
        progressView.progress = 0
        let url = urlString.flatMap { URL(string: $0) }
        imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: { (received, total) in
             if total > 0 {
                           self.progressView.progress = CGFloat(received) / CGFloat(total)
                       }
        }) { (image, error, cashType, url) in
            if (image != nil) {
                 self.progressView.isHidden = true
            }else {
                self.progressView.progress = 0
                           self.setNeedsLayout()
            }
        }
   
    
}
}
/// 加载进度环
open class JXPhotoBrowserProgressView: UIView {
    
    /// 进度
    open var progress: CGFloat = 0 {
        didSet {
            DispatchQueue.main.async {
                self.fanshapedLayer.path = self.makeProgressPath(self.progress).cgPath
                if self.progress >= 1.0 || self.progress < 0.01 {
                    self.isHidden = true
                } else {
                    self.isHidden = false
                }
            }
        }
    }
    
    /// 外边界
    private var circleLayer: CAShapeLayer!
    
    /// 扇形区
    private var fanshapedLayer: CAShapeLayer!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        if self.frame.size.equalTo(.zero) {
            self.frame.size = CGSize(width: 50, height: 50)
        }
        setupUI()
        progress = 0
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.clear
        let strokeColor = UIColor(white: 1, alpha: 0.8).cgColor
        
        circleLayer = CAShapeLayer()
        circleLayer.strokeColor = strokeColor
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.path = makeCirclePath().cgPath
        layer.addSublayer(circleLayer)
        
        fanshapedLayer = CAShapeLayer()
        fanshapedLayer.fillColor = strokeColor
        layer.addSublayer(fanshapedLayer)
    }
    
    private func makeCirclePath() -> UIBezierPath {
        let arcCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath(arcCenter: arcCenter, radius: 25, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        path.lineWidth = 2
        return path
    }
    
    private func makeProgressPath(_ progress: CGFloat) -> UIBezierPath {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = bounds.midY - 2.5
        let path = UIBezierPath()
        path.move(to: center)
        path.addLine(to: CGPoint(x: bounds.midX, y: center.y - radius))
        path.addArc(withCenter: center, radius: radius, startAngle: -CGFloat.pi / 2, endAngle: -CGFloat.pi / 2 + CGFloat.pi * 2 * progress, clockwise: true)
        path.close()
        path.lineWidth = 1
        return path
    }
}
