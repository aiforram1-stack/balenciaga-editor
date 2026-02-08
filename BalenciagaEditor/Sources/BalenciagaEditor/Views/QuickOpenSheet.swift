import SwiftUI

struct QuickOpenSheet: View {
    @EnvironmentObject private var appState: AppState
    @State private var query: String = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("QUICK OPEN")
                .font(Theme.uiFontHuge)
            TextField("TYPE TO FILTER", text: $query)
                .textFieldStyle(.plain)
                .padding(8)
                .overlay(Rectangle().stroke(Theme.palette.border, lineWidth: 2))
                .background(Theme.palette.backgroundPanel)

            List(filteredFiles, id: \.self) { url in
                Button(action: {
                    appState.openFile(url: url)
                    appState.showQuickOpen = false
                }) {
                    HStack {
                        Text(url.lastPathComponent.uppercased())
                            .font(Theme.uiFont)
                        Spacer()
                        Text(url.deletingLastPathComponent().lastPathComponent.uppercased())
                            .font(Theme.uiFont)
                            .foregroundColor(Theme.palette.muted)
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .frame(minHeight: 240)

            BrutalistButton(label: "CLOSE", isPrimary: false) {
                appState.showQuickOpen = false
            }
        }
        .padding(16)
        .frame(width: 520, height: 420)
        .background(Theme.palette.background)
    }

    private var filteredFiles: [URL] {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Array(appState.fileIndex.prefix(50))
        }
        return appState.fileIndex.filter { $0.lastPathComponent.lowercased().contains(query.lowercased()) }
    }
}
