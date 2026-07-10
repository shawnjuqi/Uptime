import SwiftUI

struct SessionControlButtonStyle: ButtonStyle {
    var emphasized = false
    var width: CGFloat = 120

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        Group {
            if emphasized {
                // X/Twitter-style primary action: white pill, bold black text
                configuration.label
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: width, height: 36)
                    .background(Capsule().fill(Color.white))
                    .foregroundStyle(.black)
                    .opacity(isEnabled ? 1 : 0.4)
            } else {
                configuration.label
                    .frame(width: width, height: 36)
                    .background(Color.white.opacity(0.1))
                    .foregroundStyle(Color.white)
                    .clipShape(.rect(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
