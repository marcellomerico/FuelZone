import SwiftUI

struct PrimaryCTAButton: View {
    let titleKey: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(DesignSystem.accentOnAmber)
                } else {
                    Text(localized: titleKey)
                }
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isLoading)
    }
}
