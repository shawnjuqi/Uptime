import SwiftUI

struct SessionControlButtonStyle: ButtonStyle {
    var emphasized = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 120, height: 50)
            .background(Color.white.opacity(backgroundOpacity))
            .foregroundStyle(isEnabled ? Color.white : Color.white.opacity(0.4))
            .clipShape(.rect(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
    }

    private var backgroundOpacity: Double {
        guard isEnabled else { return 0.05 }
        return emphasized ? 0.15 : 0.1
    }

    private var strokeOpacity: Double {
        guard isEnabled else { return 0.1 }
        return emphasized ? 0.3 : 0.2
    }
}
