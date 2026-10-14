import SwiftUI

enum Theme {
    static let backgroundTop = Color(red: 0.06, green: 0.07, blue: 0.16)
    static let backgroundBottom = Color(red: 0.12, green: 0.10, blue: 0.28)
    static let background = LinearGradient(colors: [backgroundTop, backgroundBottom], startPoint: .top, endPoint: .bottom)

    static let card = Color.white.opacity(0.07)
    static let cardStroke = Color.white.opacity(0.09)
    static let accent = Color(red: 0.36, green: 0.52, blue: 1.0)
    static let gold = Color(red: 1.0, green: 0.78, blue: 0.24)
    static let correct = Color(red: 0.20, green: 0.83, blue: 0.50)
    static let wrong = Color(red: 1.0, green: 0.36, blue: 0.40)
    static let flame = Color(red: 1.0, green: 0.55, blue: 0.20)
    static let muted = Color.white.opacity(0.55)

    static let snappy = Animation.snappy(duration: 0.22)
}

extension Font {
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Instant, springy press feedback for every tappable surface.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct CardBackground: ViewModifier {
    var radius: CGFloat = 22
    var fill: Color = Theme.card

    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Theme.cardStroke))
    }
}

extension View {
    func card(radius: CGFloat = 22, fill: Color = Theme.card) -> some View {
        modifier(CardBackground(radius: radius, fill: fill))
    }
}

/// Horizontal shake for wrong answers.
struct ShakeEffect: GeometryEffect {
    var travel: CGFloat = 9
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: travel * sin(animatableData * .pi * 6), y: 0))
    }
}
