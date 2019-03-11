//
//  String+Localized.swift
//  iChat
//
//  Created by Tejasree Marthy on 07/03/19.
//  Copyright © 2019 Tejasree Marthy. All rights reserved.
//

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }

    var stringlength: Int {
        return (self as NSString).length
    }
}
