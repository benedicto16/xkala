import SwiftUI

private let xkalaCalendarLocale = Locale(identifier: "es_ES")
private let xkalaCalendar: Calendar = {
    var cal = Calendar.current
    cal.locale = xkalaCalendarLocale
    cal.firstWeekday = 2 // lunes
    return cal
}()

// MARK: - Calendar summaries (auxiliares, sin lógica de UI)

enum CalendarDayCompletionState: Equatable {
    case empty
    case partial
    case complete
}

enum CalendarDayLoadLevel: Equatable {
    case none
    case low
    case medium
    case high
}

struct CalendarDaySummary: Equatable {
    let completionState: CalendarDayCompletionState
    let loadLevel: CalendarDayLoadLevel
    let dailyLoad: Int
}

struct CalendarSummaryCalculator {
    static func calculateSummaries(for workouts: [WorkoutDay]) -> [Date: CalendarDaySummary] {
        let cal = Calendar.current

        struct Accumulator {
            var hasValidEntry: Bool = false
            var allValidDone: Bool = true
            var dailyLoad: Int = 0
        }

        var accByDate: [Date: Accumulator] = [:]

        for workout in workouts {
            let dayKey = cal.startOfDay(for: workout.date)
            var acc = accByDate[dayKey] ?? Accumulator()

            for entry in workout.entries {
                let validSetsCount = validSetsCountForEntry(entry)
                guard validSetsCount > 0 else {
                    continue
                }

                acc.hasValidEntry = true
                if entry.isDone == false {
                    acc.allValidDone = false
                }

                acc.dailyLoad += entry.intensity * validSetsCount
            }

            accByDate[dayKey] = acc
        }

        var result: [Date: CalendarDaySummary] = [:]
        for (dayKey, acc) in accByDate {
            guard acc.hasValidEntry else { continue }

            let completionState: CalendarDayCompletionState = acc.allValidDone ? .complete : .partial
            let loadLevel: CalendarDayLoadLevel = loadLevel(for: acc.dailyLoad)

            result[dayKey] = CalendarDaySummary(
                completionState: completionState,
                loadLevel: loadLevel,
                dailyLoad: acc.dailyLoad
            )
        }

        return result
    }

    private static func validSetsCountForEntry(_ entry: WorkoutEntry) -> Int {
        switch entry.exercise.modeEnum {
        case .reps:
            return entry.sets.filter { ($0.reps ?? 0) > 0 }.count
        case .seconds:
            return entry.sets.filter { ($0.seconds ?? 0) > 0 }.count
        }
    }

    private static func loadLevel(for dailyLoad: Int) -> CalendarDayLoadLevel {
        if dailyLoad <= 0 { return .none }

        switch dailyLoad {
        case 1...3:
            return .low
        case 4...6:
            return .medium
        default:
            return .high
        }
    }
}

struct WorkoutCalendarView: View {
    let workouts: [WorkoutDay]
    let onSelectDate: (Date) -> Void

    @State private var displayedMonth = Date()

    var body: some View {
        let summariesByDate = CalendarSummaryCalculator.calculateSummaries(for: workouts)

        VStack(spacing: 12) {
            CalendarHeaderView(displayedMonth: displayedMonth) { newMonth in
                displayedMonth = newMonth
            }

            CalendarGridView(
                onSelectDate: onSelectDate,
                displayedMonth: displayedMonth,
                summariesByDate: summariesByDate
            )
        }
        .padding()
    }
}

private struct CalendarHeaderView: View {
    let displayedMonth: Date
    let onChangeMonth: (Date) -> Void

    private var calendar: Calendar { xkalaCalendar }

    private var monthTitle: String {
        let df = DateFormatter()
        df.locale = xkalaCalendarLocale
        df.calendar = calendar
        df.setLocalizedDateFormatFromTemplate("LLLL yyyy")
        return df.string(from: displayedMonth)
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .accessibilityLabel("Mes anterior")

            Text(monthTitle)
                .font(.headline)
                .lineLimit(1)
                .frame(maxWidth: .infinity)

            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .accessibilityLabel("Mes siguiente")
        }
    }

    private func shiftMonth(by amount: Int) {
        let cal = calendar
        let shifted = cal.date(byAdding: .month, value: amount, to: displayedMonth) ?? displayedMonth
        let normalized = cal.date(from: cal.dateComponents([.year, .month], from: shifted)) ?? shifted
        onChangeMonth(normalized)
    }
}

private struct CalendarGridView: View {
    let onSelectDate: (Date) -> Void
    let displayedMonth: Date
    let summariesByDate: [Date: CalendarDaySummary]

