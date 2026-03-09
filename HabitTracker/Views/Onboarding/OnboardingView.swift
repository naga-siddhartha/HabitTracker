import SwiftUI

struct OnboardingView: View {
    var onGetStarted: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.green)
                Text("Track habits daily")
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)
                Text("Build streaks and stay consistent. Skip a day when you need to—your streak stays intact.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Text("Start with a template or create your first habit.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 48)
            
            Button {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onGetStarted()
                }
            } label: {
                Text("Get started")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appGroupedBackground)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Onboarding. Track habits daily. Get started.")
    }
}

#Preview {
    OnboardingView(onGetStarted: {})
}
