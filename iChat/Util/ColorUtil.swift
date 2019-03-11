//
//  ColorUtil.swift
//  iChat
//
//  Created by Tejasree Marthy on 07/03/19.
//  Copyright © 2019 Tejasree Marthy. All rights reserved.
//

import UIKit

class ColorUtil: NSObject {
    
    static let sharedInstance = ColorUtil()
    
    private override init() {
        
    }

    struct ActivityIndicator {
        static let IndicatorColor: UIColor = #colorLiteral(red: 0.5741485357, green: 0.5741624236, blue: 0.574154973, alpha: 1)
    }
    
    var randomColors = [
        UIColor(red: 0.992, green:0.510, blue:0.035, alpha:1.000),
        UIColor(red: 0.039, green:0.376, blue:1.000, alpha:1.000),
        UIColor(red: 0.984, green:0.000, blue:0.498, alpha:1.000),
        UIColor(red: 0.204, green:0.644, blue:0.251, alpha:1.000),
        UIColor(red: 0.580, green:0.012, blue:0.580, alpha:1.000),
        UIColor(red: 0.396, green:0.580, blue:0.773, alpha:1.000),
        UIColor(red: 0.765, green:0.000, blue:0.086, alpha:1.000),
        UIColor.red,
        UIColor(red: 0.786, green:0.706, blue:0.000, alpha:1.000),
        UIColor(red: 0.740, green:0.624, blue:0.797, alpha:1.000)
    ]
    
    struct ChatScreen {
         static let ChatScreenBackground = #colorLiteral(red: 0.9019607843, green: 0.9215686275, blue: 0.937254902, alpha: 1)
         static let ChatCellBackground = #colorLiteral(red: 0, green: 0.5607843137, blue: 0.5568627451, alpha: 1)
         static let ChatCellSendBackground = UIColor(red: 166.3/255.0, green: 171.5/255.0, blue: 171.8/255.0, alpha: 1.0)
         static let ChatCellNotSentBackground = UIColor(red: 254.6/255.0, green: 30.3/255.0, blue: 12.5/255.0, alpha: 1.0)
         static let ChatOutGoingCellBackground = UIColor(red: 10.0/255.0, green: 95.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }
}
