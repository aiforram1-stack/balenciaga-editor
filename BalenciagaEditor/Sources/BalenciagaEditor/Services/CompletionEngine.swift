import Foundation

struct CompletionEngine {
    func suggestions(for text: String, selection: NSRange, language: Language, workspaceFiles: [URL]) -> [CompletionItem] {
        let prefix = completionPrefix(in: text, selection: selection)
        if prefix.isEmpty { return [] }

        var candidates = Set<String>()
        candidates.formUnion(keywords(for: language))
        candidates.formUnion(extractIdentifiers(from: text))
        candidates.formUnion(extractWorkspaceNames(workspaceFiles: workspaceFiles))

        let normalizedPrefix = prefix.lowercased()
        let sorted = candidates
            .filter { $0.lowercased().hasPrefix(normalizedPrefix) && $0.lowercased() != normalizedPrefix }
            .sorted()

        return Array(sorted.prefix(25)).map {
            CompletionItem(label: $0, insertText: $0, detail: "symbol")
        }
    }

    func completionPrefix(in text: String, selection: NSRange) -> String {
        let nsText = text as NSString
        let cursor = max(0, min(selection.location, nsText.length))
        if cursor == 0 { return "" }

        var start = cursor
        while start > 0 {
            let scalar = nsText.character(at: start - 1)
            if isIdentifierCharacter(scalar) {
                start -= 1
            } else {
                break
            }
        }

        let length = cursor - start
        guard length > 0 else { return "" }
        return nsText.substring(with: NSRange(location: start, length: length))
    }

    private func extractIdentifiers(from text: String) -> Set<String> {
        let pattern = "\\b[_a-zA-Z][_a-zA-Z0-9]{2,}\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        var names = Set<String>()

        regex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            guard let match else { return }
            names.insert(nsText.substring(with: match.range))
        }

        return names
    }

    private func extractWorkspaceNames(workspaceFiles: [URL]) -> Set<String> {
        Set(workspaceFiles.map { $0.deletingPathExtension().lastPathComponent })
    }

    private func isIdentifierCharacter(_ scalar: unichar) -> Bool {
        if scalar >= 65 && scalar <= 90 { return true }
        if scalar >= 97 && scalar <= 122 { return true }
        if scalar >= 48 && scalar <= 57 { return true }
        return scalar == 95
    }

    private func keywords(for language: Language) -> [String] {
        switch language {
        case .swift:
            return ["class", "struct", "enum", "func", "let", "var", "protocol", "extension", "guard", "defer", "switch", "case", "async", "await", "throws", "import", "return"]
        case .javascript, .typescript:
            return ["const", "let", "var", "function", "class", "extends", "async", "await", "import", "export", "interface", "type", "return", "switch", "case"]
        case .python:
            return ["def", "class", "import", "from", "return", "async", "await", "yield", "for", "while", "try", "except", "with", "lambda"]
        case .json:
            return ["true", "false", "null"]
        case .markdown:
            return ["#", "##", "###", "```", "-", "*"]
        case .html:
            return ["div", "span", "section", "article", "header", "footer", "main", "script", "style"]
        case .css:
            return ["display", "position", "grid", "flex", "gap", "padding", "margin", "color", "background"]
        case .shell:
            return ["if", "then", "else", "fi", "for", "while", "do", "done", "case", "esac", "function"]
        case .plain:
            return []
        }
    }
}
