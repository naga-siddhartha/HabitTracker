import SwiftUI
import SwiftData

// MARK: - Calendar Container

struct CalendarContainerView: View {
    @State private var selectedView: CalendarViewType = .monthly

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

// MARK: - Calendar View Type

enum CalendarViewType: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}
