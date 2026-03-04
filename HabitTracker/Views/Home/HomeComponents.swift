import SwiftUI
import SwiftData

// MARK: - Home Empty State

struct HomeEmptyState: View {
    let icon: String
    let iconColor: Color
    let title: String
    let message: String
    let buttonTitle: String
    let buttonAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(iconColor.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: buttonAction) {
                Label(buttonTitle, systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.accentColor))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 32)
    }
}

// MARK: - Checklist Row

struct ChecklistRow: View {
    @Bindable var habit: Habit
    let date: Date
    var onEdit: () -> Void
    var onDelete: () -> Void

    private var isCompleted: Bool { habit.isCompleted(on: date) }

    var body: some View {
        Button {
            withAnimation(.spring(duration: 0.25)) {
                HabitStore.shared.toggleCompletion(for: habit, on: date)
            }
        } label: {
            HStack(spacing: 18) {
                checkBox
                habitIcon
                habitInfo
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: onEdit) { Label("Edit", systemImage: "pencil") }
            Divider()
            Button(role: .destructive, action: onDelete) { Label("Delete", systemImage: "trash") }
        }
        .hapticFeedback(.light, trigger: isCompleted)
    }

    private var checkBox: some View {
        ZStack {
            Circle()
                .stroke(isCompleted ? habit.color.color : Color.systemGray4, lineWidth: 2)
                .frame(width: 34, height: 34)
            if isCompleted {
                Circle().fill(habit.color.color).frame(width: 34, height: 34)
                Image(systemName: "checkmark").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
            }
        }
        .animation(.spring(duration: 0.25), value: isCompleted)
    }

    private var habitIcon: some View {
        Image(systemName: habit.iconName ?? "circle.fill")
            .font(.system(size: 22))
            .foregroundStyle(habit.color.color)
            .frame(width: 28)
    }

    private var habitInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(habit.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isCompleted ? .secondary : .primary)
                .strikethrough(isCompleted)
            if let streak = habit.streak, streak.currentStreak > 0 {
                Text("\(streak.currentStreak) day streak").font(.footnote).foregroundStyle(.orange)
            }
        }
    }
}

// MARK: - Habit Grid Card

struct HabitGridCard: View {
    let habit: Habit
    var onEdit: () -> Void
    var onDelete: () -> Void

    private let config = LayoutConfig.current

    var body: some View {
        NavigationLink(destination: HabitDetailView(habit: habit)) {
            VStack(spacing: 12) {
                ZStack {
                    Circle().fill(habit.color.color.opacity(0.15)).frame(width: 56, height: 56)
                    Image(systemName: habit.iconName ?? "circle.fill").font(.system(size: 24)).foregroundStyle(habit.color.color)
                }

                Text(habit.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                if let streak = habit.streak, streak.currentStreak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill").font(.system(size: 10))
                        Text("\(streak.currentStreak)").font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.orange)
                } else {
                    Text(habit.frequency.rawValue.capitalized).font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.secondarySystemGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: config.cardCornerRadius))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: onEdit) { Label("Edit", systemImage: "pencil") }
            Button { habit.isArchived.toggle(); HabitStore.shared.save() } label: { Label("Archive", systemImage: "archivebox") }
            Divider()
            Button(role: .destructive, action: onDelete) { Label("Delete", systemImage: "trash") }
        }
    }
}
