import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \.createdAt)
    private var habits: [Habit]
    
    private let today = Date.now
    
    private var todayHabits: [Habit] {
        habits.filter { $0.isActive(on: today) }
    }
    
    private var completedCount: Int {
        todayHabits.filter { $0.isCompleted(on: today) }.count
    }
    
    private var progress: Double {
        todayHabits.isEmpty ? 0 : Double(completedCount) / Double(todayHabits.count)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    VStack(spacing: 16) {
                        Text(today, format: .dateTime.weekday(.wide).month().day())
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        // Progress Ring
                        ZStack {
                            Circle()
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 12)
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(progressColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(duration: 0.5), value: progress)
                            
                            VStack(spacing: 4) {
                                Text("\(completedCount)")
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .contentTransition(.numericText())
                                Text("of \(todayHabits.count)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 140, height: 140)
                        
                        Text(motivationalMessage)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)
                    
                    // Habits List
                    if todayHabits.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.green)
                            Text("No habits for today")
                                .font(.headline)
                            Text("Add habits to start tracking")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(todayHabits) { habit in
                                TodayHabitCard(habit: habit, date: today)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Today")
        }
    }
    
    private var progressColor: Color {
        if progress >= 1 { return .green }
        if progress >= 0.5 { return .blue }
        return .orange
    }
    
    private var motivationalMessage: String {
        if todayHabits.isEmpty { return "Add some habits!" }
        if completedCount == todayHabits.count { return "🎉 All done! Great job!" }
        if completedCount == 0 { return "Let's get started!" }
        if progress >= 0.5 { return "Keep going, you're doing great!" }
        return "You've got this!"
    }
}

struct TodayHabitCard: View {
    @Bindable var habit: Habit
    let date: Date
    @State private var showSkipSheet = false
    
    private var isCompleted: Bool { habit.isCompleted(on: date) }
    private var isSkipped: Bool { habit.isSkipped(on: date) }
    private var currentStreak: Int { habit.streak?.currentStreak ?? 0 }
    
    var body: some View {
        Button {
            withAnimation(.snappy(duration: 0.3)) {
                if isSkipped {
                    HabitStore.shared.unskipDay(for: habit, on: date)
                } else {
                    HabitStore.shared.toggleCompletion(for: habit, on: date)
                }
            }
        } label: {
            HStack(spacing: 14) {
                // Status indicator
                ZStack {
                    Circle()
                        .fill(isCompleted ? habit.color.color : Color(.tertiarySystemFill))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: statusIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isCompleted ? .white : (isSkipped ? .orange : .secondary))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.body.weight(.medium))
                        .strikethrough(isCompleted, color: .secondary)
                        .foregroundStyle(isCompleted ? .secondary : .primary)
                    
                    if currentStreak > 0 {
                        Label("\(currentStreak) days", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                Spacer()
                
                if let iconName = habit.iconName {
                    Image(systemName: iconName)
                        .font(.title3)
                        .foregroundStyle(habit.color.color.opacity(isCompleted ? 0.5 : 1))
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: isCompleted)
        .contextMenu {
            if !isCompleted && !isSkipped {
                Button { showSkipSheet = true } label: {
                    Label("Skip Today", systemImage: "forward.fill")
                }
            }
            if isSkipped {
                Button { HabitStore.shared.unskipDay(for: habit, on: date) } label: {
                    Label("Undo Skip", systemImage: "arrow.uturn.backward")
                }
            }
        }
        .sheet(isPresented: $showSkipSheet) {
            SkipDaySheet(habit: habit, date: date)
                .presentationDetents([.height(250)])
        }
    }
    
    private var statusIcon: String {
        if isCompleted { return "checkmark" }
        if isSkipped { return "forward.fill" }
        return "circle"
    }
}

struct SkipDaySheet: View {
    let habit: Habit
    let date: Date
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    
    private let quickReasons = ["Vacation", "Sick", "Rest day", "Busy", "Travel"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Skip \(habit.name)?")
                    .font(.headline)
                
                Text("Your streak won't be broken")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickReasons, id: \.self) { quickReason in
                            Button {
                                reason = quickReason
                            } label: {
                                Text(quickReason)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(reason == quickReason ? Color.orange : Color(.tertiarySystemFill))
                                    .foregroundStyle(reason == quickReason ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                TextField("Or add custom reason...", text: $reason)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    HabitStore.shared.skipDay(for: habit, on: date, reason: reason.isEmpty ? nil : reason)
                    dismiss()
                } label: {
                    Text("Skip Today")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: Habit.self, inMemory: true)
}
