import SwiftUI

struct ChoiceButton: View {
    let choice: Choice
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(choice.text)
                .font(.custom("AvenirNext-Medium", size: 16))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(choice.isCritical ? Theme.accentRed.opacity(0.3) : Color.white.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(choice.isCritical ? Theme.accentRed : Color.white.opacity(0.2), lineWidth: 1))
                )
        }
    }
}
