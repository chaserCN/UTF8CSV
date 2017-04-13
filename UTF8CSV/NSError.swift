//
//  NSError+s2r.swift
//  Spot2R
//
//  Created by Nicolas on 4/10/16.
//  Copyright © 2016 Mobile Labs. All rights reserved.
//

import Foundation

let kCSVErrorDomain = "CSVErrorDomain"

extension NSError {
    internal convenience init(message: String) {
        self.init(domain: kCSVErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

extension NSError {
    struct csv {
        static var failedToParse: NSError {
            return NSError(message: NSLocalizedString("Failed to parse CSV file", comment: ""))
        }
        
        static func failedToDecode(strings: [String]) -> NSError {
            return NSError(message: NSLocalizedString("Failed to decode CSV values: \(strings)", comment: ""))
        }
    }
}