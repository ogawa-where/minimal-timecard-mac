import Foundation
import SwiftUI
import AppKit

@Observable
@MainActor
final class TimecardViewModel {

    // MARK: - State

    private(set) var workState: WorkState = .idle
    private(set) var elapsedWorkTime: TimeInterval = 0
    private(set) var errorMessage: String? = nil
    private(set) var showDeleteConfirmation = false
    private(set) var lastReportPath: String? = nil

    // MARK: - Internal Tracking

    private var clockInDate: Date? = nil
    private var accumulatedBreakTime: TimeInterval = 0
    private var currentBreakStartDate: Date? = nil
    private var timer: Timer? = nil

    // MARK: - Initialization

    init() {
        restoreState()
    }

    // MARK: - Actions

    func clockIn() {
        record(action: .clockIn)
    }

    func startBreak() {
        record(action: .breakStart)
    }

    func endBreak() {
        record(action: .breakEnd)
    }

    func clockOut() {
        record(action: .clockOut)
    }

    private func record(action: TimecardAction) {
        let event = TimecardEvent(action: action)
        do {
            try CSVService.appendEvent(event)
        } catch {
            errorMessage = "打刻の保存に失敗しました: \(error.localizedDescription)"
            return
        }

        let now = Date()
        switch action {
        case .clockIn:
            clockInDate = now
            accumulatedBreakTime = 0
            currentBreakStartDate = nil
            workState = .working
            startTimer()

        case .breakStart:
            currentBreakStartDate = now
            // Freeze elapsed time at this moment
            if let clockIn = clockInDate {
                elapsedWorkTime = now.timeIntervalSince(clockIn) - accumulatedBreakTime
            }
            workState = .onBreak
            stopTimer()

        case .breakEnd:
            if let breakStart = currentBreakStartDate {
                accumulatedBreakTime += now.timeIntervalSince(breakStart)
            }
            currentBreakStartDate = nil
            workState = .working
            startTimer()

        case .clockOut:
            if let breakStart = currentBreakStartDate {
                accumulatedBreakTime += now.timeIntervalSince(breakStart)
            }
            if let clockIn = clockInDate {
                elapsedWorkTime = now.timeIntervalSince(clockIn) - accumulatedBreakTime
            }
            clockInDate = nil
            currentBreakStartDate = nil
            accumulatedBreakTime = 0
            workState = .idle
            stopTimer()
            elapsedWorkTime = 0
        }
        errorMessage = nil
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateElapsedTime()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateElapsedTime() {
        guard let clockIn = clockInDate, workState == .working else { return }
        elapsedWorkTime = Date().timeIntervalSince(clockIn) - accumulatedBreakTime
    }

    // MARK: - State Restoration

    func restoreState() {
        let events: [TimecardEvent]
        do {
            events = try CSVService.readAllEvents()
        } catch {
            errorMessage = "ログの読み込みに失敗しました: \(error.localizedDescription)"
            workState = .idle
            return
        }

        guard let lastEvent = events.last else {
            workState = .idle
            return
        }

        let newState = lastEvent.action.nextState
        guard newState != .idle else {
            workState = .idle
            elapsedWorkTime = 0
            return
        }

        // Find the current session (from the last clockIn)
        guard let sessionStartIndex = events.lastIndex(where: { $0.action == .clockIn }) else {
            workState = .idle
            return
        }

        let sessionEvents = Array(events[sessionStartIndex...])

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        formatter.locale = Locale(identifier: "ja_JP")

        guard let clockInTimestamp = sessionEvents.first?.timestamp else {
            workState = .idle
            return
        }

        clockInDate = clockInTimestamp
        // calculateBreakTotal only sums completed break pairs (breakStart→breakEnd/clockOut)
        // An ongoing break (breakStart without a matching end) is NOT included.
        accumulatedBreakTime = ReportService.calculateBreakTotal(events: sessionEvents, formatter: formatter)

        if newState == .onBreak {
            // Currently on break: find when it started
            if let lastBreakStart = sessionEvents.last(where: { $0.action == .breakStart }) {
                currentBreakStartDate = lastBreakStart.timestamp
            }
            // Frozen timer = time from clockIn to breakStart minus completed breaks
            if let breakStart = currentBreakStartDate {
                elapsedWorkTime = breakStart.timeIntervalSince(clockInTimestamp) - accumulatedBreakTime
            }
            workState = .onBreak
        } else {
            // Currently working
            currentBreakStartDate = nil
            let now = Date()
            elapsedWorkTime = now.timeIntervalSince(clockInTimestamp) - accumulatedBreakTime
            workState = .working
            startTimer()
        }
    }

    // MARK: - Monthly Report

    func exportMonthlyReport() {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)

        let events: [TimecardEvent]
        do {
            events = try CSVService.readAllEvents()
        } catch {
            errorMessage = "ログの読み込みに失敗しました: \(error.localizedDescription)"
            return
        }

        let summaries = ReportService.generateMonthlyReport(events: events, year: year, month: month)

        guard !summaries.isEmpty else {
            errorMessage = "今月の勤務データがありません"
            return
        }

        let csvContent = ReportService.formatReport(summaries: summaries)
        let fileName = String(format: "%04d-%02d_report.csv", year, month)

        do {
            let path = try CSVService.writeReport(fileName: fileName, content: csvContent)
            lastReportPath = path
            CSVService.revealInFinder(path: path)
            showDeleteConfirmation = true
            errorMessage = nil
        } catch {
            errorMessage = "レポートの出力に失敗しました: \(error.localizedDescription)"
        }
    }

    func deleteLogFile() {
        do {
            try CSVService.deleteLogFile()
            showDeleteConfirmation = false
            // Reset state since log is gone
            workState = .idle
            elapsedWorkTime = 0
            clockInDate = nil
            accumulatedBreakTime = 0
            currentBreakStartDate = nil
            stopTimer()
            errorMessage = nil
        } catch {
            errorMessage = "ログの削除に失敗しました: \(error.localizedDescription)"
        }
    }

    func dismissDeleteConfirmation() {
        showDeleteConfirmation = false
    }

    // MARK: - Formatted Time

    var formattedElapsedTime: String {
        ReportService.formatDuration(elapsedWorkTime)
    }
}
