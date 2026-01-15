import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Habit.createdAt, order: .reverse) private var allHabits: [Habit]
    @State private var showingAddHabit = false
    @State private var showingTemplates = false
    @State private var selectedTab: HomeTab = .active
    @State private var editingHabit: Habit?
    
    private let config = LayoutConfig.current
    
    enum HomeTab: String, CaseIterable {
        case active = "Active"
        case all = "All Habits"
    }
    
    private let today = Date.now
    private var habits: [Habit] { allHabits.filter { !$0.isArchived } }
    private var todayHabits: [Habit] { habits.filter { $0.isActive(on: today) } }
    private var completedCount: Int { todayHabits.filter { $0.isCompleted(on: today) }.count }
    private var progress: Double { todayHabits.isEmpty ? 0 : Double(completedCount) / Double(todayHabits.count) }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    segmentedPicker
                    
                    if selectedTab == .active {
                        activeSection
                    } else {
                        allHabitsSection
                    }
                }
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.systemGray6)
            .inlineNavigationTitle()
            .sheet(isPresented: $showingAddHabit) { AddEditHabitView() }
            .sheet(isPresented: $showingTemplates) { HabitTemplatesView() }
            .sheet(item: $editingHabit) { AddEditHabitView(habit: $0) }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(today.formatted(.dateTime.weekday(.wide)))
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(today.formatted(.dateTime.month(.wide).day()))
                .font(.system(size: 34, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: config.contentMaxWidth, alignment: .leading)
        .padding(.horizontal, config.horizontalPadding)
        .padding(.top, 12)
    }
    
    // MARK: - Segmented Picker
    
    private var segmentedPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(HomeTab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
        .labelsHidden()
        .padding(.horizontal, config.horizontalPadding)
        .frame(maxWidth: config.contentMaxWidth)
    }
    
    // MARK: - Active Section
    
    private var activeSection: some View {
        Group {
            if todayHabits.isEmpty {
                EmptyState(
                    icon: "checkmark.circle",
                    iconColor: .green,
                    title: "All caught up!",
                    message: "No habits scheduled for today.",
                    buttonTitle: "Add Habit",
                    buttonAction: { showingAddHabit = true }
                )
            } else {
                VStack(spacing: 0) {
                    progressHeader
                    Divider()
                    checklistItems
                }
                .background(Color.systemBackground)
                .clipShape(RoundedRectangle(cornerRadius: config.cardCornerRadius))
                .frame(maxWidth: config.contentMaxWidth)
                .padding(.horizontal, config.horizontalPadding)
            }
        }
    }
    
    private var progressHeader: some View {
        HStack {
            ProgressRing(progress: progress, count: completedCount, total: todayHabits.count, size: 60)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(completedCount)/\(todayHabits.count) completed").font(.headline.weight(.semibold))
                Text(motivationalMessage).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
    }
    
    private var checklistItems: some View {
        ForEach(Array(todayHabits.enumerated()), id: \.element.id) { index, habit in
            ChecklistRow(habit: habit, date: today, onEdit: { editingHabit = habit }, onDelete: { deleteHabit(habit) })
            if index < todayHabits.count - 1 {
                Divider().padding(.leading, 96)
            }
        }
    }
    
    // MARK: - All Habits Section
    
    private var allHabitsSection: some View {
        Group {
            if habits.isEmpty {
                EmptyState(
                    icon: "square.grid.2x2",
                    iconColor: .purple,
                    title: "No habits yet",
                    message: "Build lasting habits with templates",
                    buttonTitle: "Browse Templates",
                    buttonColor: .purple,
                    buttonAction: { showingTemplates = true }
                )
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(habits) { habit in
                        HabitGridCard(habit: habit, onEdit: { editingHabit = habit }, onDelete: { deleteHabit(habit) })
                    }
                }
                .frame(maxWidth: config.contentMaxWidth)
                .padding(.horizontal, config.horizontalPadding)
            }
        }
    }
    
    private var motivationalMessage: String {
        if completedCount == todayHabits.count && completedCount > 0 { return "All done! 🎉" }
        if progress >= 0.5 { return "Keep going! 💪" }
        if completedCount > 0 { return "\(todayHabits.count - completedCount) left" }
        return "Let's start! 👋"
    }
    
    private func deleteHabit(_ habit: Habit) {
        NotificationService.shared.removeReminders(for: habit.id)
        HabitStore.shared.deleteHabit(habit)
    }
}

// MARK: - Empty State

struct EmptyState: View {
    let icon: String
    let iconColor: Color
    let title: String
    let message: String
    let buttonTitle: String
    var buttonColor: Color = .accentColor
    let buttonAction: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)
            
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundStyle(iconColor)
            }
            
            VStack(spacing: 8) {
                Text(title).font(.title2.bold())
                Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            
            AdaptiveButton(buttonTitle, icon: nil, action: buttonAction)
                .tint(buttonColor)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
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
            .background(Color.systemBackground)
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

// MARK: - Skip Sheet

struct SkipSheet: View {
    let habit: Habit
    let date: Date
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    private let reasons = ["Vacation", "Sick", "Rest day", "Busy", "Travel"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Skip \(habit.name)?").font(.headline)
            Text("Your streak won't be affected").font(.subheadline).foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                ForEach(reasons, id: \.self) { r in
                    Button { reason = r } label: {
                        Text(r)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(reason == r ? Color.orange : Color.systemGray6)
                            .foregroundStyle(reason == r ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            HStack {
                AdaptiveSecondaryButton("Cancel") { dismiss() }
                AdaptiveButton("Skip Today") {
                    HabitStore.shared.skipDay(for: habit, on: date, reason: reason.isEmpty ? nil : reason)
                    dismiss()
                }
                .tint(.orange)
            }
        }
        .padding(24)
        .frame(minWidth: LayoutConfig.current.sheetWidth ?? 300)
    }
}

#Preview {
    HomeView().modelContainer(for: Habit.self, inMemory: true)
}

