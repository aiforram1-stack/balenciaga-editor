import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            WorkspaceSectionView()
            BrutalistDivider(horizontal: true)
            OutlineSectionView()
        }
        .background(Theme.palette.backgroundPanel)
    }
}

struct WorkspaceSectionView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "WORKSPACE") {
                if appState.workspaceURL != nil {
                    Button("REFRESH") { appState.refreshWorkspace() }
                        .buttonStyle(.plain)
                        .font(Theme.uiFont)
                }
            }

            BrutalistDivider(horizontal: true)

            if appState.workspaceURL == nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("NO WORKSPACE")
                        .font(Theme.uiFont)
                    Text("OPEN A FOLDER TO BROWSE DOCUMENTS.")
                        .font(Theme.uiFont)
                        .foregroundColor(Theme.palette.muted)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                List {
                    OutlineGroup(appState.fileTree, children: \.children) { item in
                        Button(action: {
                            if !item.isDirectory {
                                appState.openFile(url: item.url)
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(item.isDirectory ? "[D]" : "[F]")
                                    .foregroundColor(Theme.palette.muted)
                                Text(item.name)
                                    .font(Theme.uiFont)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .background(Theme.palette.backgroundPanel)
                .frame(minHeight: 160)
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(title: String, @ViewBuilder trailing: () -> some View) -> some View {
        HStack {
            Text(title)
                .font(Theme.uiFontLarge)
                .foregroundColor(Theme.palette.textPrimary)
            Spacer()
            trailing()
        }
        .padding(12)
        .background(Theme.palette.backgroundPanel)
    }
}

struct OutlineSectionView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("OUTLINE")
                    .font(Theme.uiFontLarge)
                Spacer()
            }
            .padding(12)

            BrutalistDivider(horizontal: true)

            let headings = appState.headingsForActive()
            if headings.isEmpty {
                Text("USE MARKDOWN HEADINGS (#, ##, ###) TO BUILD AN OUTLINE.")
                    .font(Theme.uiFont)
                    .foregroundColor(Theme.palette.muted)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                List(headings) { heading in
                    Button(action: {
                        appState.jumpToHeading(heading)
                    }) {
                        HStack {
                            Text(String(repeating: "  ", count: max(heading.level - 1, 0)) + heading.title)
                                .font(Theme.uiFont)
                            Spacer()
                            Text("L\(heading.line)")
                                .font(Theme.uiFont)
                                .foregroundColor(Theme.palette.muted)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }

            BrutalistDivider(horizontal: true)

            VStack(alignment: .leading, spacing: 8) {
                Text("RECENT")
                    .font(Theme.uiFontLarge)
                if appState.recentFiles.isEmpty {
                    Text("NO RECENT FILES")
                        .font(Theme.uiFont)
                        .foregroundColor(Theme.palette.muted)
                } else {
                    ForEach(Array(appState.recentFiles.prefix(5)), id: \.self) { file in
                        Button(action: { appState.openFile(url: file) }) {
                            Text(file.lastPathComponent)
                                .font(Theme.uiFont)
                                .lineLimit(1)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity)
    }
}
