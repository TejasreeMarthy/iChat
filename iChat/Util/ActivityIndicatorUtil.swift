//
//  ActivityIndicatorUtil.swift
//  iChat
//
//  Created by Tejasree Marthy on 07/03/19.
//  Copyright © 2019 Tejasree Marthy. All rights reserved.
//

import UIKit

class ActivityIndicatorUtil: NSObject {
    
    static let sharedInstnace = ActivityIndicatorUtil()
    var activityIndicator: UIActivityIndicatorView!

    private override init() {
        
    }

    // Add ActivityIndicator to ViewController
    func addActivityIndicator(viewController: UIViewController) {
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x: (viewController.view.frame.size.width/2) - (ConstantsUtil.ActivityIndicatorKeys.DefaultWidth/2), y: (viewController.view.frame.size.height/2) - (ConstantsUtil.ActivityIndicatorKeys.DefaultHeight/2), width: ConstantsUtil.ActivityIndicatorKeys.DefaultWidth, height: ConstantsUtil.ActivityIndicatorKeys.DefaultHeight))
        activityIndicator.style = .whiteLarge
        activityIndicator.color = ColorUtil.ActivityIndicator.IndicatorColor
        activityIndicator.hidesWhenStopped = true
        viewController.view.addSubview(activityIndicator)
    }

    // Show Activity Indicator
    func showActivityIndicator(viewController: UIViewController) {
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        viewController.view.bringSubviewToFront(self.activityIndicator)
    }

    // Hide Activity Indicator
    func hideActivityIndicator(viewController: UIViewController) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        viewController.view.sendSubviewToBack(self.activityIndicator)
    }
}
