import SwiftUI
import SwiftData

#if !os(watchOS)
// MARK: - Main Tab View

struct MainTabView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived }) private var habits: [Habit]
    @State private var selectedTab = 0
    @State private var isPresentingAddHabit = false
    @State private var isFabOpen = false
    @State private var isPresentingTemplates = false

    private var hasHabits: Bool { !habits.isEmpty }

    var body: some View {
        TabView(selection: $selectedTab) {
            ZStack {
                HomeView()

                if hasHabits && selectedTab == 0 {
                    fabOverlay
                }
            }
            .sheet(isPresented: $isPresentingAddHabit) {
                AddEditHabitView()
            }
            .sheet(isPresented: $isPresentingTemplates) {
                HabitTemplatesView()
            }
            .tag(0)
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            CalendarContainerView()
                .tag(1)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            StatisticsView()
                .tag(2)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tag(3)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }

    private var fabOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    if isFabOpen {
                        Button {
                            isPresentingTemplates = true
                            isFabOpen = false
                        } label: {
                            HStack(spacing: 8) {
                                Text("Templates").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                                Image(systemName: "square.grid.2x2").font(.headline).foregroundStyle(.white)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color.purple))
                            .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .buttonStyle(.plain)

                        Button {
                            isPresentingAddHabit = true
                            isFabOpen = false
                        } label: {
                            HStack(spacing: 8) {
                                Text("New Habit").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                                Image(systemName: "plus").font(.headline).foregroundStyle(.white)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color.accentColor))
                            .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .buttonStyle(.plain)
                    }

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isFabOpen.toggle() }
                    } label: {
                        Image(systemName: isFabOpen ? "xmark" : "plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(Color.accentColor))
                            .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
                    }
                    .accessibilityLabel(isFabOpen ? "Close actions" : "Add actions")
                    .buttonStyle(.plain)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
        }
    }
}
#endif
