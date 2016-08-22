//
//  RSVCSVDecoder.swift
//  Spot2R
//
//  Created by Nicolas on 4/23/16.
//  Copyright © 2016 Mobile Labs. All rights reserved.
//

import Foundation

public protocol CSVDecodable {
    init(values: [String]) throws
    init(decoder: CSVDecoder) throws
}

extension CSVDecodable {
    public init(values: [String]) throws {
        let decoder = CSVDecoder(strings: values)
        try self.init(decoder: decoder)
    }
}

public protocol CSVStringRepresentable {
    static func fromString(string: String) -> Self?
}

public protocol CSVIntRepresentable {
    static func fromInt(i: Int) -> Self?
}

public class CSVDecoder {
    private let strings: [String]
    private var enumerator: EnumerateGenerator<IndexingGenerator<Array<String>>>
    
    public init(strings: [String]) {
        self.strings = strings
        self.enumerator = self.strings.enumerate().generate()
    }

    // MARK:

    public func decodeNext() throws -> Int? {
        return try decodeNext {Int($0)}
    }

    public func decodeNext() throws -> Int {
        return try unwrapOptional(try decodeNext())
    }

    public func decodeNext() throws -> Double? {
        return try decodeNext {Double($0)}
    }

    public func decodeNext() throws -> Double {
        return try unwrapOptional(try decodeNext())
    }
    
    public func decodeNext() throws -> Bool? {
        return try decodeNext {NSString(string: $0).boolValue}
    }

    public func decodeNext() throws -> Bool {
        return try unwrapOptional(try decodeNext())
    }

    public func decodeNext() throws -> String? {
        return try next()
    }

    public func decodeNext() throws -> String {
        return try next()
    }

    public func decodeNext() throws -> NSDecimalNumber? {
        return try decodeNext {NSDecimalNumber(string: $0)}
    }

    public func decodeNext() throws -> NSDecimalNumber {
        return try unwrapOptional(try decodeNext())
    }

    public func decodeNext<T: CSVStringRepresentable>() throws -> T? {
        return try decodeNext {T.fromString($0)}
    }

    public func decodeNext<T: CSVStringRepresentable>() throws -> T {
        return try unwrapOptional(try decodeNext())
    }

    public func decodeNext<T: CSVIntRepresentable>() throws -> T? {
        return try decodeNext {
            if let i = Int($0) {
                return T.fromInt(i)
            }
            return nil
        }!
    }

    public func decodeNext<T: CSVIntRepresentable>() throws -> T {
        return try unwrapOptional(try decodeNext())
    }
    
    public func decodeNext(format format: String) throws -> NSDate? {
        let formatter = NSDateFormatter()
        formatter.dateFormat = format
        return try decodeNext {formatter.dateFromString($0)}
    }

    public func decodeNext(format format: String) throws -> NSDate {
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
