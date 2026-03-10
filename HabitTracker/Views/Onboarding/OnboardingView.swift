import SwiftUI

struct OnboardingView: View {
    var onGetStarted: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Very light tint so home screen is almost fully visible
            Rectangle()
                .fill(colorScheme == .dark ? Color.black.opacity(0.12) : Color.white.opacity(0.15))
                .ignoresSafeArea()
            
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
                .padding(28)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                
                Button {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    #if os(macOS)
                    dismiss()
                    #endif
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
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
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Onboarding. Track habits daily. Get started.")
    }
}

#Preview {
    OnboardingView(onGetStarted: {})
}
