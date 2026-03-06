import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

// MARK: - Home Empty State

struct HomeEmptyState: View {
    let icon: String
    let iconColor: Color
    let title: String
    let message: String
    let primaryButtonTitle: String
    let primaryButtonAction: () -> Void
    let secondaryButtonTitle: String
    let secondaryButtonAction: () -> Void

    private var secondaryButtonBackground: Color {
        #if os(iOS)
        Color(uiColor: .quaternarySystemFill)
        #elseif os(macOS)
        Color(nsColor: .quaternarySystemFill)
        #else
        Color.primary.opacity(0.06)
        #endif
    }

    private var primaryButtonBackground: Color {
        Color.accentColor.opacity(0.15)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Message block: icon + copy grouped together
            VStack(alignment: .center, spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 96, height: 96)
                    Image(systemName: icon)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .center, spacing: 8) {
                    Text(title)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 28)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)

            // Separator so the button reads as the card’s action, not another line of text
            Divider()
                .padding(.horizontal, 24)

            VStack(spacing: 12) {
                Button(action: primaryButtonAction) {
                    Label(primaryButtonTitle, systemImage: "plus.circle")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(primaryButtonBackground, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                Button(action: secondaryButtonAction) {
                    Label(secondaryButtonTitle, systemImage: "square.grid.2x2")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(secondaryButtonBackground, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 20)
    }
}

// MARK: - Checklist Row

struct ChecklistRow: View {
    @Bindable var habit: Habit
    let date: Date
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onViewDescription: (() -> Void)? = nil

    private var isCompleted: Bool { habit.isCompleted(on: date) }

    private var timeLabel: String {
        habit.reminderTimes.isEmpty ? "All day" : habit.reminderTimes.first!.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        HStack(spacing: 18) {
            Button {
                withAnimation(.spring(duration: 0.25)) {
                    HabitStore.shared.toggleCompletion(for: habit, on: date)
                }
            } label: { checkBox }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .hapticFeedback(.light, trigger: isCompleted)
            Button {
                onViewDescription?()
            } label: {
                HStack(spacing: 18) {
                    habitIcon
                    habitInfo
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Menu {
                HabitRowActions(
                    onViewDetails: { onViewDescription?() },
                    onEdit: onEdit,
                    onDelete: onDelete
                )
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .contextMenu {
            HabitRowActions(
                onViewDetails: { onViewDescription?() },
                onEdit: onEdit,
                onDelete: onDelete
            )
        }
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
        .frame(width: 34, height: 34)
        .contentShape(Rectangle())
        .animation(.spring(duration: 0.25), value: isCompleted)
    }

    private var habitIcon: some View {
        Group {
            if let emoji = habit.emoji, !emoji.isEmpty {
                Text(emoji).font(.system(size: 22))
            } else {
                Image(systemName: habit.iconName ?? "circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(habit.color.color)
            }
        }
        .frame(width: 28)
    }

    private var habitInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(habit.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isCompleted ? .secondary : .primary)
                .strikethrough(isCompleted)
            Text(timeLabel)
                .font(.footnote)
                .foregroundStyle(.secondary)
            if isCompleted, let streak = habit.streak, streak.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").font(.system(size: 10))
                    Text("\(streak.currentStreak) day streak").font(.footnote).foregroundStyle(.orange)
                }
            }
        }
    }
}

// MARK: - Ad Card (sleek slot for home page ads)

struct AdCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Advertisement".uppercased().map { String($0) }.joined(separator: " "))
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)
            #if os(iOS)
            AdMobBannerView()
            #endif
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.05), lineWidth: 1)
        )
        .shadow(
            color: colorScheme == .dark ? .white.opacity(0.04) : .black.opacity(0.05),
            radius: 8,
            x: 0,
            y: 3
        )
    }
}

// MARK: - Scheduled Row (habit + time, for Scheduled card)

struct ScheduledRow: View {
    let habit: Habit
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onViewDescription: (() -> Void)? = nil

    private var timeLabel: String {
        habit.reminderTimes.isEmpty ? "—" : habit.reminderTimes.first!.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        HStack(spacing: 18) {
            Button {
                onViewDescription?()
            } label: {
                HStack(spacing: 18) {
                    Group {
                        if let emoji = habit.emoji, !emoji.isEmpty {
                            Text(emoji).font(.system(size: 22))
                        } else {
                            Image(systemName: habit.iconName ?? "circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(habit.color.color)
                        }
                    }
                    .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name)
                            .font(.system(size: 18, weight: .semibold))
                        Text(timeLabel)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Menu {
                HabitRowActions(
                    onViewDetails: { onViewDescription?() },
                    onEdit: onEdit,
                    onDelete: onDelete
                )
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            HabitRowActions(
                onViewDetails: { onViewDescription?() },
                onEdit: onEdit,
                onDelete: onDelete
            )
        }
    }
}

