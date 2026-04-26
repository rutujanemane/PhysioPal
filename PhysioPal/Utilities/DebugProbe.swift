import Foundation

enum DebugProbe {
    private static let path = "/Users/rutujanemane/Documents/SJSU/PhysioPal/.cursor/debug-626697.log"
    private static let sessionId = "626697"

    static func log(
        runId: String,
        hypothesisId: String,
        location: String,
        message: String,
        data: [String: String] = [:]
    ) {
        let payload: [String: Any] = [
            "sessionId": sessionId,
            "runId": runId,
            "hypothesisId": hypothesisId,
            "location": location,
            "message": message,
            "data": data,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let line = String(data: jsonData, encoding: .utf8) else { return }

        let dir = "/Users/rutujanemane/Documents/SJSU/PhysioPal/.cursor"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        if let handle = FileHandle(forWritingAtPath: path) {
            defer { try? handle.close() }
            try? handle.seekToEnd()
            if let out = (line + "\n").data(using: .utf8) {
                try? handle.write(contentsOf: out)
            }
            return
        }
        try? (line + "\n").write(toFile: path, atomically: true, encoding: .utf8)
    }
}
