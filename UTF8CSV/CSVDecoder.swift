//
//  RSVCSVDecoder.swift
//  Spot2R
//
//  Created by Nicolas on 4/23/16.
//  Copyright © 2016 Mobile Labs. All rights reserved.
//

import Foundation

protocol CSVDecodable {
    init(values: [String]) throws
    init(decoder: CSVDecoder) throws
}

extension CSVDecodable {
    init(values: [String]) throws {
        let decoder = CSVDecoder(strings: values)
        try self.init(decoder: decoder)
    }
}

protocol CSVStringRepresentable {
    static func fromString(string: String) -> Self?
}

protocol CSVIntRepresentable {
    static func fromInt(i: Int) -> Self?
}

class CSVDecoder {
    private let strings: [String]
    private var enumerator: EnumerateGenerator<IndexingGenerator<Array<String>>>
    
    init(strings: [String]) {
        self.strings = strings
        self.enumerator = self.strings.enumerate().generate()
    }

    // MARK:

    func decodeNext() throws -> Int? {
        return try decodeNext {Int($0)}
    }

    func decodeNext() throws -> Int {
        return try unwrapOptional(try decodeNext())
    }

    func decodeNext() throws -> Double? {
        return try decodeNext {Double($0)}
    }

    func decodeNext() throws -> Double {
        return try unwrapOptional(try decodeNext())
    }
    
    func decodeNext() throws -> Bool? {
        return try decodeNext {NSString(string: $0).boolValue}
    }

    func decodeNext() throws -> Bool {
        return try unwrapOptional(try decodeNext())
    }

    func decodeNext() throws -> String? {
        return try next()
    }

    func decodeNext() throws -> String {
        return try next()
    }

    func decodeNext() throws -> NSDecimalNumber? {
        return try decodeNext {NSDecimalNumber(string: $0)}
    }

    func decodeNext() throws -> NSDecimalNumber {
        return try unwrapOptional(try decodeNext())
    }

    func decodeNext<T: CSVStringRepresentable>() throws -> T? {
        return try decodeNext {T.fromString($0)}
    }

    func decodeNext<T: CSVStringRepresentable>() throws -> T {
        return try unwrapOptional(try decodeNext())
    }

    func decodeNext<T: CSVIntRepresentable>() throws -> T? {
        return try decodeNext {
            if let i = Int($0) {
                return T.fromInt(i)
            }
            return nil
        }!
    }

    func decodeNext<T: CSVIntRepresentable>() throws -> T {
        return try unwrapOptional(try decodeNext())
    }
    
    func decodeNext(format format: String) throws -> NSDate? {
        let formatter = NSDateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        
        return try decodeNext {formatter.dateFromString($0)}
    }

    func decodeNext(format format: String) throws -> NSDate {
        return try unwrapOptional(try decodeNext(format: format))
    }

    // MARK:
    
    private func decodeNext<T>(converter: String -> T?) throws -> T? {
        let string = try next()
        
        if string.isEmpty {
            return nil
        }
        
        guard let t = converter(string) else {
            throw NSError.csv.failedToDecode(strings)
        }
        
        return t
    }
    
    private func next() throws -> String {
        guard let s = enumerator.next() else {
            throw NSError.csv.failedToDecode(strings)
        }
        return s.element
    }

    private func unwrapOptional<T>(t: T?) throws -> T {
        guard let t = t else {
            throw NSError.csv.failedToDecode(strings)
        }
        return t
    }
}
