import SwiftUI
import UIKit

/// Fortnightly's colours, shared by the app, the widget and the prompt. Yellow means "act now" and
/// nothing else; green, orange and red appear only on the hours-left line and the 48 tick.
public enum Palette {
    public static let shell = Color(light: 0x16204A, dark: 0x0B1030)
    public static let ground = Color(light: 0xEEF0F6, dark: 0x0D1120)
    public static let card = Color(light: 0xFFFFFF, dark: 0x161B2E)
    public static let ink = Color(light: 0x16204A, dark: 0xE8EBF5)
    public static let muted = Color(light: 0x5B6275, dark: 0x9AA2B8)
    public static let track = Color(light: 0xE3E6EF, dark: 0x252D47)
    public static let actNow = Color(light: 0xFFC21A, dark: 0xFFC21A)
    /// Buttons and links on the ground and cards.
    public static let tint = Color(light: 0x16204A, dark: 0xA5B4FC)
    /// Text on the yellow "act now" buttons.
    public static let onActNow = Color(light: 0x16204A, dark: 0x16204A)

    /// The shell for the real appearance. Navigation bars and headers on the shell force a dark colour
    /// scheme for their white text, which would otherwise turn the dynamic `shell` into its dark variant.
    public static func shell(for appearance: ColorScheme) -> Color {
        Color(hex: appearance == .dark ? 0x0B1030 : 0x16204A)
    }
}

extension EmployerColour {
    public var color: Color {
        switch self {
        case .violet: Color(light: 0x6F45E8, dark: 0x9775FA)
        case .teal: Color(light: 0x0F8FA8, dark: 0x3BC9DB)
        case .magenta: Color(light: 0xC2378A, dark: 0xF06BB6)
        case .cobalt: Color(light: 0x2F66D0, dark: 0x74A0FF)
        case .bronze: Color(light: 0x9A5B2B, dark: 0xD9A066)
        case .moss: Color(light: 0x5F7A1F, dark: 0xA9C25A)
        }
    }
}

extension WorkLimitStatus {
    public var color: Color {
        switch self {
        // Light variants are dark enough for 15 pt text on the grey ground (at least 4.5:1).
        case .withinLimit: Color(light: 0x237A35, dark: 0x51CF66)
        case .approachingLimit: Color(light: 0xB8400E, dark: 0xFF922B)
        case .overLimit: Color(light: 0xC92A2A, dark: 0xFF6B6B)
        }
    }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
