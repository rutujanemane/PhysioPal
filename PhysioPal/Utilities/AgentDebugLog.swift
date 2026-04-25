import Foundation

/// NDJSON append for debug-mode verification (session `998d56`).
enum AgentDebugLog {
    private static let path = "/Users/rutujanemane/Documents/SJSU/PhysioPal/.cursor/debug-998d56.log"

    private struct Line: Encodable {
        let sessionId = "998d56"
        var runId: String
        var hypothesisId: String
        var location: String
        var message: String
        var timestamp: Int64
        var data: [String: String]
    }

    static func append(
        hypothesisId: String,
        location: String,
        message: String,
        data: [String: String] = [:],
        runId: String = "verify"
    ) {
        let line = Line(
            runId: runId,
            hypothesisId: hypothesisId,
            location: location,
            message: message,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            data: data
        )
        guard let enc = try? JSONEncoder().encode(line),
              var s = String(data: enc, encoding: .utf8) else { return }
        s += "\n"
        guard let bytes = s.data(using: .utf8) else { return }
        // Physical devices cannot write the Mac workspace path; mirror one NDJSON line to the console.
        print("AGENT_NDJSON \(s.trimmingCharacters(in: .newlines))")
        let url = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: path) {
            guard let fh = try? FileHandle(forWritingTo: url) else { return }
            defer { try? fh.close() }
            try? fh.seekToEnd()
            try? fh.write(contentsOf: bytes)
        } else {
            try? bytes.write(to: url, options: .atomic)
        }
    }
}
