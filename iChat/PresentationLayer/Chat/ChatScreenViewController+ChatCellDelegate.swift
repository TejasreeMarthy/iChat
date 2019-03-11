//
//  ChatScreenViewController+ChatCellDelegate.swift
//  iChat
//
//  Created by Tejasree Marthy on 11/03/19.
//  Copyright © 2019 Tejasree Marthy. All rights reserved.
//
import SafariServices

extension ChatScreenViewController: QMChatCellDelegate {
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
}

