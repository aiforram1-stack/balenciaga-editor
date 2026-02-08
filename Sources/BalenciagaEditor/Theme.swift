import SwiftUI
import AppKit

enum Theme {
    static let palette = Palette()

    static let editorFont: NSFont = NSFont(name: "SF Mono", size: 14)
        ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    static let editorFontBold: NSFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .semibold)
    static let editorFontItalic: NSFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)

    static let uiFont: Font = .custom("HelveticaNeue-Bold", size: 12)
    static let uiFontLarge: Font = .custom("HelveticaNeue-CondensedBlack", size: 14)
    static let uiFontHuge: Font = .custom("HelveticaNeue-CondensedBlack", size: 20)

    struct Palette {
        let background = Color(hex: "F5F5F5")
        let backgroundStrong = Color.black
        let backgroundMuted = Color(hex: "EAEAEA")
        let backgroundPanel = Color(hex: "FFFFFF")
        let textPrimary = Color.black
        let textInverted = Color.white
        let accent = Color(hex: "E5FF00")
        let border = Color.black
        let muted = Color(hex: "7A7A7A")
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleaned.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension NSColor {
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleaned.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }

    static let balenciagaBackground = NSColor(hex: "F5F5F5")
    static let balenciagaPanel = NSColor(hex: "FFFFFF")
    static let balenciagaStrong = NSColor(hex: "0A0A0A")
    static let balenciagaMuted = NSColor(hex: "7A7A7A")
    static let balenciagaAccent = NSColor(hex: "E5FF00")
}
