import Combine
import Foundation

struct AssignedRoutineItem: Codable, Identifiable {
    var id: String { exerciseID }
    let exerciseID: String
    var targetReps: Int
}

@MainActor
final class RoutineStore: ObservableObject {
    static let shared = RoutineStore()

    @Published private(set) var assignedExercises: [AssignedRoutineItem] = []

    var hasAssignedRoutine: Bool { !assignedExercises.isEmpty }

    private let key = "pt_assigned_routine"

    private init() {
        load()
    }

    func save(_ items: [AssignedRoutineItem]) {
        assignedExercises = items
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func clear() {
        assignedExercises = []
        UserDefaults.standard.removeObject(forKey: key)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([AssignedRoutineItem].self, from: data) else { return }
        assignedExercises = items
    }
}
