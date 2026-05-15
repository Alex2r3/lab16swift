import SwiftUI

struct Theme {
    static let black = Color(red: 0.05, green: 0.05, blue: 0.05)
    static let darkGray = Color(red: 0.1, green: 0.1, blue: 0.12)
    static let deepBlue = Color(red: 0.05, green: 0.07, blue: 0.15)
    static let accentRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    static let accentYellow = Color(red: 0.95, green: 0.75, blue: 0.2)
    
    static let mainGradient = LinearGradient(
        gradient: Gradient(colors: [deepBlue, black]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    func cinematicStyle() -> some View {
        self.modifier(CinematicModifier())
    }
}

struct CinematicModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
    }
}
