import SwiftUI

enum StepTheme {
    static let accent = Color(hex: 0x22C55E)
    static let accentSecondary = Color(hex: 0x0EA5E9)
    static let accentWarm = Color(hex: 0xF59E0B)
    static let accentRose = Color(hex: 0xF97316)
    static let card = Color(uiColor: .secondarySystemBackground)
    static let cardSoft = Color(uiColor: .tertiarySystemBackground)
    static let cardStroke = Color.black.opacity(0.08)
    static let ringTrack = Color.black.opacity(0.08)

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentSecondary, accentWarm],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func tint(for achievement: AchievementKind) -> Color {
        switch achievement {
        case .firstWalk:
            return accentSecondary
        case .goalBreaker:
            return accent
        case .tenKDay:
            return accentWarm
        case .streak3, .streak7:
            return accentRose
        case .climb50:
            return Color(hex: 0x8B5CF6)
        case .distance25K:
            return Color(hex: 0x14B8A6)
        case .weekendWin:
            return Color(hex: 0xF43F5E)
        }
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
