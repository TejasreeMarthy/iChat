//
//  AlertUtil.swift
//  iChat
//
//  Created by Tejasree Marthy on 07/03/19.
//  Copyright © 2019 Tejasree Marthy. All rights reserved.
//

import UIKit

class AlertUtil {

    static let sharedInstnace = AlertUtil()

    private  init() { 
    }
    // Displays alert with title and subtitle
    func showAlertMessage(title: String, subTitle: String, viewController: UIViewController) {
        let alert = UIAlertController(title: title, message: subTitle, preferredStyle: .alert)
        let alertOKAction = UIAlertAction(title: "OK", style: .default) { (action) in
        }
        alert.addAction(alertOKAction)
        viewController.present(alert, animated: true, completion: nil)
    }
}