    private var calendar: Calendar { xkalaCalendar }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    }

    private func monthDates(for baseDate: Date, calendar: Calendar) -> [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: baseDate))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!

        let firstWeekday = calendar.firstWeekday
        let startWeekday = calendar.component(.weekday, from: startOfMonth)

        let offset = (startWeekday - firstWeekday + 7) % 7
        let daysInMonth = range.count

        let totalCells = offset + daysInMonth
        let numberOfRows = Int(ceil(Double(totalCells) / 7.0))
        let cellCount = numberOfRows * 7

        var cells: [Date?] = []
        cells.reserveCapacity(cellCount)

        for index in 0..<cellCount {
            if index < offset || index >= offset + daysInMonth {
                cells.append(nil)
            } else {
                let day = index - offset + 1
                var comps = calendar.dateComponents([.year, .month], from: startOfMonth)
                comps.day = day
                let date = calendar.date(from: comps)!
                cells.append(date)
            }
        }

        return cells
    }

    private func monthTitle(for baseDate: Date, calendar: Calendar) -> String {
        let df = DateFormatter()
        df.locale = xkalaCalendarLocale
        df.calendar = calendar
        df.setLocalizedDateFormatFromTemplate("LLLL yyyy")
        return df.string(from: baseDate)
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let firstIndex = firstWeekdayIndex
        return (0..<symbols.count).map { offset in
            symbols[(firstIndex + offset) % symbols.count]
        }
    }

    private var firstWeekdayIndex: Int {
        let firstWeekday = calendar.firstWeekday
        return firstWeekday - 1
    }

    var body: some View {
        let cal = calendar
        let today = cal.startOfDay(for: Date())
        let shouldHighlightToday = cal.isDate(today, equalTo: displayedMonth, toGranularity: .month)

        let monthTitle = monthTitle(for: displayedMonth, calendar: cal)
        let monthDates = monthDates(for: displayedMonth, calendar: cal)

        VStack(spacing: 8) {
            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(weekdaySymbols.indices, id: \.self) { i in
                    Text(weekdaySymbols[i])
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(monthDates.indices, id: \.self) { index in
                    let date = monthDates[index]
                    let dayKey = date.map { cal.startOfDay(for: $0) }
                    let summary = dayKey.flatMap { summariesByDate[$0] }

                    DayCellView(
                        date: date,
                        summary: summary,
                        isToday: date.map { cal.startOfDay(for: $0) == today && shouldHighlightToday } ?? false
                    ) {
                        guard let date, summary != nil else { return }
                        onSelectDate(cal.startOfDay(for: date))
                    }
                }
            }
        }
        .accessibilityLabel(monthTitle)
    }
}

private struct DayCellView: View {
    let date: Date?
    let summary: CalendarDaySummary?
    let isToday: Bool
    let onTap: () -> Void

    private var dayNumberText: String {
        guard let date else { return "" }
        return String(Calendar.current.component(.day, from: date))
    }

    var body: some View {
        ZStack {
            if date == nil {
                Color.clear
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(loadBackgroundColor)

                VStack(spacing: 4) {
                    Text(dayNumberText)
                        .font(.subheadline)
                        .foregroundStyle(cellForegroundColor)

                    completionIndicator
                }
            }
        }
        .frame(height: 44)
        .contentShape(Rectangle())
        .allowsHitTesting(date != nil && summary != nil)
        .overlay {
            if isToday {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accentColor, lineWidth: 2)
            }
        }
        .onTapGesture { onTap() }
    }

    private var cellForegroundColor: some ShapeStyle {
        if isToday { return Color.primary }
        if summary != nil { return Color.primary }
        return Color.secondary
    }

    private var loadBackgroundColor: Color {
        guard let loadLevel = summary?.loadLevel else { return Color.clear }

        switch loadLevel {
        case .none:
            return Color.clear
        case .low:
            return Color.accentColor.opacity(0.12)
        case .medium:
            return Color.accentColor.opacity(0.30)
        case .high:
            return Color.accentColor.opacity(0.55)
        }
    }

    @ViewBuilder
    private var completionIndicator: some View {
        if let completionState = summary?.completionState {
            switch completionState {
            case .empty:
                EmptyView()
            case .partial:
                Circle()
                    .stroke(Color.accentColor.opacity(0.85), lineWidth: 1.6)
                    .frame(width: 6, height: 6)
            case .complete:
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 6, height: 6)
            }
        } else {
            EmptyView()
        }
    }
}
