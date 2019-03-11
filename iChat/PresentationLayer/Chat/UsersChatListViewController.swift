//
//  UsersChatListViewController.swift
//  iChat
//
//  Created by Tejasree Marthy on 07/03/19.
//  Copyright © 2019 Tejasree Marthy. All rights reserved.
//

import UIKit

class UsersChatListViewController: UIViewController, QMChatServiceDelegate, QMChatConnectionDelegate, QMAuthServiceDelegate {

    private var didEnterBackgroundDate: NSDate?
    private var observer: NSObjectProtocol?

    var users : [QBUUser] = []

    @IBOutlet weak var chatListTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initalizeData()
    }

    func initalizeData() {
        self.navigationItem.title =  "Chats"
        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItem = self.logoutButton()

        ActivityIndicatorUtil.sharedInstnace.addActivityIndicator(viewController: self)

        //Registering nib file
        let chatNib = UINib.init(nibName: "UserChatListTableViewCell", bundle: nil)
        self.chatListTableView.register(chatNib, forCellReuseIdentifier: "UserChatListTableViewCell")

        self.chatListTableView.tableFooterView = UIView()
        self.checkUsersPresentInCache()
        
    }

    // MARK: - Actions
    func logoutButton() -> UIBarButtonItem {
        let logoutButton = UIBarButtonItem(title: "Logout",
                                        style: UIBarButtonItem.Style.plain,
                                        target: self, action: #selector(logoutButtonClicked))
        return logoutButton
    }

    @objc func logoutButtonClicked() {
        if !QBChat.instance.isConnected {
            AlertUtil.sharedInstnace.showAlertMessage(title: "",
                                                subTitle: "Error",
                                                viewController: self)
            return
        }
        self.logoutConfirmation()
    }

    // MARK: Check Cache data
    func checkUsersPresentInCache(){
        let users = ServiceManager.instance().usersService.usersMemoryStorage.unsortedUsers()
        if users.count > 0 {
            guard let users = ServiceManager.instance().sortedUsers() else {
                print("No cached users")
                return
            }
            self.setupUsers(users: users)
        }
        else {
            self.fetchUsersFromServer()
        }
    }

    // MARK: Service calls
    func fetchUsersFromServer() {
        ActivityIndicatorUtil.sharedInstnace.showActivityIndicator(viewController: self)
        self.loadUsersWithCompletion { (users) in
            guard let unwrappedUsers = users else {
                ActivityIndicatorUtil.sharedInstnace.hideActivityIndicator(viewController: self)
                AlertUtil.sharedInstnace.showAlertMessage(title: "",
                                                    subTitle: "No users downloaded",
                                                    viewController: self)
                return
            }
            ActivityIndicatorUtil.sharedInstnace.hideActivityIndicator(viewController: self)
            self.setupUsers(users: unwrappedUsers)
        }
    }

    func loadUsersWithCompletion(completion: @escaping ((_ results: [QBUUser]?)->Void)) {
        let responsePage: QBGeneralResponsePage = QBGeneralResponsePage(currentPage: 0, perPage: 100)
        QBRequest.users(for: responsePage, successBlock: { (response, responsePage, users) in
            print("users received: \(users)")
            completion(users)
        }) { (response) in
            print("error with users response: \(String(describing: response.error))")
        }
    }

    func setupUsers(users: [QBUUser]) {
        self.users = users.filter { $0.email != ServiceManager.instance().currentUser.email }
        self.chatListTableView.reloadData()
    }

    // create chat dailogue for selected user
    func createChatDailogue(user : QBUUser) {
        ServiceManager.instance().chatService.createPrivateChatDialog(withOpponent: user, completion: { (response, chatDialog) in
            let chatScreenViewController = self.storyboard?.instantiateViewController(withIdentifier: "ChatScreenViewController") as! ChatScreenViewController
            chatScreenViewController.dialog = chatDialog
            chatScreenViewController.user = user
            self.navigationController?.pushViewController(chatScreenViewController, animated: true)
        })
    }

    func logoutConfirmation() {
        let alert = UIAlertController(title: "",
                                   message: "Are you sure you want to logout",
                                   preferredStyle: .alert)
        let alertCancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
        }
        let alertOKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            self.logoutCurrentUser()
        }
        alert.addAction(alertCancelAction)
        alert.addAction(alertOKAction)
        self.present(alert, animated: true, completion: nil)
    }

    //logout user
    func logoutCurrentUser() {
        ServiceManager.instance().logoutUserWithCompletion { [weak self] (boolValue) -> () in
            guard let strongSelf = self else { return }
            if boolValue {
                NotificationCenter.default.removeObserver(strongSelf)
                if strongSelf.observer != nil {
                    NotificationCenter.default.removeObserver(strongSelf.observer!)
                    strongSelf.observer = nil
                }
                ServiceManager.instance().chatService.removeDelegate(strongSelf)
                ServiceManager.instance().authService.remove(strongSelf)
                ServiceManager.instance().lastActivityDate = nil;                
                let _ = strongSelf.navigationController?.popToRootViewController(animated: true)
                AlertUtil.sharedInstnace.showAlertMessage(title: "",
                                                     subTitle: "Successfully logged out".localized,
                                                     viewController:self!)
            }
        }
    }
   
}
// MARK: UITableView Methods
extension UsersChatListViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count;
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserChatListTableViewCell") as! UserChatListTableViewCell
        let user = self.users[indexPath.row]
        cell.loadCellData(user: user)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let user = self.users[indexPath.row]
        self.createChatDailogue(user: user)
    }

}

