//
//  TSChatViewController+HandleData.swift
//  YBIMSDK
//
//  Created by apolla on 2020/1/19.
//  Copyright © 2016 Hilen. All rights reserved.
//

import Foundation

// MARK: - @extension TSChatViewController
extension YBChatViewController {
    /**
     发送文字
     */
    func chatSendText() {
     
        dispatch_async_safely_to_main_queue({[weak self] in
            guard let strongSelf = self else { return }
            guard let textView = strongSelf.chatActionBarView.inputTextView else {return }
            guard textView.text.ts_length < 1000 else {
                TSProgressHUD.ts_showWarningWithStatus("超出字数限制")
                return
            }
            
            let text = textView.text.trimmingCharacters(in: CharacterSet.whitespaces)
            if text.count == 0 {
                TSProgressHUD.ts_showWarningWithStatus("不能发送空白消息")
                return
            }
            
            let string = strongSelf.chatActionBarView.inputTextView.text
            let model = ChatModel(text: string!)
            model.fid = self?.fid
            model.tid = self?.tid
            if let sid = self?.sid {
                model.sid = sid
            }
            model.sendTime = "\(CLongLong(round(Date().timeIntervalSince1970*1000)) )"
            model.mid = self!.fid + "\(Date().timeIntervalSince1970)"
            SocketManager.shared.sendMessage(model)
            strongSelf.itemDataSouce.append(model)
            let insertIndexPath = IndexPath(row: strongSelf.itemDataSouce.count - 1, section: 0)
            strongSelf.listTableView.insertRowsAtBottom([insertIndexPath])
            textView.text = "" //发送完毕后清空
            
            strongSelf.textViewDidChange(strongSelf.chatActionBarView.inputTextView)
        })
    }

    /**
     发送声音
     */
    func chatSendVoice(_ audioModel: ChatModel) {
        dispatch_async_safely_to_main_queue({[weak self] in
            guard let strongSelf = self else { return }
           
            audioModel.mid =  self!.fid + "\(Date().timeIntervalSince1970)"
            strongSelf.itemDataSouce.append(audioModel)
            let insertIndexPath = IndexPath(row: strongSelf.itemDataSouce.count - 1, section: 0)
            strongSelf.listTableView.insertRowsAtBottom([insertIndexPath])
        })
    }

    /**
     发送图片
     */
    func chatSendImage(_ imageModel: ChatModel) {
        dispatch_async_safely_to_main_queue({[weak self] in
            guard let strongSelf = self else { return }
            imageModel.mid = strongSelf.fid + "\(Date().timeIntervalSince1970)"
            strongSelf.itemDataSouce.append(imageModel)
            let insertIndexPath = IndexPath(row: strongSelf.itemDataSouce.count - 1, section: 0)
            strongSelf.listTableView.insertRowsAtBottom([insertIndexPath])
        })
    }
}







