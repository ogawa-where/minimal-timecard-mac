import Foundation
import AppKit

struct CSVService: Sendable {
    private static let directoryPath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path()
        return "\(home)/Documents/Timecard"
    }()

    static let logFilePath: String = "\(directoryPath)/log.csv"

    private static let header = "Date,Time,Action"

    // MARK: - Directory / File Setup

    static func ensureDirectoryExists() throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: directoryPath) {
            try fm.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
        }
    }

    static func ensureLogFileExists() throws {
        try ensureDirectoryExists()
        let fm = FileManager.default
        if !fm.fileExists(atPath: logFilePath) {
            let data = (header + "\n").data(using: .utf8)!
            fm.createFile(atPath: logFilePath, contents: data)
        }
    }

    // MARK: - Write

    static func appendEvent(_ event: TimecardEvent) throws {
        try ensureLogFileExists()

        let line = event.csvLine + "\n"
        guard let data = line.data(using: .utf8) else {
            throw CSVError.encodingFailed
        }

        let handle = try FileHandle(forWritingTo: URL(fileURLWithPath: logFilePath))
        defer { try? handle.close() }
        handle.seekToEndOfFile()
        handle.write(data)
    }

    // MARK: - Read

    static func readAllEvents() throws -> [TimecardEvent] {
        try ensureLogFileExists()

        let content = try String(contentsOfFile: logFilePath, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        return lines.dropFirst() // skip header
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .compactMap { TimecardEvent.from(csvLine: $0) }
    }

    // MARK: - Delete

    static func deleteLogFile() throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: logFilePath) {
            try fm.removeItem(atPath: logFilePath)
        }
    }

    // MARK: - Report Output

    static func writeReport(fileName: String, content: String) throws -> String {
        try ensureDirectoryExists()
        let path = "\(directoryPath)/\(fileName)"
        try content.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }

    static func revealInFinder(path: String) {
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }
}

enum CSVError: LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "CSVデータのエンコードに失敗しました"
        }
    }
}
