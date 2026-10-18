//
//  logger.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 8/24/26.
//

import Foundation

actor PersistedLogger {
    static let shared = PersistedLogger()

    nonisolated let fileURL: URL
    private let maxFileSizeBytes = 2 * 1024 * 1024 // 2 MB cap before trimming

    private init() {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        fileURL = dir.appendingPathComponent("debug-log.txt")
    }

    func log(_ message: String, file: String = #fileID, line: Int = #line) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let entry = "\(timestamp) [\(file):\(line)] \(message)\n"
        append(entry)
    }

    private func append(_ entry: String) {
        guard let data = entry.data(using: .utf8) else { return }

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }
        rotateIfNeeded()

        guard let handle = try? FileHandle(forWritingTo: fileURL) else { return }
        defer { try? handle.close() }
        handle.seekToEndOfFile()
        handle.write(data)
    }

    private func rotateIfNeeded() {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let size = attrs[.size] as? Int, size > maxFileSizeBytes,
              let contents = try? String(contentsOf: fileURL, encoding: .utf8) else { return }

        let lines = contents.components(separatedBy: "\n")
        let trimmed = lines.suffix(lines.count / 2).joined(separator: "\n")
        try? trimmed.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}

/// Fire-and-forget convenience — call this like `print`.
func log(_ message: String, file: String = #fileID, line: Int = #line) {
    Task { await PersistedLogger.shared.log(message, file: file, line: line) }
}
