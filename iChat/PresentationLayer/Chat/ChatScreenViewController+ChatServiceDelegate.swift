//
//  ChatScreenViewController+ChatServiceDelegate.swift
//  iChat
//
//  Created by Tejasree Marthy on 11/03/19.
//  Copyright © 2019 Tejasree Marthy. All rights reserved.
//

extension ChatScreenViewController: QMChatServiceDelegate {

    func chatService(_ chatService: QMChatService, didLoadMessagesFromCache messages: [QBChatMessage], forDialogID dialogID: String) {
        if self.dialog.id == dialogID {
            if !(self.progressView?.isHidden)! {
                self.stopSpinProgress()
            }
            self.chatDataSource.add(messages)
        }
    }

    func chatService(_ chatService: QMChatService, didAddMessageToMemoryStorage message: QBChatMessage, forDialogID dialogID: String) {
        if self.dialog.id == dialogID {
            // Insert message received from XMPP or self sent
            if self.chatDataSource.messageExists(message) {
                self.chatDataSource.update(message)
            }
            else {
                self.chatDataSource.add(message)
            }
        }
    }

    func chatService(_ chatService: QMChatService, didUpdateChatDialogInMemoryStorage chatDialog: QBChatDialog) {
        if self.dialog.type != QBChatDialogType.private && self.dialog.id == chatDialog.id {
            self.dialog = chatDialog
            self.title = self.dialog.name
        }
    }

    func chatService(_ chatService: QMChatService, didUpdate message: QBChatMessage, forDialogID dialogID: String) {
        if self.dialog.id == dialogID {
            self.chatDataSource.update(message)
        }
    }

    func chatService(_ chatService: QMChatService, didUpdate messages: [QBChatMessage], forDialogID dialogID: String) {
        if self.dialog.id == dialogID {
            self.chatDataSource.update(messages)
        }
    }
    
}

