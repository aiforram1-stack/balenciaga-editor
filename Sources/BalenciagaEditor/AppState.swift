import SwiftUI
import AppKit

final class AppState: ObservableObject {
    @Published var workspaceURL: URL?
    @Published var fileTree: [FileNode] = []
    @Published var fileIndex: [URL] = []
    @Published var recentFiles: [URL] = []

    @Published var tabs: [EditorTab] = []
    @Published var activeTabID: UUID?

    @Published var statusText: String = "READY"
    @Published var showGoToLine: Bool = false
    @Published var showQuickOpen: Bool = false

    @Published var showSidebar: Bool = true
    @Published var showInspector: Bool = true
    @Published var showPreview: Bool = false
    @Published var focusMode: Bool = false
    @Published var typewriterMode: Bool = false
    @Published var showLineNumbers: Bool = false

    @Published var writingGoalWords: Int = 1000

    private var autosaveWorkItems: [UUID: DispatchWorkItem] = [:]

    func openWorkspace() {
        let panel = NSOpenPanel()
        panel.title = "OPEN"
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "OPEN"

        if panel.runModal() == .OK, let url = panel.url {
            var isDirectory: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            if isDirectory.boolValue {
                workspaceURL = url
                refreshWorkspace()
                statusText = "WORKSPACE OPENED"
            } else {
                workspaceURL = url.deletingLastPathComponent()
                refreshWorkspace()
                openFile(url: url)
            }
        }
    }

    func refreshWorkspace() {
        guard let workspaceURL else {
            fileTree = []
            fileIndex = []
            return
        }
        let root = buildTree(url: workspaceURL)
        fileTree = root.map { [$0] } ?? []
        fileIndex = flattenFiles(nodes: fileTree)
    }

    func createNewFile() {
        let tab = EditorTab(url: nil, name: "UNTITLED", text: "", language: .plain)
        tabs.append(tab)
        activeTabID = tab.id
        statusText = "NEW DOCUMENT"
    }

    func openFile(url: URL) {
        if let existing = tabs.first(where: { $0.url == url }) {
            activeTabID = existing.id
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let contents = String(decoding: data, as: UTF8.self)
            let tab = EditorTab(url: url, name: url.lastPathComponent, text: contents, language: Language.from(url: url))
            tabs.append(tab)
            activeTabID = tab.id
            pushRecentFile(url)
            statusText = "OPENED \(url.lastPathComponent.uppercased())"
        } catch {
            statusText = "FAILED TO OPEN FILE"
        }
    }

    func saveActiveTab() {
        guard let activeTabID else {
            statusText = "NO ACTIVE DOCUMENT"
            return
        }
        saveTab(id: activeTabID)
    }

    func saveAll() {
        for tab in tabs {
            saveTab(id: tab.id)
        }
    }

    func saveTab(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }

        if let url = tabs[index].url {
            do {
                try tabs[index].text.write(to: url, atomically: true, encoding: .utf8)
                tabs[index].isDirty = false
                pushRecentFile(url)
                statusText = "SAVED \(tabs[index].name.uppercased())"
            } catch {
                statusText = "SAVE FAILED"
            }
            return
        }

