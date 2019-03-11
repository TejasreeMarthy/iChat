//
//  LoginViewController.swift
//  iChat
//
//  Created by Tejasree Marthy on 07/03/19.
//  Copyright © 2019 Tejasree Marthy. All rights reserved.
//

import UIKit
import Quickblox

class LoginViewController: UIViewController {

    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var password: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
         ActivityIndicatorUtil.sharedInstnace.addActivityIndicator(viewController: self)
        // Do any additional setup after loading the view.
    }

    // MARK: Login Service
    func loginWithUSerDetails() {
        var currentUser:QBUUser = ServiceManager.instance().currentUser
        if (currentUser == nil) {
            currentUser = QBUUser()
        }
        currentUser.login = userName.text
        currentUser.password = password.text
        ActivityIndicatorUtil.sharedInstnace.showActivityIndicator(viewController: self)
        ServiceManager.instance().logIn(with: currentUser, completion: {
            [weak self] (success,  errorMessage) -> Void in
            
            guard success else {
            ActivityIndicatorUtil.sharedInstnace.hideActivityIndicator(viewController: self!)
                AlertUtil.sharedInstnace.showAlertMessage(title: "Error", subTitle: errorMessage ?? "", viewController: self!)
                return
            }
            ActivityIndicatorUtil.sharedInstnace.hideActivityIndicator(viewController: self!)
            self?.navigateToChatListViewController()
            
        })
    }

    @IBAction func LoginButtonClick(_ sender: Any) {
        if userName.text?.isEmpty ?? true {
          AlertUtil.sharedInstnace.showAlertMessage(title: "", subTitle: "Please enter username", viewController: self)
        }
        else  if password.text?.isEmpty ?? true {
          AlertUtil.sharedInstnace.showAlertMessage(title: "", subTitle: "Please enter password", viewController: self)
        }
        else {
          self.loginWithUSerDetails()
        }
    }

    func navigateToChatListViewController() {
        let chatListViewController = self.storyboard?.instantiateViewController(withIdentifier: "UsersChatListViewController") as! UsersChatListViewController
        self.navigationController?.pushViewController(chatListViewController, animated: true)
    }
}
