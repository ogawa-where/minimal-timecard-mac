import Foundation

enum TimecardAction: String, Sendable, CaseIterable {
    case clockIn = "出勤"
    case breakStart = "休憩"
    case breakEnd = "再開"
    case clockOut = "退勤"

    var nextState: WorkState {
        switch self {
        case .clockIn, .breakEnd: return .working
        case .breakStart: return .onBreak
        case .clockOut: return .idle
        }
    }
}

struct TimecardEvent: Sendable, Equatable {
    let date: String      // yyyy/MM/dd
    let time: String      // HH:mm:ss
    let action: TimecardAction

    var timestamp: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.date(from: "\(date) \(time)")
    }

    init(date: String, time: String, action: TimecardAction) {
        self.date = date
        self.time = time
        self.action = action
    }

    init(action: TimecardAction, at now: Date = Date()) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")

        formatter.dateFormat = "yyyy/MM/dd"
        self.date = formatter.string(from: now)

        formatter.dateFormat = "HH:mm:ss"
        self.time = formatter.string(from: now)

        self.action = action
    }

    var csvLine: String {
        "\(date),\(time),\(action.rawValue)"
    }

    static func from(csvLine: String) -> TimecardEvent? {
        let components = csvLine.split(separator: ",", maxSplits: 2).map(String.init)
        guard components.count == 3,
              let action = TimecardAction(rawValue: components[2].trimmingCharacters(in: .whitespacesAndNewlines))
        else {
            return nil
        }
        return TimecardEvent(
            date: components[0],
            time: components[1],
            action: action
        )
    }
}
