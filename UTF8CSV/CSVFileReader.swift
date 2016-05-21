//
//  RSVStreamBuffer.swift
//  Spot2R
//
//  Created by Nicolas on 4/23/16.
//  Copyright © 2016 Mobile Labs. All rights reserved.
//

import Foundation

class CSVFileReader {
    let chunkSize : Int
    
    var fileHandle : NSFileHandle!
    var atEof : Bool = false
    
    init?(url: NSURL, chunkSize: Int = 102400) {
        self.chunkSize = chunkSize
        
        if let fileHandle = try? NSFileHandle(forReadingFromURL: url) {
            self.fileHandle = fileHandle
        } else {
            self.fileHandle = nil
            return nil
        }
    }
    
    deinit {
        self.close()
    }
    
    /// Return next line, or nil on EOF.
    func nextChunk() -> NSData? {
        precondition(fileHandle != nil, "Attempt to read from closed file")
        
        if atEof {
            return nil
        }
        
        let tmpData = fileHandle.readDataOfLength(chunkSize)
        if tmpData.length == 0 {
            atEof = true
            return nil
        }
        
        return tmpData
    }

    /// Close the underlying file. No reading must be done after calling this method.
    func close() -> Void {
        fileHandle?.closeFile()
        fileHandle = nil
    }
}

extension CSVFileReader : SequenceType {
    func generate() -> AnyGenerator<NSData> {
        return AnyGenerator {
            return self.nextChunk()
        }
    }
}
