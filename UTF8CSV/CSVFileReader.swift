//
//  RSVStreamBuffer.swift
//  Spot2R
//
//  Created by Nicolas on 4/23/16.
//  Copyright © 2016 Mobile Labs. All rights reserved.
//

import Foundation

open class CSVFileReader {
    let chunkSize : Int
    
    var fileHandle : FileHandle!
    var atEof : Bool = false
    
    public init?(url: URL, chunkSize: Int = 102400) {
        self.chunkSize = chunkSize
        
        if let fileHandle = try? FileHandle(forReadingFrom: url) {
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
    func nextChunk() -> Data? {
        precondition(fileHandle != nil, "Attempt to read from closed file")
        
        if atEof {
            return nil
        }
        
        let tmpData = fileHandle.readData(ofLength: chunkSize)
        if tmpData.count == 0 {
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

extension CSVFileReader : Sequence {
    public func makeIterator() -> AnyIterator<Data> {
        return AnyIterator {
            return self.nextChunk()
        }
    }
}
