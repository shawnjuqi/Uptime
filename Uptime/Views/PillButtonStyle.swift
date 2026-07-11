import SwiftUI

/// The app's single button look: a white pill with bold black text,
/// matching the Start button. Use `icon: true` for a circular icon button.
struct PillButtonStyle: ButtonStyle {
    var width: CGFloat? = nil
    var icon = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        Group {
            if icon {
                configuration.label
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white))
                    .foregroundStyle(.black)
            } else {
                configuration.label
                    .font(.system(size: 15, weight: .bold))
                    .padding(.horizontal, 18)
                    .frame(width: width, height: 36)
                    .background(Capsule().fill(Color.white))
                    .foregroundStyle(.black)
            }
        }
        .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
    }
}
