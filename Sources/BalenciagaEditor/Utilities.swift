import Foundation

func lineColumn(in text: String, selection: NSRange) -> (line: Int, column: Int) {
    let nsText = text as NSString
    let location = min(selection.location, nsText.length)
    let prefix = nsText.substring(to: location) as NSString
    let line = max(prefix.components(separatedBy: "\n").count, 1)

    let lastNewline = prefix.range(of: "\n", options: .backwards)
    let column: Int
    if lastNewline.location == NSNotFound {
        column = location + 1
    } else {
        column = location - lastNewline.location
    }
    return (line, column)
}

func rangeForLine(_ line: Int, in text: String) -> NSRange {
    if line <= 1 { return NSRange(location: 0, length: 0) }
    let nsText = text as NSString
    var currentLine = 1
    var index = 0
    while currentLine < line && index < nsText.length {
        let range = nsText.range(of: "\n", options: [], range: NSRange(location: index, length: nsText.length - index))
        if range.location == NSNotFound { break }
        index = range.location + 1
        currentLine += 1
    }
    return NSRange(location: min(index, nsText.length), length: 0)
}
