import SwiftUI

/// "‹ Friday, Nov 20 ›" day picker: arrows step a day, the title opens a calendar,
/// and Today jumps back when another day is shown.
struct DaySwitcher: View {
    @Binding var date: Date
    @State private var showingCalendar = false
    private let calendar = Calendar.current

    private var isToday: Bool { calendar.isDateInToday(date) }

    var body: some View {
        HStack(spacing: 8) {
            stepButton(-1, symbol: "chevron.left", label: "Previous day")

            Button {
                showingCalendar = true
            } label: {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens a calendar to pick a day")
            .popover(isPresented: $showingCalendar, arrowEdge: .bottom) {
                DatePicker("Day", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(Color.brandPurple)
                    .padding()
                    .frame(minWidth: 300)
                    .presentationCompactAdaptation(.popover)
                    .onChange(of: date) { showingCalendar = false }
            }

            stepButton(1, symbol: "chevron.right", label: "Next day")

            if !isToday {
                Button("Today") { withAnimation { date = .now } }
                    .font(.subheadline.weight(.semibold))
                    .tint(Color.brandPurple)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .transition(.opacity)
            }
        }
        .animation(.snappy, value: isToday)
    }

    private var title: String {
        if isToday { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        let sameYear = calendar.isDate(date, equalTo: .now, toGranularity: .year)
        return sameYear
            ? date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
            : date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private func stepButton(_ days: Int, symbol: String, label: String) -> some View {
        Button {
            withAnimation(.snappy) {
                date = calendar.date(byAdding: .day, value: days, to: date) ?? date
            }
        } label: {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .frame(width: 32, height: 32)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.brandPurple)
        .accessibilityLabel(label)
    }
}

#Preview {
    @Previewable @State var date = Date.now
    DaySwitcher(date: $date).padding()
}
