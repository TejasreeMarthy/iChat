//
//  Constants.swift
//  iChat
//
//  Created by Tejasree Marthy on 07/03/19.
//  Copyright © 2019 Tejasree Marthy. All rights reserved.
//

import UIKit

struct Constants {

    struct ActivityIndicatorKeys {
        static let DefaultHeight: CGFloat = 30.0
        static let DefaultWidth: CGFloat = 30.0
    }

    struct ApplicationKeys {
        static let kApplicationID: UInt =  73996
        static let kAccountKey = "KuiEZ-QfLJPzYGr14KKR"
        static let kAuthKey = "cEpHFMMjFYaJ5t8"
        static let kAuthSecret = "whSWwOjgV2528N2"
    }

    struct environment {
        
        static var QB_USERS_ENVIROMENT: String {
            
            #if DEBUG
            return "dev"
            #elseif QA
            return "qbqa"
            #else
            assert(false, "Not supported build configuration")
            return ""
            #endif
            
        }
    }

    struct limitAndInterVel {
        static let kChatPresenceTimeInterval:TimeInterval = 45
        static let kDialogsPageLimit:UInt = 100
        static let kMessageContainerWidthPadding:CGFloat = 40.0
        static let charactersLimit = 1024
    }
    
    struct UserChatStatus {
        static let Online: String = "Online"
        static let Offline: String = "Offline"
    }
}
