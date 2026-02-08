import Foundation
import AppKit
import SwiftUI

private var failures = 0

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    if condition() {
        print("PASS: \(message)")
    } else {
        failures += 1
        print("FAIL: \(message)")
    }
}

private func runTextFormattingTests() {
    let state = AppState()
    state.createNewFile()
    expect(state.activeTabID != nil, "Active document is created")

    guard let activeID = state.activeTabID,
          let index = state.tabs.firstIndex(where: { $0.id == activeID }) else {
        expect(false, "Can resolve active tab index")
        return
    }

    state.tabs[index].text = "hello"
    state.tabs[index].lastSelection = NSRange(location: 0, length: 5)
    state.applyBold()
    expect(state.tabs[index].text == "**hello**", "Bold formatting wraps selection")

    state.tabs[index].lastSelection = NSRange(location: 2, length: 5)
    state.applyItalic()
    expect(state.tabs[index].text.contains("*hello*"), "Italic formatting wraps selection")

    state.tabs[index].text = "Title\nLine"
    state.tabs[index].lastSelection = NSRange(location: 0, length: 5)
    state.insertHeading()
    expect(state.tabs[index].text.hasPrefix("# Title"), "Heading inserts markdown prefix")

    state.tabs[index].text = "One\nTwo"
    state.tabs[index].lastSelection = NSRange(location: 0, length: 7)
    state.insertBulletList()
    expect(state.tabs[index].text.contains("- One") && state.tabs[index].text.contains("- Two"), "Bullet list prefixes selected lines")

    state.tabs[index].text = "Quote me"
    state.tabs[index].lastSelection = NSRange(location: 0, length: 8)
    state.insertQuote()
    expect(state.tabs[index].text.hasPrefix("> Quote me"), "Quote prefixes selected line")
}

private func runDocumentStatsAndOutlineTests() {
    let state = AppState()
    state.createNewFile()

    guard let activeID = state.activeTabID,
          let index = state.tabs.firstIndex(where: { $0.id == activeID }) else {
        expect(false, "Can resolve active tab for stats")
        return
    }

    state.tabs[index].text = "# First\n\nParagraph one words here.\n\n## Second\nMore text"
    let stats = state.statsForActive()
    let headings = state.headingsForActive()

    expect(stats.words >= 8, "Word counting works")
    expect(stats.paragraphs == 3, "Paragraph counting works")
    expect(stats.readingMinutes >= 1, "Reading-time estimate works")
    expect(headings.count == 2, "Outline heading extraction works")
    expect(headings.first?.title == "First", "Outline heading title parsed")

    state.jumpToHeading(headings[1])
    let cursor = lineColumn(in: state.tabs[index].text, selection: state.tabs[index].lastSelection)
    expect(cursor.line == 5, "Jump to heading moves cursor to target line")
}

private func runViewStateToggleTests() {
    let state = AppState()

    state.togglePreview()
    expect(state.showPreview, "Preview toggle works")

    state.toggleTypewriterMode()
    expect(state.typewriterMode, "Typewriter toggle works")

    state.toggleLineNumbers()
    expect(state.showLineNumbers, "Line number toggle works")

    state.toggleFocusMode()
    expect(state.focusMode, "Focus mode toggle works")
    expect(!state.showSidebar && !state.showInspector && !state.showPreview, "Focus mode hides side panels")

    state.toggleFocusMode()
    expect(!state.focusMode && state.showSidebar && state.showInspector, "Leaving focus mode restores panels")
}

private func runSaveLoadTests() {
    let state = AppState()
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("writer-test-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

    defer { try? FileManager.default.removeItem(at: dir) }

    state.workspaceURL = dir
    state.refreshWorkspace()

    state.createNewFile()
    guard let activeID = state.activeTabID,
          let index = state.tabs.firstIndex(where: { $0.id == activeID }) else {
        expect(false, "Can resolve active tab for save/load")
        return
    }

    let fileURL = dir.appendingPathComponent("draft.md")
    state.tabs[index].url = fileURL
    state.tabs[index].name = "draft.md"
    state.tabs[index].text = "Saved content"
    state.saveActiveTab()

    let diskText = (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
    expect(diskText == "Saved content", "Saving writes content to disk")

    state.closeTab(id: activeID)
    state.openFile(url: fileURL)
    expect(state.activeTab()?.text == "Saved content", "Opening file loads saved content")
    expect(state.recentFiles.contains(fileURL), "Recent files are tracked")
}

private func runUtilityTests() {
    let text = "a\nb\nc"
    let range = rangeForLine(3, in: text)
    let point = lineColumn(in: text, selection: range)
    expect(point.line == 3, "Go-to-line utility resolves line")
}

@main
struct FeatureValidationRunner {
    static func main() {
        runTextFormattingTests()
        runDocumentStatsAndOutlineTests()
        runViewStateToggleTests()
        runSaveLoadTests()
        runUtilityTests()

        if failures == 0 {
            print("\nALL WRITER FEATURE CHECKS PASSED")
            exit(0)
        }

        print("\nWRITER FEATURE CHECKS FAILED: \(failures)")
        exit(1)
    }
}
