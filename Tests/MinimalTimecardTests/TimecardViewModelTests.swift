import XCTest
@testable import MinimalTimecard

final class TimecardEventTests: XCTestCase {
    func testCSVLineParsing() {
        let event = TimecardEvent.from(csvLine: "2026/02/18,10:00:00,出勤")
        XCTAssertNotNil(event)
        XCTAssertEqual(event?.date, "2026/02/18")
        XCTAssertEqual(event?.time, "10:00:00")
        XCTAssertEqual(event?.action, .clockIn)
    }

    func testCSVLineGeneration() {
        let event = TimecardEvent(date: "2026/02/18", time: "10:00:00", action: .clockIn)
        XCTAssertEqual(event.csvLine, "2026/02/18,10:00:00,出勤")
    }

    func testAllActions() {
        let actions: [(String, TimecardAction)] = [
            ("出勤", .clockIn),
            ("休憩", .breakStart),
            ("再開", .breakEnd),
            ("退勤", .clockOut),
        ]
        for (raw, expected) in actions {
            let event = TimecardEvent.from(csvLine: "2026/01/01,09:00:00,\(raw)")
            XCTAssertEqual(event?.action, expected)
        }
    }

    func testInvalidCSVLine() {
        XCTAssertNil(TimecardEvent.from(csvLine: "invalid"))
        XCTAssertNil(TimecardEvent.from(csvLine: "2026/01/01,09:00:00,不明"))
        XCTAssertNil(TimecardEvent.from(csvLine: ""))
    }

    func testNextState() {
        XCTAssertEqual(TimecardAction.clockIn.nextState, .working)
        XCTAssertEqual(TimecardAction.breakStart.nextState, .onBreak)
        XCTAssertEqual(TimecardAction.breakEnd.nextState, .working)
        XCTAssertEqual(TimecardAction.clockOut.nextState, .idle)
    }
}

final class ReportServiceTests: XCTestCase {
    func testFormatDuration() {
        XCTAssertEqual(ReportService.formatDuration(0), "00:00:00")
        XCTAssertEqual(ReportService.formatDuration(3661), "01:01:01")
        XCTAssertEqual(ReportService.formatDuration(28800), "08:00:00")
    }

    func testCalculateBreakTotal() {
        let events = [
            TimecardEvent(date: "2026/02/18", time: "10:00:00", action: .clockIn),
            TimecardEvent(date: "2026/02/18", time: "12:00:00", action: .breakStart),
            TimecardEvent(date: "2026/02/18", time: "13:00:00", action: .breakEnd),
            TimecardEvent(date: "2026/02/18", time: "15:00:00", action: .breakStart),
            TimecardEvent(date: "2026/02/18", time: "15:30:00", action: .breakEnd),
            TimecardEvent(date: "2026/02/18", time: "19:00:00", action: .clockOut),
        ]
        let total = ReportService.calculateBreakTotal(events: events)
        XCTAssertEqual(total, 5400, accuracy: 1) // 1h + 30min = 5400s
    }

    func testMonthlyReport() {
        let events = [
            TimecardEvent(date: "2026/02/18", time: "10:00:00", action: .clockIn),
            TimecardEvent(date: "2026/02/18", time: "12:00:00", action: .breakStart),
            TimecardEvent(date: "2026/02/18", time: "13:00:00", action: .breakEnd),
            TimecardEvent(date: "2026/02/18", time: "19:00:00", action: .clockOut),
            TimecardEvent(date: "2026/02/19", time: "09:00:00", action: .clockIn),
            TimecardEvent(date: "2026/02/19", time: "18:00:00", action: .clockOut),
        ]
        let summaries = ReportService.generateMonthlyReport(events: events, year: 2026, month: 2)
        XCTAssertEqual(summaries.count, 2)

        XCTAssertEqual(summaries[0].date, "2026/02/18")
        XCTAssertEqual(summaries[0].clockIn, "10:00")
        XCTAssertEqual(summaries[0].clockOut, "19:00")
        XCTAssertEqual(summaries[0].breakTotal, 3600, accuracy: 1)
        XCTAssertEqual(summaries[0].workTotal!, 28800, accuracy: 1) // 9h - 1h = 8h

        XCTAssertEqual(summaries[1].date, "2026/02/19")
        XCTAssertEqual(summaries[1].clockIn, "09:00")
        XCTAssertEqual(summaries[1].clockOut, "18:00")
        XCTAssertEqual(summaries[1].breakTotal, 0, accuracy: 1)
        XCTAssertEqual(summaries[1].workTotal!, 32400, accuracy: 1) // 9h
    }
}
