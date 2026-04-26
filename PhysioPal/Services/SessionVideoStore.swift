import Combine
import Foundation

@MainActor
final class SessionVideoStore: ObservableObject {
    static let shared = SessionVideoStore()

    @Published private(set) var videos: [SessionVideo] = []

    private let fm = FileManager.default
    private let videosFolderName = "SessionVideos"
    private let indexFileName = "index.json"

    private init() {
        loadIndex()
    }

    var latestVideo: SessionVideo? {
        videos.sorted(by: { $0.createdAt > $1.createdAt }).first
    }

    var sharedVideos: [SessionVideo] {
        videos.filter(\.sharedWithPT).sorted(by: { $0.createdAt > $1.createdAt })
    }

    func videos(for session: ExerciseSession) -> [SessionVideo] {
        videosForSession(startTime: session.date)
    }

    func sharedVideo(for session: ExerciseSession) -> SessionVideo? {
        sharedVideos(for: session).first
    }

    func sharedVideos(for session: ExerciseSession) -> [SessionVideo] {
        videos(for: session).filter(\.sharedWithPT)
    }

    func saveVideo(
        tempURL: URL,
        summary: SessionSummary,
        exerciseName: String? = nil,
        markShared: Bool = false
    ) {
        do {
            let folder = try ensureVideosFolder()
            let ext = tempURL.pathExtension.isEmpty ? "mov" : tempURL.pathExtension
            let name = "session-\(UUID().uuidString).\(ext)"
            let target = folder.appendingPathComponent(name)
            if fm.fileExists(atPath: target.path) {
                try fm.removeItem(at: target)
            }
            try fm.copyItem(at: tempURL, to: target)

            let item = SessionVideo(
                id: UUID(),
                createdAt: Date(),
                sessionStartTime: summary.startTime,
                localPath: target.path,
                exerciseName: exerciseName,
                totalReps: summary.totalReps,
                accuracy: summary.overallAccuracy,
                duration: summary.totalDuration,
                sharedWithPT: markShared
            )
            videos.insert(item, at: 0)
            persistIndex()
        } catch {
            print("[SessionVideoStore] save failed: \(error.localizedDescription)")
        }
    }

    func markLatestAsSharedWithPT() {
        markLatestSessionVideosAsShared()
    }

    func unshareLatestVideo() {
        unshareLatestSessionVideos()
    }

    func deleteLatestVideo() {
        deleteLatestSessionVideos()
    }

    func markLatestSessionVideosAsShared() {
        guard let latest = latestVideo else { return }
        let targets = videosForSession(startTime: latest.sessionStartTime)
        if targets.isEmpty {
            markVideoAsSharedWithPT(id: latest.id)
            return
        }
        let ids = Set(targets.map(\.id))
        for idx in videos.indices where ids.contains(videos[idx].id) {
            videos[idx].sharedWithPT = true
        }
        persistIndex()
    }

    func unshareLatestSessionVideos() {
        guard let latest = latestVideo else { return }
        let targets = videosForSession(startTime: latest.sessionStartTime)
        if targets.isEmpty {
            unshareVideo(id: latest.id)
            return
        }
        let ids = Set(targets.map(\.id))
        for idx in videos.indices where ids.contains(videos[idx].id) {
            videos[idx].sharedWithPT = false
        }
        persistIndex()
    }

    func deleteLatestSessionVideos() {
        guard let latest = latestVideo else { return }
        let targets = videosForSession(startTime: latest.sessionStartTime)
        if targets.isEmpty {
            deleteVideo(id: latest.id)
            return
        }
        let ids = Set(targets.map(\.id))
        for video in videos where ids.contains(video.id) {
            if fm.fileExists(atPath: video.localPath) {
                try? fm.removeItem(atPath: video.localPath)
            }
        }
        videos.removeAll { ids.contains($0.id) }
        persistIndex()
    }

    func markVideoAsSharedWithPT(id: UUID) {
        guard let idx = videos.firstIndex(where: { $0.id == id }) else { return }
        videos[idx].sharedWithPT = true
        persistIndex()
    }

    func unshareVideo(id: UUID) {
        guard let idx = videos.firstIndex(where: { $0.id == id }) else { return }
        videos[idx].sharedWithPT = false
        persistIndex()
    }

    func deleteVideo(id: UUID) {
        guard let idx = videos.firstIndex(where: { $0.id == id }) else { return }
        let video = videos.remove(at: idx)
        if fm.fileExists(atPath: video.localPath) {
            try? fm.removeItem(atPath: video.localPath)
        }
        persistIndex()
    }

    private func ensureVideosFolder() throws -> URL {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = docs.appendingPathComponent(videosFolderName, isDirectory: true)
        if !fm.fileExists(atPath: folder.path) {
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    private func indexURL() throws -> URL {
        try ensureVideosFolder().appendingPathComponent(indexFileName)
    }

    private func loadIndex() {
        do {
            let url = try indexURL()
            guard fm.fileExists(atPath: url.path) else {
                videos = []
                return
            }
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([SessionVideo].self, from: data)
            videos = decoded.filter { fm.fileExists(atPath: $0.localPath) }
        } catch {
            videos = []
            print("[SessionVideoStore] load failed: \(error.localizedDescription)")
        }
    }

    private func persistIndex() {
        do {
            let data = try JSONEncoder().encode(videos)
            try data.write(to: try indexURL(), options: .atomic)
        } catch {
            print("[SessionVideoStore] persist failed: \(error.localizedDescription)")
        }
    }

    private func videosForSession(startTime: Date?) -> [SessionVideo] {
        guard let startTime else { return [] }
        let strictWindow: TimeInterval = 2
        let strictMatches = videos.filter {
            guard let start = $0.sessionStartTime else { return false }
            return abs(start.timeIntervalSince(startTime)) <= strictWindow
        }
        return strictMatches.sorted(by: { $0.createdAt > $1.createdAt })
    }
}
