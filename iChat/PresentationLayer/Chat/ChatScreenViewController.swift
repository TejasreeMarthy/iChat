//
//  ChatScreenViewController.swift
//  iChat
//
//  Created by Tejasree Marthy on 07/03/19.
//  Copyright © 2019 Tejasree Marthy. All rights reserved.
//

import UIKit
import CoreTelephony

class ChatScreenViewController: BaseChatScreenViewController, UINavigationControllerDelegate {

    let maxCharactersNumber = Constants.limitAndInterVel.charactersLimit
    private var willResignActiveBlock: AnyObject?
    private var failedDownloads: Set<String> = []
    private var typingTimer: Timer?
    private var unreadMessages: [QBChatMessage]?

    var user: QBUUser = QBUUser()

    var messageTimeDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // top layout inset for collectionView
        self.topContentAdditionalInset = self.navigationController!.navigationBar.frame.size.height + UIApplication.shared.statusBarFrame.size.height;
        view.backgroundColor = ColorUtil.ChatScreen.ChatScreenBackground
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

    func loadMessages() {
        // Retrieving messages for chat dialog ID.
        guard let currentDialogID = self.dialog.id else {
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

    func showCharactersNumberError() {
        let subtitle = String(format: "The character limit is %lu.", maxCharactersNumber)
        AlertUtil.sharedInstnace.showAlertMessage(title: "Error",
                                             subTitle: subtitle,
                                             viewController: self)
    }

    func statusStringFromMessage(message: QBChatMessage) -> String {
        var statusString = ""
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
            return QMChatIncomingCell.self
        }
        else {
            return QMChatOutgoingCell.self
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

    //Creates top label attributed string from QBChatMessage
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
    
    // Creates bottom label attributed string from QBChatMessage using self.statusStringFromMessage
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

    // MARK: UITextViewDelegate
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
    }

    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Prevent crashing undo bug
        let currentCharacterCount = textView.text?.count ?? 0
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
            if currentCharacterCount >= maxCharactersNumber && text.count > 0 {
                self.showCharactersNumberError()
                return false
            }
            let newLength = currentCharacterCount + text.count - range.length
            if  newLength <= maxCharactersNumber || text.count == 0 {
                return true
            }
            let oldString = textView.text ?? ""
            let numberOfSymbolsToCut = maxCharactersNumber - oldString.count
            var stringRange = NSMakeRange(0, min(text.count, numberOfSymbolsToCut))
            // adjust the range to include dependent chars
            stringRange = (text as NSString).rangeOfComposedCharacterSequences(for: stringRange)
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
