import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(sort: \Habit.createdAt, order: .reverse) private var allHabits: [Habit]
    @State private var showingAddHabit = false
    @State private var showingTemplates = false
    @State private var showAllHabits = false
    
    private let today = Date.now
    
    private var habits: [Habit] { allHabits.filter { !$0.isArchived } }
    private var todayHabits: [Habit] { habits.filter { $0.isActive(on: today) } }
    private var completedCount: Int { todayHabits.filter { $0.isCompleted(on: today) }.count }
    private var progress: Double { todayHabits.isEmpty ? 0 : Double(completedCount) / Double(todayHabits.count) }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with date
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(today.formatted(.dateTime.weekday(.wide)))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(today.formatted(.dateTime.month().day()))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                        }
                        Spacer()
                    }
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Progress card (only show if there are habits)
                    if !todayHabits.isEmpty {
                        HStack(spacing: 16) {
                            ProgressRing(progress: progress, count: completedCount, total: todayHabits.count)
                                .frame(width: 56, height: 56)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(completedCount) of \(todayHabits.count) complete")
                                    .font(.headline)
                                Text(motivationalMessage)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                        .frame(maxWidth: 600)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                    }
                    
                    // Tab bar: Today | All Tasks | +
                    HStack(spacing: 0) {
                        Button { showAllHabits = false } label: {
                            Text("Today")
                                .font(.subheadline.weight(showAllHabits ? .regular : .semibold))
                                .foregroundStyle(showAllHabits ? .secondary : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(showAllHabits ? Color.clear : Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        
                        Button { showAllHabits = true } label: {
                            Text("Habits")
                                .font(.subheadline.weight(showAllHabits ? .semibold : .regular))
                                .foregroundStyle(showAllHabits ? .primary : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(showAllHabits ? Color(.systemBackground) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        
                        Menu {
                            Button { showingAddHabit = true } label: {
                                Label("Create Custom", systemImage: "plus")
                            }
                            Button { showingTemplates = true } label: {
                                Label("From Template", systemImage: "square.grid.2x2")
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(4)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    
                    // Content
                    if showAllHabits {
                        allHabitsSection
                    } else {
                        todaySection
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddHabit) { AddEditHabitView() }
            .sheet(isPresented: $showingTemplates) { HabitTemplatesView() }
        }
    }
    
    private var todaySection: some View {
        Group {
            if todayHabits.isEmpty {
                EmptyStateView(onAdd: { showingTemplates = true })
                    .padding(.top, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(todayHabits) { habit in
                        HabitCard(habit: habit, date: today)
                    }
                }
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var allHabitsSection: some View {
        Group {
            if habits.isEmpty {
                EmptyStateView(onAdd: { showingTemplates = true })
                    .padding(.top, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(habits) { habit in
                        NavigationLink(destination: HabitDetailView(habit: habit)) {
                            HabitRow(habit: habit)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .contextMenu {
                            Button(role: .destructive) {
                                NotificationService.shared.removeReminders(for: habit.id)
                                HabitStore.shared.deleteHabit(habit)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                habit.isArchived.toggle()
                                HabitStore.shared.save()
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                        }
                    }
                }
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var motivationalMessage: String {
        if completedCount == todayHabits.count && completedCount > 0 {
            return "🎉 All done! You're on fire today."
        } else if progress >= 0.5 {
            return "💪 Great progress! Keep it up."
        } else if completedCount > 0 {
            return "✨ Good start! \(todayHabits.count - completedCount) more to go."
        } else {
            return "👋 Ready to build some habits?"
        }
    }
}

struct ProgressRing: View {
    let progress: Double
    let count: Int
    let total: Int
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 6)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(progress == 1 ? Color.green : Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.5), value: progress)
            VStack(spacing: 0) {
                Text("\(count)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("/\(total)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct HabitCard: View {
    @Bindable var habit: Habit
    let date: Date
    @State private var showSkipSheet = false
    
    private var isCompleted: Bool { habit.isCompleted(on: date) }
    private var isSkipped: Bool { habit.isSkipped(on: date) }
    private var streak: Int { habit.streak?.currentStreak ?? 0 }
    
    var body: some View {
        Button {
            withAnimation(.spring(duration: 0.3)) {
                if isSkipped {
                    HabitStore.shared.unskipDay(for: habit, on: date)
                } else {
                    HabitStore.shared.toggleCompletion(for: habit, on: date)
                }
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(habit.color.color.opacity(isCompleted ? 1 : 0.15))
                        .frame(width: 48, height: 48)
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    } else if let iconName = habit.iconName {
                        Image(systemName: iconName)
                            .font(.system(size: 20))
                            .foregroundStyle(habit.color.color)
                    }
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(habit.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isCompleted ? .secondary : .primary)
                        .strikethrough(isCompleted, color: .secondary)
                    
                    if isSkipped {
                        Text("Skipped").font(.system(size: 13)).foregroundStyle(.orange)
                    } else if streak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill").font(.system(size: 11))
                            Text("\(streak) day streak").font(.system(size: 13))
                        }
                        .foregroundStyle(.orange)
                    } else if let desc = habit.habitDescription {
                        Text(desc).font(.system(size: 13)).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                
                Spacer()
                
                if !isCompleted && !isSkipped {
                    Circle()
                        .strokeBorder(Color(.systemGray4), lineWidth: 2)
                        .frame(width: 26, height: 26)
                }
            }
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
        .contextMenu {
            if !isCompleted && !isSkipped {
                Button { showSkipSheet = true } label: { Label("Skip Today", systemImage: "forward.fill") }
            }
            if isSkipped {
                Button { HabitStore.shared.unskipDay(for: habit, on: date) } label: { Label("Undo Skip", systemImage: "arrow.uturn.backward") }
            }
        }
        .sheet(isPresented: $showSkipSheet) {
            SkipSheet(habit: habit, date: date).presentationDetents([.height(280)])
        }
        .sensoryFeedback(.impact(weight: .light), trigger: isCompleted)
    }
}

struct HabitRow: View {
    let habit: Habit
    private var streak: Int { habit.streak?.currentStreak ?? 0 }
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(habit.color.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                if let iconName = habit.iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(habit.color.color)
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                if streak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill").font(.system(size: 11))
                        Text("\(streak) day streak").font(.system(size: 13))
                    }
                    .foregroundStyle(.orange)
                } else if let desc = habit.habitDescription {
                    Text(desc).font(.system(size: 13)).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct EmptyStateView: View {
    var onAdd: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green.opacity(0.6))
            VStack(spacing: 8) {
                Text("No habits yet")
                    .font(.title3.bold())
                Text("Start building habits that stick")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let onAdd {
                Button(action: onAdd) {
                    Text("Browse Templates")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

struct SkipSheet: View {
    let habit: Habit
    let date: Date
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    private let reasons = ["Vacation", "Sick", "Rest day", "Busy", "Travel"]
    
    var body: some View {
        VStack(spacing: 20) {
            Capsule().fill(Color(.systemGray4)).frame(width: 36, height: 5).padding(.top, 8)
            Text("Skip \(habit.name)?").font(.headline)
            Text("Your streak won't be affected").font(.subheadline).foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(reasons, id: \.self) { r in
                        Button { reason = r } label: {
                            Text(r)
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(reason == r ? Color.orange : Color(.systemGray6))
                                .foregroundStyle(reason == r ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            
            Button {
                HabitStore.shared.skipDay(for: habit, on: date, reason: reason.isEmpty ? nil : reason)
                dismiss()
            } label: {
                Text("Skip Today")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            Spacer()
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: Habit.self, inMemory: true)
}
