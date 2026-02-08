import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            if !appState.focusMode {
                TopBar()
                BrutalistDivider(horizontal: true)
            }

            HStack(spacing: 0) {
                if appState.showSidebar && !appState.focusMode {
                    SidebarView()
                        .frame(minWidth: 280, idealWidth: 320, maxWidth: 420)
                    BrutalistDivider(horizontal: false)
                }

                EditorAreaView()

                if appState.showInspector && !appState.focusMode {
                    BrutalistDivider(horizontal: false)
                    InspectorView()
                        .frame(minWidth: 240, idealWidth: 280, maxWidth: 320)
                }
            }

            BrutalistDivider(horizontal: true)
            StatusBarView()
        }
        .background(Theme.palette.background)
        .sheet(isPresented: $appState.showQuickOpen) {
            QuickOpenSheet()
        }
        .sheet(isPresented: $appState.showGoToLine) {
            GoToLineSheet()
        }
        .overlay(WindowConfigurator().allowsHitTesting(false))
    }
}

struct TopBar: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Text("BALENCIAGA WRITER")
                    .font(Theme.uiFontHuge)
                    .foregroundColor(Theme.palette.textInverted)
                    .padding(.leading, 14)
                BrutalistButton(label: "NEW", isPrimary: false) { appState.createNewFile() }
                BrutalistButton(label: "OPEN", isPrimary: false) { appState.openWorkspace() }
                BrutalistButton(label: "SAVE", isPrimary: true) { appState.saveActiveTab() }
                BrutalistButton(label: "SAVE ALL", isPrimary: false) { appState.saveAll() }
                BrutalistButton(label: "QUICK", isPrimary: false) { appState.showQuickOpen = true }
                BrutalistButton(label: "FIND", isPrimary: false) { appState.showFindPanel() }
                BrutalistButton(label: "GO TO", isPrimary: false) { appState.showGoToLine = true }
                Spacer(minLength: 0)
            }
            HStack(spacing: 8) {
                BrutalistButton(label: "BOLD", isPrimary: false) { appState.applyBold() }
                BrutalistButton(label: "ITALIC", isPrimary: false) { appState.applyItalic() }
                BrutalistButton(label: "CODE", isPrimary: false) { appState.applyInlineCode() }
                BrutalistButton(label: "H1", isPrimary: false) { appState.insertHeading() }
                BrutalistButton(label: "LIST", isPrimary: false) { appState.insertBulletList() }
                BrutalistButton(label: "QUOTE", isPrimary: false) { appState.insertQuote() }
                BrutalistButton(label: "DATE", isPrimary: false) { appState.insertDateStamp() }
                BrutalistButton(label: appState.showPreview ? "PREVIEW ON" : "PREVIEW OFF", isPrimary: appState.showPreview) { appState.togglePreview() }
                BrutalistButton(label: appState.typewriterMode ? "TYPEWRITER ON" : "TYPEWRITER OFF", isPrimary: appState.typewriterMode) { appState.toggleTypewriterMode() }
                BrutalistButton(label: appState.showLineNumbers ? "LINES ON" : "LINES OFF", isPrimary: appState.showLineNumbers) { appState.toggleLineNumbers() }
                BrutalistButton(label: appState.showSidebar ? "SIDEBAR ON" : "SIDEBAR OFF", isPrimary: appState.showSidebar) { appState.toggleSidebar() }
                BrutalistButton(label: appState.showInspector ? "PANEL ON" : "PANEL OFF", isPrimary: appState.showInspector) { appState.toggleInspector() }
                BrutalistButton(label: appState.focusMode ? "FOCUS ON" : "FOCUS OFF", isPrimary: appState.focusMode) { appState.toggleFocusMode() }
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 6)
        .background(Theme.palette.backgroundStrong)
    }
}

struct StatusBarView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        let stats = appState.statsForActive()

        HStack(spacing: 12) {
            if let tab = appState.activeTab() {
                let cursor = lineColumn(in: tab.text, selection: tab.lastSelection)
                Text(tab.url?.path ?? "UNTITLED")
                    .font(Theme.uiFont)
                    .lineLimit(1)
                Spacer()
                Text("LINE \(cursor.line):\(cursor.column)")
                    .font(Theme.uiFont)
                Text("WORDS \(stats.words)")
                    .font(Theme.uiFont)
                Text("CHARS \(stats.characters)")
                    .font(Theme.uiFont)
                Text("READ \(stats.readingMinutes) MIN")
                    .font(Theme.uiFont)
            } else {
                Text("NO DOCUMENT OPEN")
                    .font(Theme.uiFont)
                Spacer()
            }

            Text(appState.statusText)
                .font(Theme.uiFont)
        }
        .foregroundColor(Theme.palette.textPrimary)
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background(Theme.palette.backgroundMuted)
    }
}

struct BrutalistDivider: View {
    let horizontal: Bool

    var body: some View {
        Rectangle()
            .fill(Theme.palette.border)
            .frame(width: horizontal ? nil : 2, height: horizontal ? 2 : nil)
    }
}

struct BrutalistButton: View {
    let label: String
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Theme.uiFontLarge)
                .tracking(1.1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(minHeight: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(isPrimary ? Theme.palette.textPrimary : Theme.palette.textInverted)
        .background(isPrimary ? Theme.palette.accent : Theme.palette.backgroundStrong)
        .overlay(Rectangle().stroke(Theme.palette.border, lineWidth: 2))
    }
}

struct WindowConfigurator: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView { PassthroughNSView() }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let window = nsView.window else { return }
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor.balenciagaBackground
        if !context.coordinator.didActivateWindow {
            context.coordinator.didActivateWindow = true
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    final class Coordinator {
        var didActivateWindow = false
    }

    final class PassthroughNSView: NSView {
        override func hitTest(_ point: NSPoint) -> NSView? {
            nil
        }
    }
}
