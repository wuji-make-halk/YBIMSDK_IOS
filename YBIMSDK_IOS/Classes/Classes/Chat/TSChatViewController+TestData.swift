//
//  TSChatViewController+TestData.swift
//  YBIMSDK
//
//  Created by apolla on 2020/1/19.
//  Copyright © 2016 Hilen. All rights reserved.
//

import Foundation
import SwiftyJSON

// MARK: - @extension TSChatViewController
// 聊天测试数据 , 仅仅是测试
extension YBChatViewController {
    //第一次请求的数据
    func firstFetchMessageList() {
        guard let list = self.fetchData() else {return}
        self.itemDataSouce.insert(contentsOf: list, at: 0)
        self.listTableView.reloadData { 
            self.isReloading = false
            self.listTableView.scrollBottomToLastRow()
        }
    }
    
    /**
     下拉加载更多请求，模拟一下请求时间
     */
    func pullToLoadMore() {
        self.isEndRefreshing = false
        self.indicatorView.startAnimating()
        self.isReloading = true
        
        
    }
    
    //获取聊天列表数据
    func fetchData() -> [ChatModel]? {
        var list:[ChatModel] = []
        if let message =  realmManager.shared.getMessages().last ,let chats:[ChatModel] = realmManager.shared.getChats(by: message).reversed(){
            for (index,mess) in chats.enumerated() {
                
                chats[index].messageContentType = MessageContentType(rawValue: chats[index].sendType!)!
                chats[index].sendSuccessType = .success
            }
            list = chats
        }
        return list
    }
    
    //下拉刷新加载数据， inert rows
    func updateTableWithNewRowCount(_ count: Int) {
        var contentOffset = self.self.listTableView.contentOffset

        UIView.setAnimationsEnabled(false)
        self.listTableView.beginUpdates()
        
        var heightForNewRows: CGFloat = 0
        var indexPaths = [IndexPath]()
        for i in 0 ..< count {
            let indexPath = IndexPath(row: i, section: 0)
            indexPaths.append(indexPath)
            
            heightForNewRows += self.tableView(self.listTableView, heightForRowAt: indexPath)
        }
        contentOffset.y += heightForNewRows
        
        self.listTableView.insertRows(at: indexPaths, with: UITableView.RowAnimation.none)
        self.listTableView.endUpdates()
        UIView.setAnimationsEnabled(true)
        self.self.listTableView.setContentOffset(contentOffset, animated: false)
    }

}
