//
//  ChatScreenViewController.swift
//  iChat
//
//  Created by Tejasree Marthy on 07/03/19.
//  Copyright © 2019 Tejasree Marthy. All rights reserved.
//

import UIKit
import CoreTelephony
import SafariServices

var messageTimeDateFormatter: DateFormatter {
    struct Static {
        static let instance : DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter
        }()
    }
    return Static.instance
}


class ChatScreenViewController: QMChatViewController, QMChatServiceDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, QMChatAttachmentServiceDelegate, QMChatConnectionDelegate, QMChatCellDelegate, QMDeferredQueueManagerDelegate, QMPlaceHolderTextViewPasteDelegate {

    let maxCharactersNumber = ConstantsUtil.limitAndInterVel.charactersLimit
    private var willResignActiveBlock: AnyObject?
    private var failedDownloads: Set<String> = []
    private var detailedCells: Set<String> = []
    private var typingTimer: Timer?
    private var unreadMessages: [QBChatMessage]?

    var dialog: QBChatDialog!
    var user : QBUUser = QBUUser()

    override func viewDidLoad() {
        super.viewDidLoad()
        // top layout inset for collectionView
        self.topContentAdditionalInset = self.navigationController!.navigationBar.frame.size.height + UIApplication.shared.statusBarFrame.size.height;
        view.backgroundColor = #colorLiteral(red: 0.9019607843, green: 0.9215686275, blue: 0.937254902, alpha: 1)
        self.collectionView?.backgroundColor = .clear
        self.initialiseData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.queueManager().add(self)
        self.willResignActiveBlock = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { [weak self] (notification) in
            self?.fireSendStopTypingIfNecessary()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Saving current dialog ID.
        ServiceManager.instance().currentDialogID = self.dialog.id!
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if let willResignActive = self.willResignActiveBlock {
            NotificationCenter.default.removeObserver(willResignActive)
        }
        // Resetting current dialog ID.
        ServiceManager.instance().currentDialogID = ""
        // clearing typing status blocks
        self.dialog.clearTypingStatusBlocks()
        self.queueManager().remove(self)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Custom Methods
    func initialiseData() {
        if let currentUser:QBUUser = ServiceManager.instance().currentUser {
            self.senderID = currentUser.id
            self.senderDisplayName = currentUser.login!

            ServiceManager.instance().chatService.addDelegate(self)
            ServiceManager.instance().chatService.chatAttachmentService.addDelegate(self)

            self.setUpToolbar()
            self.checkDailogeTypeForUserTypingStatus()
            self.updateTitle()

            // Retrieving messages
            let messagesCount = self.storedMessages()?.count
            if (messagesCount == 0) {
                self.startSpinProgress()
            }
            else if (self.chatDataSource.messagesCount() == 0) {
                self.chatDataSource.add(self.storedMessages()!)
            }

            self.loadMessages()
            self.enableTextCheckingTypes = NSTextCheckingAllTypes
        }
    }

    func setUpToolbar() {
        self.inputToolbar?.contentView.leftBarButtonItem.isHidden = true
        self.inputToolbar?.contentView?.backgroundColor = UIColor.white
        self.inputToolbar?.contentView?.textView?.placeHolder = "Type your message here"
    }

    func checkDailogeTypeForUserTypingStatus(){
        if self.dialog.type == QBChatDialogType.private {
            self.dialog.onUserIsTyping = {
                [weak self] (userID)-> Void in
                if ServiceManager.instance().currentUser.id == userID {
                    return
                }
                self?.title = "Typing"
            }
            self.dialog.onUserStoppedTyping = {
                [weak self] (userID)-> Void in
                if ServiceManager.instance().currentUser.id == userID {
                    return
                }
                self?.updateTitle()
            }
        }
    }

    // MARK: Update title
    func updateTitle() {
        if self.dialog.type != QBChatDialogType.private {
            self.navigationItem.title = self.dialog.name
        }
        else {
            self.navigationItem.title = user.fullName
        }
    }

    func storedMessages() -> [QBChatMessage]? {
        return ServiceManager.instance().chatService.messagesMemoryStorage.messages(withDialogID: self.dialog.id!)
    }

    func loadMessages() {
        // Retrieving messages for chat dialog ID.
        guard let currentDialogID = self.dialog.id else {
            print ("Current chat dialog is nil")
            return
        }
        ServiceManager.instance().chatService.messages(withChatDialogID: currentDialogID, completion: {
            [weak self] (response, messages) -> Void in
            guard let strongSelf = self else { return }
            guard response.error == nil else {
                AlertUtil.sharedInstnace.showAlertMessage(title: "",
                                                     subTitle: response.error?.error?.localizedDescription ?? "",
                                                     viewController: self!)
                return
            }
            if !(self?.progressView?.isHidden)! {
                self?.stopSpinProgress()
            }
            if messages?.count ?? 0 > 0 {
                strongSelf.chatDataSource.add(messages)
            }
        })
    }
    
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
    
    func readMessages(messages: [QBChatMessage]) {
        if QBChat.instance.isConnected {
            ServiceManager.instance().chatService.read(messages, forDialogID: self.dialog.id!, completion: nil)
        }
        else {
            self.unreadMessages = messages
        }
        var messageIDs = [String]()
        for message in messages {
            messageIDs.append(message.id!)
        }
    }
    
    // MARK: Actions
    override func didPressSend(_ button: UIButton, withMessageText text: String, senderId: UInt, senderDisplayName: String, date: Date) {
        if !self.queueManager().shouldSendMessagesInDialog(withID: self.dialog.id!) {
            return
        }
        self.fireSendStopTypingIfNecessary()
        let message = QBChatMessage()
        message.text = text
        message.senderID = self.senderID
        message.deliveredIDs = [(NSNumber(value: self.senderID))]
        message.readIDs = [(NSNumber(value: self.senderID))]
        message.markable = true
        message.dateSent = date
        self.sendMessage(message: message)
    }
    
    func sendMessage(message: QBChatMessage) {
        // Sending message.
        ServiceManager.instance().chatService.send(message, toDialogID: self.dialog.id!, saveToHistory: true, saveToStorage: true) { (error) ->
            Void in
            if error != nil {
                AlertUtil.sharedInstnace.showAlertMessage(title: "Error",
                                                     subTitle: error?.localizedDescription ?? "",
                                                     viewController: self)
            }
        }
        self.finishSendingMessage(animated: true)
    }
    
    func placeHolderTextView(_ textView: QMPlaceHolderTextView, shouldPasteWithSender sender: Any) -> Bool {
        if UIPasteboard.general.image != nil {
            let textAttachment = NSTextAttachment()
            textAttachment.image = UIPasteboard.general.image!
            textAttachment.bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
            
            let attrStringWithImage = NSAttributedString.init(attachment: textAttachment)
            self.inputToolbar?.contentView.textView.attributedText = attrStringWithImage
            self.textViewDidChange((self.inputToolbar?.contentView.textView)!)
            
            return false
        }
        return true
    }
    
    func showCharactersNumberError() {
        let subtitle = String(format: "The character limit is %lu.", maxCharactersNumber)
        AlertUtil.sharedInstnace.showAlertMessage(title: "Error",
                                             subTitle: subtitle,
                                             viewController: self)
    }
    
    /**
     Builds a string
     Read: login1, login2, login3
     Delivered: login1, login3, @12345
     
     If user does not exist in usersMemoryStorage, then ID will be used instead of login
     
     - parameter message: QBChatMessage instance
     
     - returns: status string
     */
    func statusStringFromMessage(message: QBChatMessage) -> String {
        var statusString = ""
        let currentUserID = NSNumber(value:self.senderID)
        var readLogins: [String] = []
        if message.readIDs != nil {
            let messageReadIDs = message.readIDs!.filter { (element) -> Bool in
                return !element.isEqual(to: currentUserID)
            }
            if !messageReadIDs.isEmpty {
                for readID in messageReadIDs {
                    let user = ServiceManager.instance().usersService.usersMemoryStorage.user(withID: UInt(truncating: readID))
                    guard let unwrappedUser = user else {
                        let unknownUserLogin = "@\(readID)"
                        readLogins.append(unknownUserLogin)
                        continue
                    }
                    readLogins.append(unwrappedUser.login!)
                }
//                statusString += message.isMediaMessage() ? "SA_STR_SEEN_STATUS".localized : "SA_STR_READ_STATUS".localized;
               // statusString += ": " + readLogins.joined(separator: ", ")
            }
        }

        if message.deliveredIDs != nil {
            var deliveredLogins: [String] = []
            let messageDeliveredIDs = message.deliveredIDs!.filter { (element) -> Bool in
                return !element.isEqual(to: currentUserID)
            }
            if !messageDeliveredIDs.isEmpty {
                for deliveredID in messageDeliveredIDs {
                    let user = ServiceManager.instance().usersService.usersMemoryStorage.user(withID: UInt(truncating: deliveredID))
                    guard let unwrappedUser = user else {
                        let unknownUserLogin = "@\(deliveredID)"
                        deliveredLogins.append(unknownUserLogin)
                        continue
                    }
                    if readLogins.contains(unwrappedUser.login!) {
                        continue
                    }
                    deliveredLogins.append(unwrappedUser.login!)
                }

                if readLogins.count > 0 && deliveredLogins.count > 0 {
                    statusString += "\n"
                }

//                if deliveredLogins.count > 0 {
//                    statusString += "SA_STR_DELIVERED_STATUS".localized + ": " + deliveredLogins.joined(separator: ", ")
//                }
            }
        }

        if statusString.isEmpty {
            let messageStatus: QMMessageStatus = self.queueManager().status(for: message)
            switch messageStatus {
            case .sent:
                statusString = "Sent"
            case .sending:
                statusString = "Sending".localized
            case .notSent:
                statusString = "NotSent".localized
            }
        }
        return statusString
    }

    // MARK: Override
    override func viewClass(forItem item: QBChatMessage) -> AnyClass {
        // TODO: check and add QMMessageType.AcceptContactRequest, QMMessageType.RejectContactRequest, QMMessageType.ContactRequest
        if item.isNotificationMessage() || item.isDateDividerMessage {
            return QMChatNotificationCell.self
        }
        if (item.senderID != self.senderID) {
            if (item.isMediaMessage() && item.attachmentStatus != QMMessageAttachmentStatus.error) {
                return QMChatAttachmentIncomingCell.self
            }
            else {
                return QMChatIncomingCell.self
            }
        }
        else {
            if (item.isMediaMessage() && item.attachmentStatus != QMMessageAttachmentStatus.error) {
                return QMChatAttachmentOutgoingCell.self
            }
            else {
                return QMChatOutgoingCell.self
            }
        }
    }
    
    // MARK: Strings builder
    override func attributedString(forItem messageItem: QBChatMessage) -> NSAttributedString? {
        guard messageItem.text != nil else {
            return nil
        }
        var textColor = messageItem.senderID == self.senderID ? UIColor.black : UIColor.white
        if messageItem.isNotificationMessage() || messageItem.isDateDividerMessage {
            textColor = UIColor.black
        }
        var attributes = Dictionary<NSAttributedString.Key, AnyObject>()
        attributes[NSAttributedString.Key.foregroundColor] = textColor
        attributes[NSAttributedString.Key.font] = UIFont(name: "Helvetica", size: 17)
        let attributedString = NSAttributedString(string: messageItem.text!, attributes: attributes)
        return attributedString
    }
    
    
    /**
     Creates top label attributed string from QBChatMessage
     
     - parameter messageItem: QBCHatMessage instance
     
     - returns: login string, example: @SwiftTestDevUser1
     */
    override func topLabelAttributedString(forItem messageItem: QBChatMessage) -> NSAttributedString? {
        guard messageItem.senderID != self.senderID else {
            return nil
        }
        guard self.dialog.type != QBChatDialogType.private else {
            return nil
        }
        let paragrpahStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragrpahStyle.lineBreakMode = NSLineBreakMode.byTruncatingTail
        var attributes = Dictionary<NSAttributedString.Key, AnyObject>()
        attributes[NSAttributedString.Key.foregroundColor] = UIColor(red: 11.0/255.0, green: 96.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        attributes[NSAttributedString.Key.font] = UIFont(name: "Helvetica", size: 17)
        attributes[NSAttributedString.Key.paragraphStyle] = paragrpahStyle

        var topLabelAttributedString : NSAttributedString?
        if let topLabelText = ServiceManager.instance().usersService.usersMemoryStorage.user(withID: messageItem.senderID)?.login {
            topLabelAttributedString = NSAttributedString(string: topLabelText, attributes: attributes)
        } else { // no user in memory storage
            topLabelAttributedString = NSAttributedString(string: "@\(messageItem.senderID)", attributes: attributes)
        }
        return topLabelAttributedString
    }
    
    /**
     Creates bottom label attributed string from QBChatMessage using self.statusStringFromMessage
     
     - parameter messageItem: QBChatMessage instance
     
     - returns: bottom label status string
     */
    override func bottomLabelAttributedString(forItem messageItem: QBChatMessage) -> NSAttributedString {
        let paragrpahStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragrpahStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        var attributes = Dictionary<NSAttributedString.Key, AnyObject>()
        attributes[NSAttributedString.Key.foregroundColor] = UIColor.black
        attributes[NSAttributedString.Key.font] = UIFont(name: "Helvetica", size: 13)
        attributes[NSAttributedString.Key.paragraphStyle] = paragrpahStyle
        
        var text = messageItem.dateSent != nil ? messageTimeDateFormatter.string(from: messageItem.dateSent!) : ""
        if messageItem.senderID == self.senderID {
            text = text + "\n" + self.statusStringFromMessage(message: messageItem)
        }
        let bottomLabelAttributedString = NSAttributedString(string: text, attributes: attributes)
        return bottomLabelAttributedString
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
            size = TTTAttributedLabel.sizeThatFitsAttributedString(str, withConstraints: CGSize(width:frameWidth - ConstantsUtil.limitAndInterVel.kMessageContainerWidthPadding, height: maxHeight), limitedToNumberOfLines:0)
        }
        
        if self.dialog.type != QBChatDialogType.private {
            let topLabelSize = TTTAttributedLabel.sizeThatFitsAttributedString(self.topLabelAttributedString(forItem: item), withConstraints: CGSize(width: collectionView.frame.width - ConstantsUtil.limitAndInterVel.kMessageContainerWidthPadding, height: CGFloat.greatestFiniteMagnitude), limitedToNumberOfLines:0)
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
                let size = TTTAttributedLabel.sizeThatFitsAttributedString(topAttributedString, withConstraints: CGSize(width: collectionView.frame.width - ConstantsUtil.limitAndInterVel.kMessageContainerWidthPadding, height: CGFloat.greatestFiniteMagnitude), limitedToNumberOfLines:1)
                layoutModel.topLabelHeight = size.height
            }
            layoutModel.spaceBetweenTopLabelAndTextView = 5
        }
        var size = CGSize.zero
        if self.detailedCells.contains(item.id!) {
            let bottomAttributedString = self.bottomLabelAttributedString(forItem: item)
            size = TTTAttributedLabel.sizeThatFitsAttributedString(bottomAttributedString, withConstraints: CGSize(width: collectionView.frame.width - ConstantsUtil.limitAndInterVel.kMessageContainerWidthPadding, height: CGFloat.greatestFiniteMagnitude), limitedToNumberOfLines:0)
        }
        layoutModel.bottomLabelHeight = floor(size.height)
        return layoutModel
    }
    
    override func collectionView(_ collectionView: QMChatCollectionView, configureCell cell: UICollectionViewCell, for indexPath: IndexPath) {
        super.collectionView(collectionView, configureCell: cell, for: indexPath)
        // subscribing to cell delegate
        let chatCell = cell as! QMChatCell
        chatCell.delegate = self
        let message = self.chatDataSource.message(for: indexPath)
        if cell is QMChatIncomingCell || cell is QMChatAttachmentIncomingCell {
            chatCell.containerView?.bgColor = #colorLiteral(red: 0, green: 0.5607843137, blue: 0.5568627451, alpha: 1)
        }
        else if cell is QMChatOutgoingCell {
            let status: QMMessageStatus = self.queueManager().status(for: message!)
            switch status {
            case .sent:
                chatCell.containerView?.bgColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            case .sending:
                chatCell.containerView?.bgColor = UIColor(red: 166.3/255.0, green: 171.5/255.0, blue: 171.8/255.0, alpha: 1.0)
            case .notSent:
                chatCell.containerView?.bgColor = UIColor(red: 254.6/255.0, green: 30.3/255.0, blue: 12.5/255.0, alpha: 1.0)
            }
        }
        else if cell is QMChatAttachmentOutgoingCell {
            chatCell.containerView?.bgColor = UIColor(red: 10.0/255.0, green: 95.0/255.0, blue: 255.0/255.0, alpha: 1.0)
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
                    //                    guard let imageData = UIImageJPEGRepresentation(image!, 1) else { return }
                    
                    //                    let pasteboard = UIPasteboard.general
                    //
                    //                    pasteboard.setValue(imageData, forPasteboardType:kUTTypeJPEG as String)
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
            // the very first message
            // load more if exists
            // Getting earlier messages for chat dialog identifier.
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
    
    // MARK: QMChatCellDelegate
    
    /**
     Removes size from cache for item to allow cell expand and show read/delivered IDS or unexpand cell
     */
    func chatCellDidTapContainer(_ cell: QMChatCell!) {
        let indexPath = self.collectionView?.indexPath(for: cell)
        guard let currentMessage = self.chatDataSource.message(for: indexPath) else {
            return
        }
        let messageStatus: QMMessageStatus = self.queueManager().status(for: currentMessage)
        if messageStatus == .notSent {
            self.handleNotSentMessage(currentMessage, forCell:cell)
            return
        }
        if self.detailedCells.contains(currentMessage.id!) {
            self.detailedCells.remove(currentMessage.id!)
        } else {
            self.detailedCells.insert(currentMessage.id!)
        }
        self.collectionView?.collectionViewLayout.removeSizeFromCache(forItemID: currentMessage.id)
        self.collectionView?.performBatchUpdates(nil, completion: nil)
    }
    
    func chatCell(_ cell: QMChatCell!, didTapAtPosition position: CGPoint) {}

    func chatCell(_ cell: QMChatCell!, didPerformAction action: Selector!, withSender sender: Any!) {}
 
    func chatCell(_ cell: QMChatCell!, didTapOn result: NSTextCheckingResult) {
        switch result.resultType {
        case NSTextCheckingResult.CheckingType.link:
            let strUrl : String = (result.url?.absoluteString)!
            let hasPrefix = strUrl.lowercased().hasPrefix("https://") || strUrl.lowercased().hasPrefix("http://")
            if #available(iOS 9.0, *) {
                if hasPrefix {
                    let controller = SFSafariViewController(url: URL(string: strUrl)!)
                    self.present(controller, animated: true, completion: nil)
                    break
                }
            }
            // Fallback on earlier versions
            if UIApplication.shared.canOpenURL(URL(string: strUrl)!) {
                UIApplication.shared.open(URL(string: strUrl)!, options: [:]) { (result) in
                }
            }
            break
        default:
            break
        }
    }

    func chatCellDidTapAvatar(_ cell: QMChatCell!) {
    }

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
    
    // MARK: QMChatServiceDelegate
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

    // MARK: UITextViewDelegate
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
    }

    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Prevent crashing undo bug
        let currentCharacterCount = textView.text?.stringlength ?? 0
        if (range.length + range.location > currentCharacterCount) {
            return false
        }
        if !QBChat.instance.isConnected { return true }

        if let timer = self.typingTimer {
            timer.invalidate()
            self.typingTimer = nil
        } else {
            self.sendBeginTyping()
        }

        self.typingTimer = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(ChatScreenViewController.fireSendStopTypingIfNecessary), userInfo: nil, repeats: false)

