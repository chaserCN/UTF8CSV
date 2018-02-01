//
//  RSVCSVDecoder.swift
//  Spot2R
//
//  Created by Nicolas on 4/23/16.
//  Copyright © 2016 Mobile Labs. All rights reserved.
//

import Foundation

public protocol CSVDecodable {
    init(values: [String], serverTimeZone: TimeZone) throws
    init(decoder: CSVDecoder, serverTimeZone: TimeZone) throws
    init(decoder: CSVDecoder) throws
}

extension CSVDecodable {
    public init(values: [String], serverTimeZone: TimeZone) throws {
        let decoder = CSVDecoder(strings: values)
        try self.init(decoder: decoder, serverTimeZone: serverTimeZone)
    }

    public init(decoder: CSVDecoder, serverTimeZone: TimeZone) throws {
        try self.init(decoder: decoder)
    }
}

public protocol CSVDecodableZone: CSVDecodable {}

extension CSVDecodableZone {
    //CSVDecodableZone has to implement init(values: [String], serverTimeZone: TimeZone)
    //otherwise this will create a loop between inits.
    //this is a work around. need to figure out a better way latter
    public init(decoder: CSVDecoder) throws {
        try self.init(decoder: decoder, serverTimeZone: TimeZone.current)
    }
}

public protocol CSVStringRepresentable {
    static func fromString(_ string: String) -> Self?
}

public protocol CSVIntRepresentable {
    static func fromInt(_ i: Int) -> Self?
}

open class CSVDecoder {
    fileprivate var strings: [String]
    fileprivate var enumerator: EnumeratedIterator<IndexingIterator<Array<String>>>
    
    public init(strings: [String]) {
        self.strings = strings
        self.enumerator = self.strings.enumerated().makeIterator()
    }

    public init() {
        self.strings = []
        self.enumerator = self.strings.enumerated().makeIterator()
    }
    
    public func reset(with strings: [String]) {
        self.strings = strings
        self.enumerator = self.strings.enumerated().makeIterator()
    }

    // MARK:

    open func decodeNext() throws -> Int64? {
        return try decodeNext {Int64($0)}
    }
    
    open func decodeNext() throws -> Int64 {
        return try unwrapOptional(try decodeNext())
    }
    
    open func decodeNext() throws -> Int32? {
        return try decodeNext {Int32($0)}
    }
    
    open func decodeNext() throws -> Int32 {
        return try unwrapOptional(try decodeNext())
    }

    open func decodeNext() throws -> Int? {
        return try decodeNext {Int($0)}
    }

    open func decodeNext() throws -> Int {
        return try unwrapOptional(try decodeNext())
    }

    open func decodeNext() throws -> Double? {
        return try decodeNext {Double($0)}
    }

    open func decodeNext() throws -> Double {
        return try unwrapOptional(try decodeNext())
    }
    
    open func decodeNext() throws -> Bool? {
        return try decodeNext {NSString(string: $0).boolValue}
    }

    open func decodeNext() throws -> Bool {
        return try unwrapOptional(try decodeNext())
    }

    open func decodeNext() throws -> String? {
        return try next()
    }

    open func decodeNext() throws -> String {
        return try next()
    }

    open func decodeNext() throws -> NSDecimalNumber? {
        return try decodeNext {$0.toDelocalizedDecimalNumber}
    }

    open func decodeNext() throws -> NSDecimalNumber {
        return try unwrapOptional(try decodeNext())
    }

    open func decodeNext<T: CSVStringRepresentable>() throws -> T? {
        return try decodeNext {T.fromString($0)}
    }

    open func decodeNext<T: CSVStringRepresentable>() throws -> T {
        return try unwrapOptional(try decodeNext())
    }

    open func decodeNext<T: CSVIntRepresentable>() throws -> T? {
        return try decodeNext {
            if let i = Int($0) {
                return T.fromInt(i)
            }
            return nil
        }!
    }

    open func decodeNext<T: CSVIntRepresentable>() throws -> T {
        return try unwrapOptional(try decodeNext())
    }

    open func decodeNext(format: String) throws -> Date {
        return try unwrapOptional(try decodeNext(format: format))
    }
    
    open func decodeNext(formatter: DateFormatter) throws -> Date {
        return try unwrapOptional(try decodeNext(formatter: formatter))
    }
    
    open func decodeNext(formatter: DateFormatter) throws -> Date? {
        return try decodeNext {formatter.date(from: $0)}
    }

    open func decodeNext(format: String) throws -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return try decodeNext(formatter: formatter)
    }

    // MARK:
    // open for custom extensions

    open func decodeNext<T>(_ converter: (String) -> T?) throws -> T? {
        let string = try next()
        
        if string.isEmpty {
            return nil
        }
        
        guard let t = converter(string) else {
            throw NSError.csv.failedToDecode(strings)
        }
        
        return t
    }

    open func unwrapOptional<T>(_ t: T?) throws -> T {
        guard let t = t else {
            throw NSError.csv.failedToDecode(strings)
        }
        return t
    }
    
    // MARK:
    
    private func next() throws -> String {
        guard let s = enumerator.next() else {
            throw NSError.csv.failedToDecode(strings)
        }
        return s.element
    }
}
