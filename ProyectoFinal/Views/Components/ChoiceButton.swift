import SwiftUI

struct ChoiceButton: View {
    let choice: Choice
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Indicador de bala
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .padding(.leading, 4)
                
                Text(choice.text)
                    .font(.custom("AvenirNext-Medium", size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true) // El texto NUNCA se corta
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.black.opacity(0.75))   // Fondo oscuro para legibilidad
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.06))  // Toque vidrioso sutil
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}


struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

