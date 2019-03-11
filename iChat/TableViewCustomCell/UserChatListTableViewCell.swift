//
//  UserChatListTableViewCell.swift
//  iChat
//
//  Created by Tejasree Marthy on 07/03/19.
//  Copyright © 2019 Tejasree Marthy. All rights reserved.
//

import UIKit

class UserChatListTableViewCell: UITableViewCell {

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userOnlineStatus: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func loadCellData(user: QBUUser) {
        self.userName.text = user.fullName
        self.userOnlineStatus.text = self.showOnlineOrOfflineStatus(user: user)
        if self.showOnlineOrOfflineStatus(user: user) == Constants.UserChatStatus.Offline {
            self.userOnlineStatus.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        }
    }

    func showOnlineOrOfflineStatus(user : QBUUser) -> String{
        let currentTimeInterval = Int(Date().timeIntervalSince1970)
        let userLastRequestAtTimeInterval = Int(user.lastRequestAt?.timeIntervalSince1970 ?? 0)
        // if user didn't do anything last 1 minute (60 seconds)
        if (currentTimeInterval - userLastRequestAtTimeInterval) > 60 {
            return Constants.UserChatStatus.Offline
        }
        return Constants.UserChatStatus.Online
    }
    
}
