//
//  NotificationServiceUtil.swift
//  iChat
//
//  Created by Tejasree Marthy on 07/03/19.
//  Copyright © 2019 Tejasree Marthy. All rights reserved.
//

import UIKit

protocol NotificationServiceDelegate {
    /**
     *  Is called when dialog fetching is complete and ready to return requested dialog
     *
     *  @param chatDialog QBChatDialog instance. Successfully fetched dialog
     */
    func notificationServiceDidSucceedFetchingDialog(chatDialog: QBChatDialog!)
    
    /**
     *  Is called when dialog was not found nor in memory storage nor in cache
     *  and NotificationService started requesting dialog from server
     */
    func notificationServiceDidStartLoadingDialogFromServer()
    
    /**
     *  Is called when dialog request from server was completed
     */
    func notificationServiceDidFinishLoadingDialogFromServer()
    
    /**
     *  Is called when dialog was not found in both memory storage and cache
     *  and server request return nil
     */
    func notificationServiceDidFailFetchingDialog()
}


class NotificationServiceUtil: NSObject {
    var delegate: NotificationServiceDelegate?
    var pushDialogID: String?
    
    func handlePushNotificationWithDelegate(delegate: NotificationServiceDelegate!) {
        guard let dialogID = self.pushDialogID else {
            return
        }
        guard !dialogID.isEmpty else {
            return
        }
        self.delegate = delegate;

        ServiceManager.instance().chatService.fetchDialog(withID: dialogID, completion: {
            [weak self] (chatDialog: QBChatDialog?) -> Void in
            guard let strongSelf = self else { return }

            if (chatDialog != nil) {
                strongSelf.pushDialogID = nil;
                strongSelf.delegate?.notificationServiceDidSucceedFetchingDialog(chatDialog: chatDialog);
            }
            else {
                strongSelf.delegate?.notificationServiceDidStartLoadingDialogFromServer()
                ServiceManager.instance().chatService.loadDialog(withID: dialogID, completion: { (loadedDialog: QBChatDialog?) -> Void in

                    guard let unwrappedDialog = loadedDialog else {
                        strongSelf.delegate?.notificationServiceDidFailFetchingDialog()
                        return
                    }

                    strongSelf.delegate?.notificationServiceDidFinishLoadingDialogFromServer()
                    strongSelf.delegate?.notificationServiceDidSucceedFetchingDialog(chatDialog: unwrappedDialog)
                })
            }
        })
    }
}
