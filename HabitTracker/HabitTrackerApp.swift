import SwiftUI
import SwiftData

@main
struct HabitTrackerApp: App {
    let store = HabitStore.shared
    
    init() {
        store.updateAllStreaks()
    }
    
    var body: some Scene {
        WindowGroup {
            #if os(watchOS)
            WatchMainView()
            #else
            MainTabView()
            #endif
        }
        .modelContainer(store.modelContainer)
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

#if !os(watchOS)
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var isPresentingAddHabit = false
    @State private var isFabOpen = false
    @State private var isPresentingTemplates = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ZStack {
                HomeView()
                
                // Floating Add Button
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
                                    .shadow(radius: 3)
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
                                    .shadow(radius: 3)
                                }
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                                .buttonStyle(.plain)
                            }

                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isFabOpen.toggle() }
                            } label: {
                                Image(systemName: isFabOpen ? "xmark" : "plus")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(20)
                                    .background(Circle().fill(Color.accentColor))
                                    .shadow(radius: 4)
                            }
                            .accessibilityLabel(isFabOpen ? "Close actions" : "Add actions")
                            .buttonStyle(.plain)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 24)
                    }
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
}

struct CalendarContainerView: View {
    @State private var selectedView: CalendarViewType = .monthly
    
    enum CalendarViewType: String, CaseIterable {
        case daily = "Daily", weekly = "Weekly", monthly = "Monthly", yearly = "Yearly"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedView) {
                    ForEach(CalendarViewType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding()
                
                switch selectedView {
                case .daily: DailyView()
                case .weekly: WeeklyView()
                case .monthly: MonthlyView()
                case .yearly: YearlyView()
                }
            }
            .navigationTitle("Calendar")
            #if os(iOS)
            .inlineNavigationTitle()
            #endif
        }
    }
}
#endif

