import SwiftUI

@main
struct BalenciagaEditorApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .frame(minWidth: 1100, minHeight: 720)
        }
        .commands {
            EditorCommands(appState: appState)
        }
    }
}

struct EditorCommands: Commands {
    @ObservedObject var appState: AppState

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Document") { appState.createNewFile() }
                .keyboardShortcut("n")
            Button("Open Workspace or File") { appState.openWorkspace() }
                .keyboardShortcut("o")
        }

        CommandGroup(replacing: .saveItem) {
            Button("Save") { appState.saveActiveTab() }
                .keyboardShortcut("s")
            Button("Save All") { appState.saveAll() }
                .keyboardShortcut("s", modifiers: [.command, .shift])
        }

        CommandGroup(after: .textEditing) {
            Button("Find") { appState.showFindPanel() }
                .keyboardShortcut("f")
            Button("Replace") { appState.showReplacePanel() }
                .keyboardShortcut("f", modifiers: [.command, .option])
            Button("Go To Line") { appState.showGoToLine = true }
                .keyboardShortcut("l")
            Button("Quick Open") { appState.showQuickOpen = true }
                .keyboardShortcut("p")
            Divider()
            Button("Bold") { appState.applyBold() }
                .keyboardShortcut("b")
            Button("Italic") { appState.applyItalic() }
                .keyboardShortcut("i")
            Button("Heading") { appState.insertHeading() }
                .keyboardShortcut("h", modifiers: [.command, .shift])
            Button("Bulleted List") { appState.insertBulletList() }
                .keyboardShortcut("8", modifiers: [.command, .shift])
            Button("Quote") { appState.insertQuote() }
                .keyboardShortcut("'", modifiers: [.command, .shift])
        }

        CommandMenu("View") {
            Button("Toggle Preview") { appState.togglePreview() }
                .keyboardShortcut("p", modifiers: [.command, .option])
            Button("Toggle Focus Mode") { appState.toggleFocusMode() }
                .keyboardShortcut("f", modifiers: [.command, .option])
            Button("Toggle Typewriter") { appState.toggleTypewriterMode() }
                .keyboardShortcut("t", modifiers: [.command, .option])
            Button("Toggle Line Numbers") { appState.toggleLineNumbers() }
                .keyboardShortcut("l", modifiers: [.command, .option])
            Button("Toggle Sidebar") { appState.toggleSidebar() }
                .keyboardShortcut("0", modifiers: [.command, .option])
        }
    }
}
