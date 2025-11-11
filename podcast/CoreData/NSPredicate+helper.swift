//
//  NSPredicate+helper.swift
//  podcast
//
//  Created by Matt Wittbrodt on 4/21/25.
//

import Foundation

extension NSPredicate {
    
    static let all = NSPredicate(format: "TRUEPREDICATE")
    static let none = NSPredicate(format: "FALSEPREDICATE")
    
}
