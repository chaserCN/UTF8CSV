//
//  CSVString.swift
//  UTF8CSV
//
//  Created by Nicolas on 9/5/16.
//  Copyright © 2016 Mobile Labs. All rights reserved.
//

import Foundation

extension String {
    var toDelocalizedDecimalNumber: NSDecimalNumber? {
        let number = NSDecimalNumber(string: self.replacingOccurrences(of: ",", with: "."),
                                     locale: nil)
        return number == NSDecimalNumber.notANumber ? nil : number
    }
}
