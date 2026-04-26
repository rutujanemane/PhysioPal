import Foundation

struct Incident: Identifiable, Codable, Hashable {
    let id: UUID
    let createdAt: Date
    let title: String
    let details: String
    let sessionStartTime: Date?
    let sharedVideoCount: Int
}
