//
//  CSVPerformanceTests.swift
//  UTF8CSV
//
//  Created by Nicolas on 5/21/16.
//  Copyright © 2016 Mobile Labs. All rights reserved.
//

import XCTest
import SwiftCSV
import CHCSVParser
@testable import UTF8CSV

class CSVPerformanceTests: XCTestCase {
    func testCHCSV() {
        measureBlock {
            let url = fileURL()
            let delimiter = ";".utf16.first!
            let _ = NSArray(contentsOfDelimitedURL: url, delimiter: delimiter)
        }
    }
    
    func testSwiftCSV() {
        measureBlock {
            let url = fileURL()
            let csv = try! CSV(url: url, delimiter: ";")
            
            csv.enumerateAsArray {_ in
            }
        }
    }
    
    func testUTF8Version() {
        measureBlock {
            let url = fileURL()
            
            let reader = CSVFileReader(url: url)!
            let parser = CSVDataParser()
            
            let processor: [String] -> () = {_ in
            }
            
            for data in reader {
                try! parser.parseData(data, processor: processor)
            }
            
            try! parser.parseData(nil, processor: processor)
        }
    }
}

private func fileURL() -> NSURL {
    let bundle = NSBundle(forClass: CSVPerformanceTests.self)
    let path = bundle.pathForResource("Test", ofType: "csv")!
    return NSURL(fileURLWithPath: path)
}

