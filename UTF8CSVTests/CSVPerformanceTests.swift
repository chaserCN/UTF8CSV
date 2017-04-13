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
    func _testCHCSV() {
        measure {
            let url = fileURL()
            let delimiter = ";".utf16.first!
            let parser = CHCSVParser(contentsOfDelimitedURL: url, delimiter: delimiter)
            parser?.parse()
            //let array: NSArray = NSArray.arrayWithContentsOfDelimitedURL(url, delimiter: delimiter)
        }
    }
    
    func _testSwiftCSV() {
        measure {
            let url = fileURL()
            let csv = try! CSV(url: url, delimiter: ";")
            
            csv.enumerateAsArray {_ in
            }
        }
    }
    
    func _testUTF8Version() {
        measure {
            let url = fileURL()
            
            let reader = CSVFileReader(url: url)!
            let parser = CSVDataParser()
            
            let processor: ([String]) -> () = {_ in
            }
            
            for data in reader {
                try! parser.parse(data, using: processor)
            }
            
            try! parser.parse(nil, using: processor)
        }
    }
}

private func fileURL() -> URL {
    let bundle = Bundle(for: CSVPerformanceTests.self)
    let path = bundle.path(forResource: "Test", ofType: "csv")!
    return URL(fileURLWithPath: path)
}

