import SwiftUI

// MARK: - App Colors
extension Color {
    // Greens
    static let greenPrimary = Color(hex: "#17A877")
    static let greenDark    = Color(hex: "#0E7A52")
    static let greenLight   = Color(hex: "#1BB082")

    // Text
    static let darkText     = Color(hex: "#20312A")
    static let bodyText     = Color(hex: "#2C3A32")
    static let subtitleText = Color(hex: "#8A8275")
    static let lightText    = Color(hex: "#A89F90")

    // Backgrounds
    static let screenBackground = Color(hex: "#FBF7F0")
    static let lightCardBg      = Color(hex: "#F1ECE2")
    static let dividerColor     = Color(hex: "#F4EFE6")
    static let borderColor      = Color(hex: "#ECE5D8")

    // Accents
    static let coralRed = Color(hex: "#FF6B5E")
    static let appBlue  = Color(hex: "#3B82F6")
    static let orange   = Color(hex: "#FFB020")
    static let purple   = Color(hex: "#7C6BFF")

    // Preset member colors
    static let presetColors: [Color] = [
        Color(hex: "#FF6B5E"),
        Color(hex: "#3B82F6"),
        Color(hex: "#FFB020"),
        Color(hex: "#17A877"),
        Color(hex: "#7C6BFF"),
    ]

    static let presetHexColors: [String] = [
        "#FF6B5E", "#3B82F6", "#FFB020", "#17A877", "#7C6BFF"
    ]

    init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h = String(h.dropFirst()) }
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return "#888888"
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Green Gradient
extension LinearGradient {
    static let greenGradient = LinearGradient(
        colors: [.greenLight, .greenDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let greenVertical = LinearGradient(
        colors: [.greenLight, .greenDark],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = 22
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 22) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius))
    }
}

// MARK: - Currency Formatter
extension Double {
    var euroFormatted: String {
        let formatted = String(format: "%.2f", self).replacingOccurrences(of: ".", with: ",")
        return "\(formatted) €"
    }
}
