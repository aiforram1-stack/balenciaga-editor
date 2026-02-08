import Foundation

enum Language: String, CaseIterable {
    case plain
    case swift
    case javascript
    case typescript
    case json
    case markdown
    case html
    case css
    case python
    case shell

    static func from(url: URL) -> Language {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "swift": return .swift
        case "js": return .javascript
        case "ts": return .typescript
        case "json": return .json
        case "md", "markdown": return .markdown
        case "html", "htm": return .html
        case "css": return .css
        case "py": return .python
        case "sh", "zsh", "bash": return .shell
        default: return .plain
        }
    }
}

enum SplitMode: String, CaseIterable {
    case single
    case vertical
    case horizontal
}

enum EditorPane: String {
    case primary
    case secondary
}

struct EditorTab: Identifiable, Equatable {
    let id: UUID
    var url: URL?
    var name: String
    var text: String
    var isDirty: Bool
    var language: Language
    var lastSelection: NSRange

    init(url: URL?, name: String, text: String, language: Language) {
        self.id = UUID()
        self.url = url
        self.name = name
        self.text = text
        self.isDirty = false
        self.language = language
        self.lastSelection = NSRange(location: 0, length: 0)
    }
}

struct DiagnosticItem: Identifiable, Equatable {
    let id = UUID()
    let severity: Severity
    let line: Int
    let column: Int
    let message: String

    enum Severity: String {
        case error
        case warning
        case info
    }
}

struct CompletionItem: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let insertText: String
    let detail: String
}

struct DocumentHeading: Identifiable, Equatable {
    let id = UUID()
    let level: Int
    let title: String
    let line: Int
}

struct DocumentStats: Equatable {
    let words: Int
    let characters: Int
    let paragraphs: Int
    let readingMinutes: Int

    static let empty = DocumentStats(words: 0, characters: 0, paragraphs: 0, readingMinutes: 0)
}

struct GitFileStatus: Identifiable, Equatable {
    let id = UUID()
    let stagedCode: String
    let unstagedCode: String
    let path: String

    var displayCode: String {
        let staged = stagedCode == " " ? "-" : stagedCode
        let unstaged = unstagedCode == " " ? "-" : unstagedCode
        return "\(staged)\(unstaged)"
    }

    var isUntracked: Bool {
        stagedCode == "?" && unstagedCode == "?"
    }
}

struct FileNode: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let isDirectory: Bool
    var children: [FileNode]?

    var name: String {
        url.lastPathComponent
    }
}
