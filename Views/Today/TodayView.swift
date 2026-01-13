import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \.createdAt)
    private var habits: [Habit]
    
    @Environment(\.modelContext) private var modelContext
    
    private let today = Date.now
    
    private var todayHabits: [Habit] {
        habits.filter { $0.isActive(on: today) }
    }
    
    private var completedCount: Int {
        todayHabits.filter { $0.isCompleted(on: today) }.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !todayHabits.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Progress")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ProgressView(value: Double(completedCount), total: Double(todayHabits.count))
                                .padding(.horizontal)
                                .animation(.smooth, value: completedCount)
                            
                            Text("\(completedCount) of \(todayHabits.count) habits completed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                                .contentTransition(.numericText())
                        }
                        .padding(.vertical)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Habits")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if todayHabits.isEmpty {
                            ContentUnavailableView("No habits scheduled", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else {
                            ForEach(todayHabits) { habit in
                                TodayHabitCard(habit: habit, date: today)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("Today")
        }
    }
}

struct TodayHabitCard: View {
    @Bindable var habit: Habit
    let date: Date
    @Environment(\.modelContext) private var modelContext
    @State private var showCelebration = false
    @State private var showSkipSheet = false
    
    private var isCompleted: Bool { habit.isCompleted(on: date) }
    private var isSkipped: Bool { habit.isSkipped(on: date) }
    private var currentStreak: Int { habit.streak?.currentStreak ?? 0 }
    
    var body: some View {
        Button {
            if isSkipped {
                HabitStore.shared.unskipDay(for: habit, on: date)
            } else {
                let wasCompleted = isCompleted
                withAnimation(.snappy(duration: 0.3)) {
                    HabitStore.shared.toggleCompletion(for: habit, on: date)
                }
                if !wasCompleted {
                    let newStreak = (habit.streak?.currentStreak ?? 0)
                    if newStreak > 0 && (newStreak == 7 || newStreak == 30 || newStreak == 100 || newStreak % 50 == 0) {
                        showCelebration = true
                    }
                }
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                    .font(.title2)
                    .contentTransition(.symbolEffect(.replace))
                
                if let iconName = habit.iconName {
                    Image(systemName: iconName)
                        .foregroundStyle(habit.color.color)
                        .font(.title2)
                } else {
                    Circle()
                        .fill(habit.color.color)
                        .frame(width: 40, height: 40)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.headline)
                        .strikethrough(isCompleted)
                    
                    if isSkipped {
                        Text("Skipped")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else if let desc = habit.habitDescription {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if currentStreak > 0 && !isSkipped {
                        Label("\(currentStreak) day streak", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .contentTransition(.numericText())
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                if showCelebration {
                    StreakCelebrationView(streak: currentStreak, color: habit.color.color)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showCelebration = false
                            }
                        }
                }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: isCompleted)
        .sensoryFeedback(.impact(weight: .heavy), trigger: showCelebration)
        .scaleEffect(isCompleted ? 0.98 : 1.0)
        .animation(.spring(duration: 0.2), value: isCompleted)
        .contextMenu {
            if !isCompleted {
                Button {
                    showSkipSheet = true
                } label: {
                    Label("Skip Today", systemImage: "forward.fill")
                }
            }
            
            if isSkipped {
                Button {
                    HabitStore.shared.unskipDay(for: habit, on: date)
                } label: {
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
        if isCompleted { return "checkmark.circle.fill" }
        if isSkipped { return "forward.circle.fill" }
        return "circle"
    }
    
    private var statusColor: Color {
        if isCompleted { return habit.color.color }
        if isSkipped { return .orange }
        return .secondary
    }
    
    private var backgroundColor: Color {
        if isCompleted { return habit.color.color.opacity(0.1) }
        if isSkipped { return .orange.opacity(0.1) }
        return Color.systemGray6
    }
}

struct StreakCelebrationView: View {
    let streak: Int
    let color: Color
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Confetti-like particles
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .offset(
                        x: animate ? CGFloat.random(in: -80...80) : 0,
                        y: animate ? CGFloat.random(in: -80...80) : 0
                    )
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 0.5 : 1)
            }
            
            // Streak badge
            VStack {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
                Text("\(streak) days!")
                    .font(.caption.bold())
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(animate ? 1.2 : 0.5)
            .opacity(animate ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5)) {
                animate = true
            }
        }
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
                
                // Quick reasons
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
                                    .background(reason == quickReason ? Color.orange : Color.systemGray6)
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
