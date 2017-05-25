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

// utf8ToString is from Apple's protobuffer parser.
// it's even slightly faster than String(bytesNoCopy:length:encoding:freeWhenDone:)
// see StringUtils.swift in https://github.com/apple/swift-protobuf

internal func utf8ToString(bytes: UnsafePointer<UInt8>, count: Int) -> String? {
    if count == 0 {
        return String()
    }

    let s = NSString(bytes: bytes, length: count, encoding: String.Encoding.utf8.rawValue)
    if let s = s {
        return String._unconditionallyBridgeFromObjectiveC(s)
    }

    return nil
}
