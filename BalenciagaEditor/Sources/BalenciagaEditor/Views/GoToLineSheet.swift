import SwiftUI

struct GoToLineSheet: View {
    @EnvironmentObject private var appState: AppState
    @State private var lineInput: String = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("GO TO LINE")
                .font(Theme.uiFontHuge)
            TextField("LINE NUMBER", text: $lineInput)
                .textFieldStyle(.plain)
                .padding(8)
                .overlay(Rectangle().stroke(Theme.palette.border, lineWidth: 2))
                .background(Theme.palette.backgroundPanel)

            HStack(spacing: 12) {
                BrutalistButton(label: "GO", isPrimary: true) {
                    goToLine()
                }
                BrutalistButton(label: "CLOSE", isPrimary: false) {
                    appState.showGoToLine = false
                }
            }
        }
        .padding(16)
        .frame(width: 360, height: 220)
        .background(Theme.palette.background)
    }

    private func goToLine() {
        guard let target = Int(lineInput), target > 0 else { return }
        appState.goToLine(target)
        appState.showGoToLine = false
    }
}
