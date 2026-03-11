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

    private let config = LayoutConfig.current

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
            VStack(alignment: .center, spacing: config.spacingM + 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: config.cardCornerRadius + 12)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 96, height: 96)
                    Image(systemName: icon)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .center, spacing: config.spacingS) {
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
            .padding(.top, config.spacingXXL + 4)
            .padding(.horizontal, config.spacingXXL)
            .padding(.bottom, config.spacingXXL)

            // Separator so the button reads as the card’s action, not another line of text
            Divider()
                .padding(.horizontal, config.spacingXXL)

            VStack(spacing: config.spacingM) {
                Button(action: primaryButtonAction) {
                    Label(primaryButtonTitle, systemImage: "plus.circle")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, config.spacingL)
                        .background(primaryButtonBackground, in: RoundedRectangle(cornerRadius: config.cornerRadiusMedium + 2))
                }
                .buttonStyle(.plain)
                Button(action: secondaryButtonAction) {
                    Label(secondaryButtonTitle, systemImage: "square.grid.2x2")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, config.spacingL)
                        .background(secondaryButtonBackground, in: RoundedRectangle(cornerRadius: config.cornerRadiusMedium + 2))
                }
                .buttonStyle(.plain)
            }
            .padding(config.spacingXL)
        }
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: config.cardCornerRadius + 2))
        .padding(.horizontal, config.spacingXL)
    }
}

// MARK: - Checklist Row

struct ChecklistRow: View {
    @Bindable var habit: Habit
    let date: Date
    private let config = LayoutConfig.current
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onViewDescription: (() -> Void)? = nil
    var onUnskip: (() -> Void)? = nil
    var onSkipWithReason: (() -> Void)? = nil
    var onTapSkipReason: ((String) -> Void)? = nil

    private var isCompleted: Bool { habit.isCompleted(on: date) }
    private var isSkipped: Bool { habit.isSkipped(on: date) }
    private var skipReason: String? { habit.entry(for: date)?.skipReason }

    private var timeLabel: String {
        habit.reminderTimes.isEmpty ? "All day" : habit.reminderTimes.first!.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        HStack(spacing: config.spacingM + 6) {
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
                HStack(spacing: config.spacingM + 6) {
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
                    onDelete: onDelete,
                    showSkipUnskip: true,
                    isSkippedOnDate: isSkipped,
                    onUnskip: onUnskip,
                    onSkipWithReason: onSkipWithReason
                )
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: config.iconSizeRow + 2))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, config.spacingL)
        .padding(.vertical, config.spacingL)
        .background(habit.displayColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: config.cardCornerRadius))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(habit.name), \(isSkipped ? "Skipped" : (isCompleted ? "Completed" : "Not completed"))")
        .accessibilityHint(isCompleted ? "Double tap to uncheck" : "Double tap to mark complete")
        .contextMenu {
            HabitRowActions(
                onViewDetails: { onViewDescription?() },
                onEdit: onEdit,
                onDelete: onDelete,
                showSkipUnskip: true,
                isSkippedOnDate: isSkipped,
                onUnskip: onUnskip,
                onSkipWithReason: onSkipWithReason
            )
        }
    }

    private var checkBox: some View {
        ZStack {
            if isSkipped {
                Circle()
                    .stroke(Color.orange, lineWidth: 2)
                    .frame(width: config.checkboxSize, height: config.checkboxSize)
                Image(systemName: "pause.fill")
                    .font(.system(size: config.cornerRadiusMedium + 2))
                    .foregroundStyle(.orange)
            } else {
                Circle()
                    .stroke(isCompleted ? habit.displayColor : Color.systemGray4, lineWidth: 2)
                    .frame(width: config.checkboxSize, height: config.checkboxSize)
                if isCompleted {
                    Circle().fill(habit.displayColor).frame(width: config.checkboxSize, height: config.checkboxSize)
                    Image(systemName: "checkmark").font(.system(size: config.spacingL, weight: .bold)).foregroundStyle(.white)
                }
            }
        }
        .frame(width: config.checkboxSize, height: config.checkboxSize)
        .contentShape(Rectangle())
        .animation(.spring(duration: 0.25), value: isCompleted)
        .animation(.spring(duration: 0.25), value: isSkipped)
    }

    private var habitIcon: some View {
        Group {
            if let emoji = habit.emoji, !emoji.isEmpty {
                Text(emoji).font(.system(size: config.iconSizeRow + 2))
            } else {
                Image(systemName: habit.iconName ?? "circle.fill")
                    .font(.system(size: config.iconSizeRow + 2))
                    .foregroundStyle(habit.displayColor)
            }
        }
        .frame(width: config.iconSizeRow)
    }

    private var skipReasonDisplayText: String {
        guard isSkipped else { return timeLabel }
        return skipReason.flatMap { $0.isEmpty ? nil : "Skipped · \($0)" } ?? "Skipped"
    }

    private var habitInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(habit.name)
                .font(.system(size: config.spacingM + 6, weight: .semibold))
                .foregroundStyle(isCompleted || isSkipped ? .secondary : .primary)
                .strikethrough(isCompleted)
            Group {
                if isSkipped, skipReason != nil, !(skipReason?.isEmpty ?? true) {
                    Button {
                        onTapSkipReason?(skipReasonDisplayText)
                    } label: {
                        Text(skipReasonDisplayText)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Double tap to show full reason")
                } else {
                    Text(skipReasonDisplayText)
                        .font(.footnote)
                        .foregroundStyle(isSkipped ? .orange : .secondary)
                        .lineLimit(isSkipped ? 2 : 1)
                        .truncationMode(.tail)
                }
            }
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
    private let config = LayoutConfig.current

    private var timeLabel: String {
        habit.reminderTimes.isEmpty ? "—" : habit.reminderTimes.first!.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        HStack(spacing: config.spacingM + 6) {
            Button {
                onViewDescription?()
            } label: {
                HStack(spacing: config.spacingM + 6) {
                    Group {
                        if let emoji = habit.emoji, !emoji.isEmpty {
                            Text(emoji).font(.system(size: config.iconSizeRow + 2))
                        } else {
                            Image(systemName: habit.iconName ?? "circle.fill")
                                .font(.system(size: config.iconSizeRow + 2))
                                .foregroundStyle(habit.displayColor)
                        }
                    }
                    .frame(width: config.iconSizeRow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name)
                            .font(.system(size: config.spacingM + 6, weight: .semibold))
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
                    .font(.system(size: config.iconSizeRow + 2))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, config.spacingL)
        .padding(.vertical, config.spacingM)
        .background(habit.displayColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: config.cardCornerRadius))
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

