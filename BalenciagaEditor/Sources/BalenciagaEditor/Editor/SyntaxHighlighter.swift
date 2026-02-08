import AppKit

struct HighlightRule {
    let pattern: String
    let color: NSColor
    let font: NSFont?
}

final class SyntaxHighlighter {
    static let shared = SyntaxHighlighter()

    func apply(to textStorage: NSTextStorage, language: Language) {
        let fullRange = NSRange(location: 0, length: textStorage.length)
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.balenciagaStrong,
            .font: Theme.editorFont
        ]

        textStorage.beginEditing()
        textStorage.setAttributes(baseAttributes, range: fullRange)

        for rule in rules(for: language) {
            guard let regex = try? NSRegularExpression(pattern: rule.pattern, options: []) else { continue }
            regex.enumerateMatches(in: textStorage.string, options: [], range: fullRange) { match, _, _ in
                guard let match else { return }
                var attrs: [NSAttributedString.Key: Any] = [
                    .foregroundColor: rule.color
                ]
                if let font = rule.font {
                    attrs[.font] = font
                }
                textStorage.addAttributes(attrs, range: match.range)
            }
        }

        textStorage.endEditing()
    }

    private func rules(for language: Language) -> [HighlightRule] {
        let comment = HighlightRule(pattern: "//.*|(?s)/\\*.*?\\*/", color: NSColor.balenciagaMuted, font: nil)
        let string = HighlightRule(pattern: "\"(\\\\.|[^\"\\\\])*\"|'(\\\\.|[^'\\\\])*'", color: NSColor(hex: "0A6E5A"), font: nil)
        let number = HighlightRule(pattern: "\\b[0-9]+(\\.[0-9]+)?\\b", color: NSColor(hex: "5A2BE2"), font: nil)
        let keywordColor = NSColor(hex: "111111")
        let keywordFont = Theme.editorFontBold

        switch language {
        case .swift:
            let keywords = ["class", "struct", "enum", "protocol", "extension", "func", "let", "var", "if", "else", "guard", "for", "while", "return", "import", "switch", "case", "default", "break", "continue", "throw", "throws", "try", "catch", "defer", "in", "where", "as", "is", "do", "public", "private", "internal", "fileprivate", "open", "static", "final"]
            let keywordRule = HighlightRule(pattern: "\\b(\(keywords.joined(separator: "|")))\\b", color: keywordColor, font: keywordFont)
            return [comment, string, number, keywordRule]
        case .javascript, .typescript:
            let keywords = ["const", "let", "var", "function", "class", "extends", "if", "else", "for", "while", "return", "import", "export", "from", "switch", "case", "break", "continue", "try", "catch", "finally", "new", "this", "super", "throw", "async", "await", "type", "interface"]
            let keywordRule = HighlightRule(pattern: "\\b(\(keywords.joined(separator: "|")))\\b", color: keywordColor, font: keywordFont)
            return [comment, string, number, keywordRule]
        case .json:
            let keyRule = HighlightRule(pattern: "\"(\\\\.|[^\"\\\\])*\"\\s*(?=:)" , color: NSColor(hex: "2D2D2D"), font: Theme.editorFontBold)
            return [string, number, keyRule]
        case .markdown:
            let heading = HighlightRule(pattern: "(?m)^#{1,6}\\s.*$", color: NSColor(hex: "000000"), font: Theme.editorFontBold)
            let emphasis = HighlightRule(pattern: "\\*\\*.*?\\*\\*|__.*?__", color: NSColor(hex: "111111"), font: Theme.editorFontBold)
            let code = HighlightRule(pattern: "`{1,3}[^`]*`{1,3}", color: NSColor(hex: "0A6E5A"), font: Theme.editorFont)
            return [heading, emphasis, code]
        case .html, .css:
            let tags = HighlightRule(pattern: "</?\\w+[^>]*>", color: NSColor(hex: "0A6E5A"), font: nil)
            let attributes = HighlightRule(pattern: "\\b[a-zA-Z-]+(?=\\=)", color: NSColor(hex: "111111"), font: Theme.editorFontBold)
            return [comment, string, number, tags, attributes]
        case .python:
            let keywords = ["def", "class", "import", "from", "as", "if", "elif", "else", "for", "while", "return", "try", "except", "finally", "with", "lambda", "pass", "break", "continue", "raise", "yield", "in", "is", "not", "and", "or"]
            let keywordRule = HighlightRule(pattern: "\\b(\(keywords.joined(separator: "|")))\\b", color: keywordColor, font: keywordFont)
            let hashComment = HighlightRule(pattern: "#.*", color: NSColor.balenciagaMuted, font: nil)
            return [hashComment, string, number, keywordRule]
        case .shell:
            let hashComment = HighlightRule(pattern: "#.*", color: NSColor.balenciagaMuted, font: nil)
            return [hashComment, string, number]
        case .plain:
            return []
        }
    }
}
