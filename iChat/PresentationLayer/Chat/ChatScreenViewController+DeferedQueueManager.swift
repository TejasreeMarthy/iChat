//
//  ChatScreenViewController+DeferedQueueManager.swift
//  iChat
//
//  Created by Tejasree Marthy on 11/03/19.
//  Copyright © 2019 Tejasree Marthy. All rights reserved.
//

extension ChatScreenViewController: QMDeferredQueueManagerDelegate{
    
    // MARK: QMDeferredQueueManager
    func deferredQueueManager(_ queueManager: QMDeferredQueueManager, didAddMessageLocally addedMessage: QBChatMessage) {
        if addedMessage.dialogID == self.dialog.id {
            self.chatDataSource.add(addedMessage)
        }
    }
    
    func deferredQueueManager(_ queueManager: QMDeferredQueueManager, didUpdateMessageLocally addedMessage: QBChatMessage) {
        if addedMessage.dialogID == self.dialog.id {
            self.chatDataSource.update(addedMessage)
        }
    }
}

