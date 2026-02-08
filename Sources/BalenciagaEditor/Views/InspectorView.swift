import SwiftUI

struct InspectorView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        let stats = appState.statsForActive()
        let progress = appState.writingGoalWords == 0 ? 0 : min(Double(stats.words) / Double(appState.writingGoalWords), 1.0)

        VStack(spacing: 0) {
            HStack {
                Text("WRITING PANEL")
                    .font(Theme.uiFontLarge)
                Spacer()
            }
            .padding(12)

            BrutalistDivider(horizontal: true)

            VStack(alignment: .leading, spacing: 12) {
                Text("WORDS: \(stats.words)")
                    .font(Theme.uiFont)
                Text("CHARACTERS: \(stats.characters)")
                    .font(Theme.uiFont)
                Text("PARAGRAPHS: \(stats.paragraphs)")
                    .font(Theme.uiFont)
                Text("READING TIME: \(stats.readingMinutes) MIN")
                    .font(Theme.uiFont)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)

            BrutalistDivider(horizontal: true)

            VStack(alignment: .leading, spacing: 10) {
                Text("WORD GOAL")
                    .font(Theme.uiFontLarge)

                Stepper(value: $appState.writingGoalWords, in: 100...10000, step: 100) {
                    Text("GOAL: \(appState.writingGoalWords)")
                        .font(Theme.uiFont)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Theme.palette.backgroundMuted)
                        Rectangle()
                            .fill(Theme.palette.accent)
                            .frame(width: geo.size.width * progress)
                    }
                    .overlay(Rectangle().stroke(Theme.palette.border, lineWidth: 2))
                }
                .frame(height: 16)

                Text("\(Int(progress * 100))% COMPLETE")
                    .font(Theme.uiFont)
                    .foregroundColor(Theme.palette.muted)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)

            BrutalistDivider(horizontal: true)

            VStack(alignment: .leading, spacing: 8) {
                Text("TOOLS")
                    .font(Theme.uiFontLarge)

                BrutalistButton(label: "BOLD", isPrimary: false) { appState.applyBold() }
                BrutalistButton(label: "ITALIC", isPrimary: false) { appState.applyItalic() }
                BrutalistButton(label: "H1", isPrimary: false) { appState.insertHeading() }
                BrutalistButton(label: "LIST", isPrimary: false) { appState.insertBulletList() }
                BrutalistButton(label: "QUOTE", isPrimary: false) { appState.insertQuote() }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .background(Theme.palette.backgroundPanel)
    }
}
