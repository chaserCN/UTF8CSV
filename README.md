UTF8CSV
==============

SwiftCSV parses 1.3MB CSV file about 50 seconds on the iPad2, CHCSVParser - 40 seconds.
If you want to parse a CSV file on the fly while downloading it from the internet, good luck with that.

UTF8CSV implementation assumes that files are always encoded with UTF8. 
Then UTF8 decoding can be inlined into the parser instead of relying on the String class.
UTF8CSV parses the same 1.3MB about 3 seconds on the iPad2.

If you need to convert parsed strings into a structure, you may use CSVDecodable protocol.

## Examples

```swift

struct Model {
    let placeID: Int
    let subgroupID: String
    let paramID: Int
}

extension Model: CSVDecodable {
    init(decoder: CSVDecoder) throws {
        placeID = try decoder.decodeNext()
        subgroupID = try decoder.decodeNext()
        paramID = try decoder.decodeNext()
    }
}

func readModels(url: NSURL) throws -> [Model] {
    // reader just returns chunks of bytes from the file.
    guard let reader = CSVFileReader(url: url) else {
        throw NSError(domain: "", code: 0, userInfo: nil)
    }

    let parser = CSVDataParser()
    var models: [Model] = []

    let processor: [String] throws -> () = {
        let m = try Model(values: $0)
        models.append(m)
    }

    for data in reader {
        try parser.parseData(data, processor: processor)
    }

    // if the last line does not have \n at the end, this will call processor one more time
    try parser.parseData(nil, processor: processor)

    return models
}
```

### License

MIT, see [LICENSE](LICENSE.md)
