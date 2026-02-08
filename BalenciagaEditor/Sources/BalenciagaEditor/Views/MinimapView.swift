import SwiftUI

struct MinimapView: View {
    let text: String
    let selection: NSRange
    let onJump: (Int) -> Void

    var body: some View {
        let lines = text.components(separatedBy: "\n")
        let currentLine = lineColumn(in: text, selection: selection).line

        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 1) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    let lineNumber = index + 1
                    HStack(spacing: 4) {
                        Text("\(lineNumber)")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.palette.muted)
                            .frame(width: 24, alignment: .trailing)
                        Text(minimapSnippet(line))
                            .font(.system(size: 7, weight: .regular, design: .monospaced))
                            .lineLimit(1)
                            .foregroundColor(Theme.palette.textPrimary)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 2)
                    .background(lineNumber == currentLine ? Theme.palette.accent.opacity(0.55) : Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onJump(lineNumber)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .background(Theme.palette.backgroundMuted)
    }

    private func minimapSnippet(_ line: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.count <= 42 { return trimmed }
        return String(trimmed.prefix(42))
    }
}
