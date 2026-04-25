import SwiftUI

enum AppColors {
    static let background = Color(hex: "FAF8F5")
    static let surface = Color(hex: "F5F0EB")
    static let primary = Color(hex: "2A9D8F")
    static let primaryDark = Color(hex: "1A7A6F")
    static let secondary = Color(hex: "E76F51")
    static let accent = Color(hex: "E9C46A")
    static let textPrimary = Color(hex: "2D3436")
    static let textSecondary = Color(hex: "636E72")
    static let success = Color(hex: "52B788")
    static let error = Color(hex: "E63946")
    static let cardWhite = Color.white
}

enum AppFonts {
    static func rounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func handwritten(_ size: CGFloat) -> Font {
        .custom("Bradley Hand", size: size)
    }

    static let title = rounded(32, weight: .bold)
    static let heading = rounded(28, weight: .bold)
    static let body = rounded(18, weight: .regular)
    static let bodyBold = rounded(18, weight: .semibold)
    static let button = rounded(20, weight: .semibold)
    static let caption = rounded(16, weight: .regular)
    static let repCounter = rounded(48, weight: .bold)
    static let feedbackText = rounded(24, weight: .bold)
    static let doctorsNote = handwritten(22)
}

enum AppLayout {
    static let screenPadding: CGFloat = 24
    static let cardPadding: CGFloat = 20
    static let cardRadius: CGFloat = 16
    static let buttonHeight: CGFloat = 56
    static let buttonRadius: CGFloat = 16
    static let minTouchTarget: CGFloat = 54
    static let elementSpacing: CGFloat = 16
    static let iconSize: CGFloat = 28
}

enum AppShadow {
    static let color = Color.black.opacity(0.08)
    static let radius: CGFloat = 12
    static let x: CGFloat = 0
    static let y: CGFloat = 4
}

enum HealthThresholds {
    static let lowSleepHours: Double = 5.0
    static let lowEnergyKcal: Double = 50.0
    static let consecutiveFailuresForEscalation: Int = 3
}

enum AppAnimation {
    static let micro: Double = 0.3
    static let screenTransition: Double = 0.5
    static let celebration: Double = 1.5
    static let springStiffness: Double = 170
    static let springDamping: Double = 15
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
