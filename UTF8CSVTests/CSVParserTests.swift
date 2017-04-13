//
//  UTF8CSVTests.swift
//  UTF8CSVTests
//
//  Created by Nicolas on 5/21/16.
//  Copyright © 2016 Mobile Labs. All rights reserved.
//

import XCTest
@testable import UTF8CSV

private extension String {
    func toData() -> NSData {
        return self.dataUsingEncoding(NSUTF8StringEncoding)!
    }
}

class CSVParserTests: XCTestCase {
    var parser: CSVDataParser!
    
    override func setUp() {
        super.setUp()
        parser = CSVDataParser()
    }
    
    func testParsingOfOneWord() {
        let line = "123"
        XCTAssert(parseText(line) == [["123"]])
    }
    
    func testParsingOfOneLine() {
        let line = "123;test;whatever\n"
        XCTAssert(parseText(line) == [["123", "test", "whatever"]])
    }
    
    func testParsingOfOneLineWithoutNewline() {
        let line = "123;test;whatever"
        XCTAssert(parseText(line) == [["123", "test", "whatever"]])
    }
    
    func testParsingOfMultipleLines() {
        let line = "123;ттт;whatever\n312;ภภภ;bbb\nqqq;www;eee"
        XCTAssert(parseText(line) == [["123", "ттт", "whatever"], ["312", "ภภภ", "bbb"], ["qqq", "www", "eee"]])
    }
    
    func testParsingOfQuotes() {
        let line = "123;\"test ; \"\" \n\n test\";whatever\nqqq"
        XCTAssert(parseText(line) == [["123", "test ; \" \n\n test", "whatever"], ["qqq"]])
    }
    
    func testParsingOfEmptyLines() {
        let line = "aaa;;bbb\nqqq;;\n;ccc"
        XCTAssert(parseText(line) == [["aaa", "", "bbb"], ["qqq", "", ""], ["", "ccc"]])
    }
    
    func testFailureOnUnmatchedDoubleQuotes() {
        let line = "\" \" \";t"
        //let line = "123;\"test \" \""
        XCTAssert(parseText(line) == [])
    }
    
    //MARK:
    
    func testParsingByteByByteInOrderToSimulateSplittedInternetResponses() {
        let text = "Їภ𝕿;𝕿𝕿𝕿;\"тестовая \"\"строка\"\"\"" //  Ї - 2 bytes, ภ - 3, 𝕿 - 4
        let result = chopAndParseText(text, step: 1)
        XCTAssert(result == [["Їภ𝕿", "𝕿𝕿𝕿", "тестовая \"строка\""]])
    }
    
    func testChunksOfThreeBytes() {
        let text = "Їภa𝕿;whatever;тест;\"перенос \n строки\"" //  Ї - 2 bytes, ภ - 3, 𝕿 - 4
        let result = chopAndParseText(text, step: 3)
        XCTAssert(result == [["Їภa𝕿", "whatever", "тест", "перенос \n строки"]])
    }
}

extension CSVParserTests {
    func parseText(text: String) -> [[String]] {
        var result: [[String]] = []
        
        _ = try? parser.parseData(text.toData()) {
            result.append($0)
        }
        
        _ = try? parser.parseData(nil) {
            result.append($0)
        }
        
        return result
    }
    
    func chopAndParseText(text: String, step: Int) -> [[String]] {
        let data = text.toData()
        let bytes = UnsafePointer<UInt8>(data.bytes)
        var result = [[String]]()
        
        var i = 0
        while i < data.length {
            let d = NSData(bytes: bytes+i, length: min(step, data.length-i))
            _ = try? parser.parseData(d) {
                result.append($0)
            }
            i += step
        }
        
        _ = try? parser.parseData(nil) {
            result.append($0)
        }
        
        return result
    }
}
