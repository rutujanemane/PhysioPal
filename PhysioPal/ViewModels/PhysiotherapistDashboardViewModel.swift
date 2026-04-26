import Combine
import Foundation
import SwiftUI

@MainActor
final class PhysiotherapistDashboardViewModel: ObservableObject {
    @Published var healthMetrics: HealthReadiness?
    @Published var patient: PatientProfile = .mock
    @Published var isLoadingHealth = false

    private let healthKit = HealthKitManager.shared
    let sessionStore = SessionStore.shared
    let routineStore = RoutineStore.shared

    func loadDashboard() async {
        isLoadingHealth = true
        healthMetrics = await healthKit.assessReadiness()
        isLoadingHealth = false
    }

    func refreshHealth() async {
        healthMetrics = await healthKit.assessReadiness()
    }
}
