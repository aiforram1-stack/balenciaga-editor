import SwiftUI

struct EditorAreaView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            TabStripView()
            BrutalistDivider(horizontal: true)

            if let tab = appState.activeTab() {
                if appState.showPreview {
                    HStack(spacing: 0) {
                        DocumentEditorView()
                        BrutalistDivider(horizontal: false)
                        PreviewPaneView(text: tab.text)
                            .frame(minWidth: 320, idealWidth: 420)
                    }
                } else {
                    DocumentEditorView()
                }
            } else {
                EmptyEditorView()
            }
        }
        .background(Theme.palette.backgroundPanel)
    }
}

struct DocumentEditorView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        CodeEditorView(
            text: appState.activeTextBinding(),
            selection: appState.activeSelectionBinding(),
            language: appState.activeTab()?.language ?? .plain,
            showLineNumbers: appState.showLineNumbers,
            typewriterMode: appState.typewriterMode
        )
        .background(Theme.palette.backgroundPanel)
    }
}

struct PreviewPaneView: View {
    let text: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("PREVIEW")
                    .font(Theme.uiFontLarge)

                if let attributed = try? AttributedString(markdown: text) {
                    Text(attributed)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(text)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .font(.custom("HelveticaNeue", size: 16))
            .padding(20)
        }
        .background(Theme.palette.backgroundMuted)
    }
}

struct TabStripView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(appState.tabs) { tab in
                    TabButton(tab: tab)
                }
            }
        }
        .frame(height: 36)
        .background(Theme.palette.backgroundPanel)
    }
}

struct TabButton: View {
    @EnvironmentObject private var appState: AppState
    let tab: EditorTab

    var body: some View {
        let isActive = tab.id == appState.activeTabID

        HStack(spacing: 8) {
            Text(tab.name.uppercased())
                .font(Theme.uiFont)
            if tab.isDirty {
                Text("*")
                    .font(Theme.uiFont)
            }
            Button(action: { appState.closeTab(id: tab.id) }) {
                Text("X")
                    .font(Theme.uiFont)
            }
            .buttonStyle(.plain)
        }
        .foregroundColor(isActive ? Theme.palette.textInverted : Theme.palette.textPrimary)
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(isActive ? Theme.palette.backgroundStrong : Theme.palette.backgroundPanel)
        .overlay(Rectangle().stroke(Theme.palette.border, lineWidth: 2))
        .contentShape(Rectangle())
        .onTapGesture {
            appState.setActiveTab(tab.id)
        }
    }
}

struct EmptyEditorView: View {
    var body: some View {
        VStack(spacing: 14) {
            Text("NO DOCUMENT OPEN")
                .font(Theme.uiFontHuge)
                .foregroundColor(Theme.palette.textPrimary)
            Text("OPEN A FILE OR START A NEW DOCUMENT.")
                .font(Theme.uiFont)
                .foregroundColor(Theme.palette.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.palette.backgroundPanel)
    }
}