        let panel = NSSavePanel()
        panel.title = "SAVE DOCUMENT"
        panel.prompt = "SAVE"
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try tabs[index].text.write(to: url, atomically: true, encoding: .utf8)
                tabs[index].url = url
                tabs[index].name = url.lastPathComponent
                tabs[index].language = Language.from(url: url)
                tabs[index].isDirty = false
                pushRecentFile(url)
                statusText = "SAVED \(tabs[index].name.uppercased())"
                refreshWorkspace()
            } catch {
                statusText = "SAVE FAILED"
            }
        }
    }

    func closeTab(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs.remove(at: index)
        autosaveWorkItems[id]?.cancel()

        if activeTabID == id {
            activeTabID = tabs.last?.id
        }
        if tabs.isEmpty {
            statusText = "NO DOCUMENT OPEN"
        }
    }

    func setActiveTab(_ id: UUID) {
        activeTabID = id
    }

    func activeTab() -> EditorTab? {
        guard let activeTabID else { return nil }
        return tabs.first(where: { $0.id == activeTabID })
    }

    func activeTextBinding() -> Binding<String> {
        Binding(
            get: { [weak self] in
                guard let self, let id = self.activeTabID else { return "" }
                return self.tabs.first(where: { $0.id == id })?.text ?? ""
            },
            set: { [weak self] newValue in
                guard let self,
                      let id = self.activeTabID,
                      let index = self.tabs.firstIndex(where: { $0.id == id }) else { return }
                self.tabs[index].text = newValue
                self.tabs[index].isDirty = true
                self.scheduleAutosave(for: id)
                self.statusText = "EDITING"
            }
        )
    }

    func activeSelectionBinding() -> Binding<NSRange> {
        Binding(
            get: { [weak self] in
                guard let self,
                      let id = self.activeTabID,
                      let tab = self.tabs.first(where: { $0.id == id }) else {
                    return NSRange(location: 0, length: 0)
                }
                return tab.lastSelection
            },
            set: { [weak self] newValue in
                guard let self,
                      let id = self.activeTabID,
                      let index = self.tabs.firstIndex(where: { $0.id == id }) else { return }
                self.tabs[index].lastSelection = newValue
            }
        )
    }

    func goToLine(_ line: Int) {
        guard let id = activeTabID,
              let index = tabs.firstIndex(where: { $0.id == id }),
              line > 0 else { return }
        tabs[index].lastSelection = rangeForLine(line, in: tabs[index].text)
        statusText = "JUMPED TO LINE \(line)"
    }

    func headingsForActive() -> [DocumentHeading] {
        guard let tab = activeTab() else { return [] }
        let lines = tab.text.components(separatedBy: "\n")
        var headings: [DocumentHeading] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("#") else { continue }

            let level = min(trimmed.prefix { $0 == "#" }.count, 6)
            guard level > 0 else { continue }
            let title = trimmed.dropFirst(level).trimmingCharacters(in: .whitespaces)
            if title.isEmpty { continue }
            headings.append(DocumentHeading(level: level, title: title, line: index + 1))
        }

        return headings
    }

    func jumpToHeading(_ heading: DocumentHeading) {
        goToLine(heading.line)
    }

    func statsForActive() -> DocumentStats {
        guard let text = activeTab()?.text else { return .empty }

        let characters = text.count
        let words = text.split { !$0.isLetter && !$0.isNumber && $0 != "'" }.count
        let paragraphs = text
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .count
        let readingMinutes = max(Int(ceil(Double(words) / 220.0)), words == 0 ? 0 : 1)

        return DocumentStats(words: words, characters: characters, paragraphs: paragraphs, readingMinutes: readingMinutes)
    }

    func applyBold() {
        wrapSelection(prefix: "**", suffix: "**")
    }

    func applyItalic() {
        wrapSelection(prefix: "*", suffix: "*")
    }

    func applyInlineCode() {
        wrapSelection(prefix: "`", suffix: "`")
    }

    func insertHeading() {
        prefixSelectedLines(with: "# ")
    }

    func insertBulletList() {
        prefixSelectedLines(with: "- ")
    }

    func insertQuote() {
        prefixSelectedLines(with: "> ")
    }

    func insertDateStamp() {
        guard let id = activeTabID,
              let index = tabs.firstIndex(where: { $0.id == id }) else {
            createNewFile()
            insertDateStamp()
            return
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let stamp = formatter.string(from: Date())
        insertTextAtCursor("\n\n\(stamp)\n\n", tabIndex: index)
        statusText = "DATE INSERTED"
    }

    func togglePreview() {
        showPreview.toggle()
    }

    func toggleFocusMode() {
        focusMode.toggle()
        if focusMode {
            showSidebar = false
            showInspector = false
            showPreview = false
        } else {
            showSidebar = true
            showInspector = true
        }
    }

    func toggleTypewriterMode() {
        typewriterMode.toggle()
    }

    func toggleLineNumbers() {
        showLineNumbers.toggle()
    }

    func toggleSidebar() {
        showSidebar.toggle()
    }

    func toggleInspector() {
        showInspector.toggle()
    }

    func showFindPanel() {
        let item = NSMenuItem()
        item.tag = Int(NSFindPanelAction.showFindPanel.rawValue)
        NSApp.sendAction(#selector(NSTextView.performFindPanelAction(_:)), to: nil, from: item)
    }

    func showReplacePanel() {
        let item = NSMenuItem()
        item.tag = Int(NSFindPanelAction.replace.rawValue)
        NSApp.sendAction(#selector(NSTextView.performFindPanelAction(_:)), to: nil, from: item)
    }

    private func wrapSelection(prefix: String, suffix: String) {
        guard let id = activeTabID,
              let index = tabs.firstIndex(where: { $0.id == id }) else {
            createNewFile()
            wrapSelection(prefix: prefix, suffix: suffix)
            return
        }

        let tabText = tabs[index].text as NSString
        let selection = tabs[index].lastSelection
        let safeSelection = NSRange(location: min(selection.location, tabText.length), length: min(selection.length, tabText.length - min(selection.location, tabText.length)))
        let selectedText = tabText.substring(with: safeSelection)

        let replacement: String
        let caretLocation: Int
        if selectedText.isEmpty {
            replacement = prefix + suffix
            caretLocation = safeSelection.location + prefix.count
        } else {
            replacement = prefix + selectedText + suffix
            caretLocation = safeSelection.location + replacement.count
        }

        tabs[index].text = tabText.replacingCharacters(in: safeSelection, with: replacement)
        tabs[index].lastSelection = NSRange(location: caretLocation, length: 0)
        tabs[index].isDirty = true
        scheduleAutosave(for: id)
    }

    private func prefixSelectedLines(with prefix: String) {
        guard let id = activeTabID,
              let index = tabs.firstIndex(where: { $0.id == id }) else {
            createNewFile()
            prefixSelectedLines(with: prefix)
            return
        }

        let nsText = tabs[index].text as NSString
        let selection = tabs[index].lastSelection
        let lineRange = nsText.lineRange(for: selection)
        let block = nsText.substring(with: lineRange)

        let lines = block.split(separator: "\n", omittingEmptySubsequences: false)
        let prefixed = lines.map { line in
            if line.trimmingCharacters(in: .whitespaces).isEmpty { return String(line) }
            return prefix + line
        }.joined(separator: "\n")

        tabs[index].text = nsText.replacingCharacters(in: lineRange, with: prefixed)
        tabs[index].lastSelection = NSRange(location: lineRange.location, length: (prefixed as NSString).length)
        tabs[index].isDirty = true
        scheduleAutosave(for: id)
    }

    private func insertTextAtCursor(_ content: String, tabIndex: Int) {
        let nsText = tabs[tabIndex].text as NSString
        let selection = tabs[tabIndex].lastSelection
        let safeSelection = NSRange(location: min(selection.location, nsText.length), length: min(selection.length, nsText.length - min(selection.location, nsText.length)))

        tabs[tabIndex].text = nsText.replacingCharacters(in: safeSelection, with: content)
        tabs[tabIndex].lastSelection = NSRange(location: safeSelection.location + (content as NSString).length, length: 0)
        tabs[tabIndex].isDirty = true
        if let id = activeTabID {
            scheduleAutosave(for: id)
        }
    }

    private func scheduleAutosave(for id: UUID) {
        autosaveWorkItems[id]?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.autosaveIfPossible(id: id)
        }
        autosaveWorkItems[id] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }

    private func autosaveIfPossible(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        guard let url = tabs[index].url else { return }

        do {
            try tabs[index].text.write(to: url, atomically: true, encoding: .utf8)
            tabs[index].isDirty = false
            statusText = "AUTO-SAVED"
            pushRecentFile(url)
        } catch {
            statusText = "AUTO-SAVE FAILED"
        }
    }

    private func pushRecentFile(_ url: URL) {
        recentFiles.removeAll(where: { $0 == url })
        recentFiles.insert(url, at: 0)
        if recentFiles.count > 20 {
            recentFiles = Array(recentFiles.prefix(20))
        }
    }

    private func buildTree(url: URL) -> FileNode? {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return nil }

        if isDirectory.boolValue {
            let childrenURLs = (try? FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )) ?? []

            let nodes = childrenURLs
                .filter { !isIgnored($0) }
                .sorted { lhs, rhs in
                    let lhsIsDir = (try? lhs.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                    let rhsIsDir = (try? rhs.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                    if lhsIsDir != rhsIsDir { return lhsIsDir && !rhsIsDir }
                    return lhs.lastPathComponent.lowercased() < rhs.lastPathComponent.lowercased()
                }
                .compactMap { buildTree(url: $0) }

            return FileNode(url: url, isDirectory: true, children: nodes)
        }

        return FileNode(url: url, isDirectory: false, children: nil)
    }

    private func isIgnored(_ url: URL) -> Bool {
        let ignoredNames: Set<String> = [".git", "node_modules", "DerivedData", ".DS_Store", ".idea", ".vscode", ".build"]
        return ignoredNames.contains(url.lastPathComponent)
    }

    private func flattenFiles(nodes: [FileNode]) -> [URL] {
        var results: [URL] = []
        for node in nodes {
            if node.isDirectory {
                if let children = node.children {
                    results.append(contentsOf: flattenFiles(nodes: children))
                }
            } else {
                results.append(node.url)
            }
        }
        return results
    }
}
