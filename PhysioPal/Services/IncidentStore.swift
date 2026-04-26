import Combine
import Foundation

@MainActor
final class IncidentStore: ObservableObject {
    static let shared = IncidentStore()

    @Published private(set) var incidents: [Incident] = []

    private let fm = FileManager.default
    private let folderName = "Incidents"
    private let fileName = "index.json"

    private init() {
        load()
    }

    func recordEscalation(summary: SessionSummary, sharedVideoCount: Int) {
        let incident = Incident(
            id: UUID(),
            createdAt: Date(),
            title: "Fall-risk escalation",
            details: "Automatic escalation triggered during exercise supervision. Please review shared incident videos.",
            sessionStartTime: summary.startTime,
            sharedVideoCount: sharedVideoCount
        )
        incidents.insert(incident, at: 0)
        persist()
    }

    private func folderURL() throws -> URL {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = docs.appendingPathComponent(folderName, isDirectory: true)
        if !fm.fileExists(atPath: folder.path) {
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    private func fileURL() throws -> URL {
        try folderURL().appendingPathComponent(fileName)
    }

    private func load() {
        do {
            let path = try fileURL()
            guard fm.fileExists(atPath: path.path) else {
                incidents = []
                return
            }
            let data = try Data(contentsOf: path)
            incidents = try JSONDecoder().decode([Incident].self, from: data)
        } catch {
            incidents = []
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(incidents)
            try data.write(to: try fileURL(), options: .atomic)
        } catch {
            print("[IncidentStore] persist failed: \(error.localizedDescription)")
        }
    }
}
