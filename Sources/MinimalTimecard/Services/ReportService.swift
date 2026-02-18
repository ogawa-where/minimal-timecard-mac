import Foundation

struct ReportService: Sendable {

    struct DailySummary: Sendable {
        let date: String          // yyyy/MM/dd
        let clockIn: String       // HH:mm
        let clockOut: String?     // HH:mm or nil
        let breakTotal: TimeInterval
        let workTotal: TimeInterval?
    }

    // MARK: - Monthly Report Generation

    static func generateMonthlyReport(
        events: [TimecardEvent],
        year: Int,
        month: Int
    ) -> [DailySummary] {
        let monthPrefix = String(format: "%04d/%02d", year, month)
        let monthEvents = events.filter { $0.date.hasPrefix(monthPrefix) }

        let grouped = Dictionary(grouping: monthEvents) { $0.date }
        let sortedDates = grouped.keys.sorted()

        return sortedDates.compactMap { date in
            summarize(date: date, events: grouped[date] ?? [])
        }
    }

    private static func summarize(date: String, events: [TimecardEvent]) -> DailySummary? {
        guard !events.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        formatter.locale = Locale(identifier: "ja_JP")

        let clockInEvent = events.first { $0.action == .clockIn }
        let clockOutEvent = events.last { $0.action == .clockOut }

        guard let clockInEvent else { return nil }

        let clockInTime = String(clockInEvent.time.prefix(5)) // HH:mm
        let clockOutTime = clockOutEvent.map { String($0.time.prefix(5)) }

        let breakTotal = calculateBreakTotal(events: events, formatter: formatter)

        var workTotal: TimeInterval? = nil
        if let clockInTimestamp = clockInEvent.timestamp,
           let clockOutTimestamp = clockOutEvent?.timestamp {
            workTotal = clockOutTimestamp.timeIntervalSince(clockInTimestamp) - breakTotal
        }

        return DailySummary(
            date: date,
            clockIn: clockInTime,
            clockOut: clockOutTime,
            breakTotal: breakTotal,
            workTotal: workTotal
        )
    }

    static func calculateBreakTotal(
        events: [TimecardEvent],
        formatter: DateFormatter? = nil
    ) -> TimeInterval {
        let fmt = formatter ?? {
            let f = DateFormatter()
            f.dateFormat = "yyyy/MM/dd HH:mm:ss"
            f.locale = Locale(identifier: "ja_JP")
            return f
        }()

        var total: TimeInterval = 0
        var breakStart: Date? = nil

        for event in events {
            guard let ts = fmt.date(from: "\(event.date) \(event.time)") else { continue }
            switch event.action {
            case .breakStart:
                breakStart = ts
            case .breakEnd, .clockOut:
                if let start = breakStart {
                    total += ts.timeIntervalSince(start)
                    breakStart = nil
                }
            default:
                break
            }
        }
        return total
    }

    // MARK: - CSV Formatting

    static func formatReport(summaries: [DailySummary]) -> String {
        var lines = ["日付,出勤,退勤,休憩時間,実働時間"]

        for s in summaries {
            let breakStr = formatDuration(s.breakTotal)
            let workStr = s.workTotal.map { formatDuration($0) } ?? ""
            lines.append("\(s.date),\(s.clockIn),\(s.clockOut ?? ""),\(breakStr),\(workStr)")
        }

        return lines.joined(separator: "\n") + "\n"
    }

    static func formatDuration(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
