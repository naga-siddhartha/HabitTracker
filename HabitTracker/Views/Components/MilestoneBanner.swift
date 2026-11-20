import SwiftUI

/// Gold celebration banner for a streak milestone. Dismisses itself after a few seconds.
struct MilestoneBanner: View {
    let event: MilestoneEvent
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(Color.rewardGold)
                .symbolEffect(.bounce, value: event.id)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(event.days)-day streak")
                    .font(.headline)
                Text([event.emoji, event.habitName].compactMap { $0 }.joined(separator: " "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background { background }
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
        .sensoryFeedback(.success, trigger: event.id)
        .task(id: event.id) {
            try? await Task.sleep(for: .seconds(4))
            onDismiss()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        if #available(iOS 26.0, macOS 26.0, *) {
            Color.clear.glassEffect(.regular.tint(Color.rewardGold.opacity(0.25)), in: shape)
        } else {
            shape.fill(.regularMaterial)
                .overlay(shape.strokeBorder(Color.rewardGold.opacity(0.5), lineWidth: 1))
        }
    }
}
