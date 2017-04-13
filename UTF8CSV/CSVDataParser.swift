//
//  RSVParser.swift
//  CSVPerformance
//
//  Created by Nicolas on 5/20/16.
//  Copyright © 2016 Mobile Labs. All rights reserved.
//

import Foundation

private let quote: UInt8 = 34
private let semicolon: UInt8 = 59
private let newline: UInt8 = 10

public final class CSVDataParser {
    fileprivate enum ParseResult: Int {
        case appendByte
        case finishValue
        case finishLine
        case skip
        case fail
    }
    
    fileprivate enum State: Int {
        case startOfValue
        case parsing
        case innerQuotesWhileParsing
        case parsingQuotes
        case innerQuotesWhileParsingQuotes
        case fail
    }
    
    fileprivate var state: State = .startOfValue
    fileprivate var keepAppending = 0
    fileprivate var error: Error?

    // if we dont clean array every time, parsing 90.000 lines drops from 7 seconds to 3 on iPad2
    fileprivate var strings = [String]()
    fileprivate var currentStringOffset = 0
    
    fileprivate let delimiter: UInt8

    fileprivate var buffer = [UInt8](repeating: 0, count: 1024)
    fileprivate let bufferPtr: UnsafeMutablePointer<UInt8>
    fileprivate var currentBufferOffset = 0
    
    public init(delimiter: UInt8 = semicolon) {
        self.delimiter = delimiter
        bufferPtr = UnsafeMutablePointer<UInt8>(mutating: self.buffer)
    }
    
    public func parse(_ data: Data?, using processLineString: @escaping ([String]) throws -> ()) throws {
        guard let data = data else {
            try processEOF(using: processLineString)
            return
        }
        
        data.enumerateBytes {pointer, range, _ in
            self.parseData(at: pointer, using: processLineString)
        }
        
        if state == .fail {
            throw error ?? NSError.csv.failedToParse
        }
    }
    
    fileprivate func parseData(at bufferPointer: UnsafeBufferPointer<UInt8>, using processLineString: ([String]) throws -> ()) {
        var index = -1
        
        for byte in bufferPointer {
            index += 1

            if self.keepAppending > 0 {
                append(byte)
                self.keepAppending -= 1
                continue
            }
            
            let times = self.timesToIgnoreProcessing(forUTF8StartingWith: byte)
            if times > 0 {
                append(byte)
                self.keepAppending = times
                continue
            }
            
            switch self.process(byte) {
            case .appendByte:
                append(byte)
            
            case.skip:
                break
                
            case .finishValue:
                appendValueFromBuffer()
            
            case .finishLine:
                appendValueFromBuffer()
                finishLine()

                do {
                    try processLineString(strings)
                } catch (let error) {
                    self.error = error
                    state = .fail
                }
                
            case .fail:
                finishLine()
                break
            }
        }
    }
    
    fileprivate func append(_ byte: UInt8) {
        if currentBufferOffset >= buffer.count {
            let extraSpace = [UInt8](repeating: 0, count: 1024)
            buffer.append(contentsOf: extraSpace)
        }
        
        bufferPtr[currentBufferOffset] = byte
        currentBufferOffset += 1
    }
    
    fileprivate func appendValueFromBuffer() {
        guard let s = String(bytesNoCopy: bufferPtr, length: currentBufferOffset, encoding: String.Encoding.utf8, freeWhenDone: false) else {
            error = NSError(message: NSLocalizedString("Failed to create a string while parsing CSV", comment: "UTF8CSV"))
            state = .fail
            return
        }
        
        if currentStringOffset >= strings.count {
            strings.append("")
        }
        
        strings[currentStringOffset] = s
        currentStringOffset += 1
        
        currentBufferOffset = 0
    }
    
    fileprivate func finishLine() {
        if currentStringOffset != strings.count {
            strings.removeLast(strings.count - currentStringOffset)
        }
        
        currentBufferOffset = 0
        currentStringOffset = 0
    }
    
    fileprivate func processEOF(using processor: ([String]) throws -> ()) throws {
        if currentBufferOffset <= 0 {
            return
        }
        
        appendValueFromBuffer()
        finishLine()
        
        try processor(strings)
    }
}
    
extension CSVDataParser {
    fileprivate func timesToIgnoreProcessing(forUTF8StartingWith byte: UInt8) -> Int {
        if byte & 0b1000_0000 == 0 {
            return 0
        }
        
        if byte & 0b1110_0000 == 0b1100_0000 {
            return 1
        }
        
        if byte & 0b1111_0000 == 0b1110_0000 {
            return 2
        }
        
        return 3
    }
}

extension CSVDataParser {
    fileprivate func process(_ byte: UInt8) -> ParseResult {
        if state == .startOfValue {
            if byte == quote {
                state = .parsingQuotes
                return .skip
            }

            if byte == delimiter {
                return .finishValue
            }
            
            if byte == newline {
                return .finishLine
            }
            
            state = .parsing
            return .appendByte
        }
        
        if state == .parsing {
            if byte == quote {
                state = .innerQuotesWhileParsing
                return .skip
            }
            
            if byte == delimiter {
                state = .startOfValue
                return .finishValue
            }
            
            if byte == newline {
                state = .startOfValue
                return .finishLine
            }
            
            return .appendByte
        }

        if state == .innerQuotesWhileParsing {
            if byte == quote {
                state = .parsing
                return .appendByte
            }

            state = .fail
            return .fail
        }

        if state == .parsingQuotes {
            if byte == quote {
                state = .innerQuotesWhileParsingQuotes
                return .skip
            }
            
            return .appendByte
        }
        
        if state == .innerQuotesWhileParsingQuotes {
            if byte == quote {
                state = .parsingQuotes
                return .appendByte
            }
            
            if byte == delimiter {
                state = .startOfValue
                return .finishValue
            }
            
            if byte == newline {
                state = .startOfValue
                return .finishLine
            }
            
            state = .fail
            return .fail
        }
        
        return .fail
    }
}
