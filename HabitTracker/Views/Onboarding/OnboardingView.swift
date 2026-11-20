import SwiftUI

/// First-launch welcome, shown as a sheet over Home.
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
                .symbolRenderingMode(.hierarchical)
                .padding(.top, 8)
            Text("Track habits daily")
                .font(.title.weight(.bold))
            Text("Build streaks and stay consistent. Skip a day when you need to; your streak stays intact.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
            Button {
                dismiss()
            } label: {
                Text("Get started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(28)
        #if os(macOS)
        .frame(width: 380, height: 320)
        #endif
    }
}

#Preview {
    OnboardingView()
}
