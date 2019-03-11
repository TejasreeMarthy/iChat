//
//  ChatScreenViewController+ChatConnectionDelegate.swift
//  iChat
//
//  Created by Tejasree Marthy on 11/03/19.
//  Copyright © 2019 Tejasree Marthy. All rights reserved.
//

extension ChatScreenViewController: QMChatConnectionDelegate {
    
    func chatServiceChatDidConnect(_ chatService: QMChatService) {
        self.refreshAndReadMessages()
    }
    
    func chatServiceChatDidReconnect(_ chatService: QMChatService) {
        
        self.refreshAndReadMessages()
    }
}

