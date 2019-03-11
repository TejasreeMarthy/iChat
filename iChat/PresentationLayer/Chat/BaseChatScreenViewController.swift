//
//  BaseChatScreenViewController.swift
//  iChat
//
//  Created by Tejasree Marthy on 11/03/19.
//  Copyright © 2019 Tejasree Marthy. All rights reserved.
//

import UIKit

class BaseChatScreenViewController: QMChatViewController {

    var dialog: QBChatDialog!
    var detailedCells: Set<String> = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func queueManager() -> QMDeferredQueueManager {
        return ServiceManager.instance().chatService.deferredQueueManager
    }
    
    // MARK: Collection View Datasource
    
    override func collectionView(_ collectionView: QMChatCollectionView!, dynamicSizeAt indexPath: IndexPath!, maxWidth: CGFloat) -> CGSize {
        
        var size = CGSize.zero
        guard let message = self.chatDataSource.message(for: indexPath) else {
            return size
        }
        let messageCellClass: AnyClass! = self.viewClass(forItem: message)
        if messageCellClass === QMChatAttachmentIncomingCell.self {
            size = CGSize(width: min(200, maxWidth), height: 200)
        }
        else if messageCellClass === QMChatAttachmentOutgoingCell.self {
            let attributedString = self.bottomLabelAttributedString(forItem: message)
            let bottomLabelSize = TTTAttributedLabel.sizeThatFitsAttributedString(attributedString, withConstraints: CGSize(width: min(200, maxWidth), height: CGFloat.greatestFiniteMagnitude), limitedToNumberOfLines: 0)
            size = CGSize(width: min(200, maxWidth), height: 200 + ceil(bottomLabelSize.height))
        }
        else if messageCellClass === QMChatNotificationCell.self {
            let attributedString = self.attributedString(forItem: message)
            size = TTTAttributedLabel.sizeThatFitsAttributedString(attributedString, withConstraints: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude), limitedToNumberOfLines: 0)
        }
        else {
            let attributedString = self.attributedString(forItem: message)
            size = TTTAttributedLabel.sizeThatFitsAttributedString(attributedString, withConstraints: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude), limitedToNumberOfLines: 0)
        }
        return size
    }
    
    override func collectionView(_ collectionView: QMChatCollectionView!, minWidthAt indexPath: IndexPath!) -> CGFloat {
        var size = CGSize.zero
        guard let item = self.chatDataSource.message(for: indexPath) else {
            return 0
        }
        if self.detailedCells.contains(item.id!) {
            let str = self.bottomLabelAttributedString(forItem: item)
            let frameWidth = collectionView.frame.width
            let maxHeight = CGFloat.greatestFiniteMagnitude
            size = TTTAttributedLabel.sizeThatFitsAttributedString(str, withConstraints: CGSize(width:frameWidth - Constants.limitAndInterVel.kMessageContainerWidthPadding, height: maxHeight), limitedToNumberOfLines:0)
        }
        
        if self.dialog.type != QBChatDialogType.private {
            let topLabelSize = TTTAttributedLabel.sizeThatFitsAttributedString(self.topLabelAttributedString(forItem: item), withConstraints: CGSize(width: collectionView.frame.width - Constants.limitAndInterVel.kMessageContainerWidthPadding, height: CGFloat.greatestFiniteMagnitude), limitedToNumberOfLines:0)
            if topLabelSize.width > size.width {
                size = topLabelSize
            }
        }
        return size.width
    }
    
    override func collectionView(_ collectionView: QMChatCollectionView!, layoutModelAt indexPath: IndexPath!) -> QMChatCellLayoutModel {
        var layoutModel: QMChatCellLayoutModel = super.collectionView(collectionView, layoutModelAt: indexPath)
        layoutModel.avatarSize = CGSize(width: 0, height: 0)
        layoutModel.topLabelHeight = 0.0
        layoutModel.spaceBetweenTextViewAndBottomLabel = 5
        layoutModel.maxWidthMarginSpace = 20.0
        guard let item = self.chatDataSource.message(for: indexPath) else {
            return layoutModel
        }
        let viewClass: AnyClass = self.viewClass(forItem: item) as AnyClass
        if viewClass === QMChatIncomingCell.self || viewClass === QMChatAttachmentIncomingCell.self {
            if self.dialog.type != QBChatDialogType.private {
                let topAttributedString = self.topLabelAttributedString(forItem: item)
                let size = TTTAttributedLabel.sizeThatFitsAttributedString(topAttributedString, withConstraints: CGSize(width: collectionView.frame.width - Constants.limitAndInterVel.kMessageContainerWidthPadding, height: CGFloat.greatestFiniteMagnitude), limitedToNumberOfLines:1)
                layoutModel.topLabelHeight = size.height
            }
            layoutModel.spaceBetweenTopLabelAndTextView = 5
        }
        var size = CGSize.zero
        if self.detailedCells.contains(item.id!) {
            let bottomAttributedString = self.bottomLabelAttributedString(forItem: item)
            size = TTTAttributedLabel.sizeThatFitsAttributedString(bottomAttributedString, withConstraints: CGSize(width: collectionView.frame.width - Constants.limitAndInterVel.kMessageContainerWidthPadding, height: CGFloat.greatestFiniteMagnitude), limitedToNumberOfLines:0)
        }
        layoutModel.bottomLabelHeight = floor(size.height)
        return layoutModel
    }
    
    override func collectionView(_ collectionView: QMChatCollectionView, configureCell cell: UICollectionViewCell, for indexPath: IndexPath) {
        super.collectionView(collectionView, configureCell: cell, for: indexPath)
        // subscribing to cell delegate
        let chatCell = cell as! QMChatCell
        chatCell.delegate = self as! QMChatCellDelegate
        let message = self.chatDataSource.message(for: indexPath)
        if cell is QMChatIncomingCell || cell is QMChatAttachmentIncomingCell {
            chatCell.containerView?.bgColor = ColorUtil.ChatScreen.ChatCellBackground
        }
        else if cell is QMChatOutgoingCell {
            let status: QMMessageStatus = self.queueManager().status(for: message!)
            switch status {
            case .sent:
                chatCell.containerView?.bgColor = UIColor.white
            case .sending:
                chatCell.containerView?.bgColor = ColorUtil.ChatScreen.ChatCellSendBackground
            case .notSent:
                chatCell.containerView?.bgColor = ColorUtil.ChatScreen.ChatCellNotSentBackground
            }
        }
        else if cell is QMChatAttachmentOutgoingCell {
            chatCell.containerView?.bgColor = ColorUtil.ChatScreen.ChatOutGoingCellBackground
        }
        else if cell is QMChatNotificationCell {
            cell.isUserInteractionEnabled = false
            chatCell.containerView?.bgColor = self.collectionView?.backgroundColor
        }
    }
    
    /**
     Allows to copy text from QMChatIncomingCell and QMChatOutgoingCell
     */
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        guard let item = self.chatDataSource.message(for: indexPath) else {
            return false
        }
        let viewClass: AnyClass = self.viewClass(forItem: item) as AnyClass
        if  viewClass === QMChatNotificationCell.self ||
            viewClass === QMChatContactRequestCell.self {
            return false
        }
        return super.collectionView(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
    }
    
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        let item = self.chatDataSource.message(for: indexPath)
        if (item?.isMediaMessage())! {
            ServiceManager.instance().chatService.chatAttachmentService.localImage(forAttachmentMessage: item!, completion: { (image) in
                if image != nil {
                }
            })
        }
        else {
            UIPasteboard.general.string = item?.text
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let lastSection = self.collectionView!.numberOfSections - 1
        if (indexPath.section == lastSection && indexPath.item == (self.collectionView?.numberOfItems(inSection: lastSection))! - 1) {
            guard let dialogID = self.dialog.id else {
                print("DialogID is nil")
                return super.collectionView(collectionView, cellForItemAt: indexPath)
            }
            ServiceManager.instance().chatService.loadEarlierMessages(withChatDialogID: dialogID).continueWith(block: {[weak self](task) -> Any? in
                guard let strongSelf = self else { return nil }
                if (task.result?.count ?? 0 > 0) {
                    strongSelf.chatDataSource.add(task.result as? [QBChatMessage])
                }
                return nil
            })
        }
        // marking message as read if needed
        if let message = self.chatDataSource.message(for: indexPath) {
            self.sendReadStatusForMessage(message: message)
        }
        return super.collectionView(collectionView, cellForItemAt
            : indexPath)
    }

    // Mark : Status message
    func sendReadStatusForMessage(message: QBChatMessage) {
        guard QBSession.current.currentUser != nil else {
            return
        }
        guard message.senderID != QBSession.current.currentUser?.id else {
            return
        }
        if self.messageShouldBeRead(message: message) {
            ServiceManager.instance().chatService.read(message, completion: { (error) -> Void in
                guard error == nil else {
                    print("Problems while marking message as read! Error: %@", error!)
                    return
                }
                if UIApplication.shared.applicationIconBadgeNumber > 0 {
                    let badgeNumber = UIApplication.shared.applicationIconBadgeNumber
                    UIApplication.shared.applicationIconBadgeNumber = badgeNumber - 1
                }
            })
        }
    }

    func messageShouldBeRead(message: QBChatMessage) -> Bool {
        let currentUserID = NSNumber(value: QBSession.current.currentUser!.id as UInt)
        return !message.isDateDividerMessage
            && message.senderID != self.senderID
            && !(message.readIDs?.contains(currentUserID))!
    }

    func storedMessages() -> [QBChatMessage]? {
        return ServiceManager.instance().chatService.messagesMemoryStorage.messages(withDialogID: self.dialog.id!)
    }
}
