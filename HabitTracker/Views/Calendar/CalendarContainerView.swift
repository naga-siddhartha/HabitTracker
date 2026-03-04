import SwiftUI
import SwiftData

// MARK: - Calendar Container

struct CalendarContainerView: View {
    @State private var selectedView: CalendarViewType = .monthly

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                PageHeading(title: "Calendar")
                    .padding(.bottom, 4)

                Picker("View", selection: $selectedView) {
                    ForEach(CalendarViewType.allCases, id: \.self) { view in
                        Text(view.rawValue)
                            .font(.system(size: 17, weight: .semibold))
                            .tag(view)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
                .labelsHidden()
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)

                switch selectedView {
                case .daily: DailyView()
                case .weekly: WeeklyView()
                case .monthly: MonthlyView()
                case .yearly: YearlyView()
                }
            }
            .navigationTitle("")
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