        if maxCharactersNumber > 0 {
            if currentCharacterCount >= maxCharactersNumber && text.stringlength > 0 {
                self.showCharactersNumberError()
                return false
            }
            let newLength = currentCharacterCount + text.stringlength - range.length
            if  newLength <= maxCharactersNumber || text.stringlength == 0 {
                return true
            }
            let oldString = textView.text ?? ""
            let numberOfSymbolsToCut = maxCharactersNumber - oldString.stringlength
            var stringRange = NSMakeRange(0, min(text.stringlength, numberOfSymbolsToCut))

            // adjust the range to include dependent chars
            stringRange = (text as NSString).rangeOfComposedCharacterSequences(for: stringRange)
            // Now you can create the short string
            let shortString = (text as NSString).substring(with: stringRange)
            let newText = NSMutableString()
            newText.append(oldString)
            newText.insert(shortString, at: range.location)
            textView.text = newText as String

            self.showCharactersNumberError()
            self.textViewDidChange(textView)
            return false
        }
        return true
    }
    
    override func textViewDidEndEditing(_ textView: UITextView) {
        super.textViewDidEndEditing(textView)
        self.fireSendStopTypingIfNecessary()
    }

    @objc func fireSendStopTypingIfNecessary() -> Void {
        if let timer = self.typingTimer {
            timer.invalidate()
        }
        self.typingTimer = nil
        self.sendStopTyping()
    }

    func sendBeginTyping() -> Void {
        self.dialog.sendUserIsTyping()
    }

    func sendStopTyping() -> Void {
        self.dialog.sendUserStoppedTyping()
    }
    
    // MARK : QMChatConnectionDelegate
    func refreshAndReadMessages() {
         AlertUtil.sharedInstnace.showAlertMessage(title: "", subTitle: "Loading Messages", viewController: self)
        self.loadMessages()
        if let messagesToRead = self.unreadMessages {
            self.readMessages(messages: messagesToRead)
        }
        self.unreadMessages = nil
    }
    
    func chatServiceChatDidConnect(_ chatService: QMChatService) {
        self.refreshAndReadMessages()
    }
    
    func chatServiceChatDidReconnect(_ chatService: QMChatService) {
        
        self.refreshAndReadMessages()
    }
    
    func queueManager() -> QMDeferredQueueManager {
        return ServiceManager.instance().chatService.deferredQueueManager
    }
    
    func handleNotSentMessage(_ message: QBChatMessage,
                              forCell cell: QMChatCell!) {
        
        let alertController = UIAlertController(title: "", message: "SA_STR_MESSAGE_FAILED_TO_SEND".localized, preferredStyle:.actionSheet)
        
        let resend = UIAlertAction(title: "SA_STR_TRY_AGAIN_MESSAGE".localized, style: .default) { (action) in
            self.queueManager().perfromDefferedAction(for: message, withCompletion: nil)
        }
        alertController.addAction(resend)
        
        let delete = UIAlertAction(title: "SA_STR_DELETE_MESSAGE".localized, style: .destructive) { (action) in
            self.queueManager().remove(message)
            self.chatDataSource.delete(message)
        }
        alertController.addAction(delete)
        
        let cancelAction = UIAlertAction(title: "SA_STR_CANCEL".localized, style: .cancel) { (action) in
            
        }
        
        alertController.addAction(cancelAction)
        
        if alertController.popoverPresentationController != nil {
            self.view.endEditing(true)
            alertController.popoverPresentationController!.sourceView = cell.containerView
            alertController.popoverPresentationController!.sourceRect = cell.containerView.bounds
        }
        
        self.present(alertController, animated: true) {
        }
    }
}
