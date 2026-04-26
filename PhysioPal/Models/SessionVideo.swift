import Foundation

struct SessionVideo: Identifiable, Codable, Hashable {
    let id: UUID
    let createdAt: Date
    let sessionStartTime: Date?
    let localPath: String
    let exerciseName: String?
    let totalReps: Int
    let accuracy: Double
    let duration: TimeInterval
    var sharedWithPT: Bool

    var fileURL: URL {
        URL(fileURLWithPath: localPath)
    }
}
