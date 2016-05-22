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
    private enum ParseResult: Int {
        case AppendByte
        case FinishValue
        case FinishLine
        case Skip
        case Fail
    }
    
    private enum State: Int {
        case StartOfValue
        case Parsing
        case InnerQuotesWhileParsing
        case ParsingQuotes
        case InnerQuotesWhileParsingQuotes
        case Fail
    }
    
    private var state: State = .StartOfValue
    private var keepAppending = 0
    private var outterError: ErrorType?

    // if we dont clean array every time, parsing 90.000 lines drops from 7 seconds to 3 on iPad2
    private var strings = [String]()
    private var currentStringOffset = 0
    
    private let delimiter: UInt8

    private var buffer = [UInt8](count: 1024, repeatedValue: 0)
    private let bufferPtr: UnsafeMutablePointer<UInt8>
    private var currentBufferOffset = 0
    
    public init(delimiter: UInt8 = semicolon) {
        self.delimiter = delimiter
        bufferPtr = UnsafeMutablePointer<UInt8>(self.buffer)
    }
    
    public func parseData(data: NSData?, processor: [String] throws -> ()) throws {
        guard let data = data else {
            try processEOF(processor)
            return
        }
        
        data.enumerateByteRangesUsingBlock {pointer, range, _ in
            self.parseDataChunk(pointer, length: range.length, processor: processor)
        }
        
        if state == .Fail {
            throw outterError ?? NSError.csv.failedToParse
        }
    }
    
    private func parseDataChunk(dataPointer: UnsafePointer<Void>, length: Int, processor: [String] throws -> ()) {
        let bufferPointer = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(dataPointer), count: length)
        
        var index = -1
        
        for byte in bufferPointer {
            index += 1

            if self.keepAppending > 0 {
                appendByte(byte)
                self.keepAppending -= 1
                continue
            }
            
            let times = self.timesToIgnoreProcessingForUTF8(byte)
            if times > 0 {
                appendByte(byte)
                self.keepAppending = times
                continue
            }
            
            switch self.processByte(byte) {
            case .AppendByte:
                appendByte(byte)
            
            case.Skip:
                break
                
            case .FinishValue:
                appendValueFromBuffer()
            
            case .FinishLine:
                appendValueFromBuffer()
                finishLine()

                do {
                    try processor(strings)
                } catch (let error) {
                    outterError = error
                    state = .Fail
                }
                
            case .Fail:
                finishLine()
                break
            }
        }
    }
    
    private func appendByte(byte: UInt8) {
        if currentBufferOffset >= buffer.count {
            let extraSpace = [UInt8](count: 1024, repeatedValue: 0)
            buffer.appendContentsOf(extraSpace)
        }
        
        bufferPtr[currentBufferOffset] = byte
        currentBufferOffset += 1
    }
    
    private func appendValueFromBuffer() {
        guard let s = String(bytesNoCopy: bufferPtr, length: currentBufferOffset, encoding: NSUTF8StringEncoding, freeWhenDone: false) else {
            state = .Fail
            return
        }
        
        if currentStringOffset >= strings.count {
            strings.append("")
        }
        
        strings[currentStringOffset] = s
        currentStringOffset += 1
        
        currentBufferOffset = 0
    }
    
    private func finishLine() {
        if currentStringOffset != strings.count {
            strings.removeLast(strings.count - currentStringOffset)
        }
        
        currentBufferOffset = 0
        currentStringOffset = 0
    }
    
    private func processEOF(processor: [String] throws -> ()) throws {
        if currentBufferOffset <= 0 {
            return
        }
        
        appendValueFromBuffer()
        finishLine()
        
        try processor(strings)
    }
}
    
extension CSVDataParser {
    private func timesToIgnoreProcessingForUTF8(byte: UInt8) -> Int {
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
    private func processByte(byte: UInt8) -> ParseResult {
        if state == .StartOfValue {
            if byte == quote {
                state = .ParsingQuotes
                return .Skip
            }

            if byte == delimiter {
                return .FinishValue
            }
            
            if byte == newline {
                return .FinishLine
            }
            
            state = .Parsing
            return .AppendByte
        }
        
        if state == .Parsing {
            if byte == quote {
                state = .InnerQuotesWhileParsing
                return .Skip
            }
            
            if byte == delimiter {
                state = .StartOfValue
                return .FinishValue
            }
            
            if byte == newline {
                state = .StartOfValue
                return .FinishLine
            }
            
            return .AppendByte
        }

        if state == .InnerQuotesWhileParsing {
            if byte == quote {
                state = .Parsing
                return .AppendByte
            }

            state = .Fail
            return .Fail
        }

        if state == .ParsingQuotes {
            if byte == quote {
                state = .InnerQuotesWhileParsingQuotes
                return .Skip
            }
            
            return .AppendByte
        }
        
        if state == .InnerQuotesWhileParsingQuotes {
            if byte == quote {
                state = .ParsingQuotes
                return .AppendByte
            }
            
            if byte == delimiter {
                state = .StartOfValue
                return .FinishValue
            }
            
            if byte == newline {
                state = .StartOfValue
                return .FinishLine
            }
            
            state = .Fail
            return .Fail
        }
        
        return .Fail
    }
}