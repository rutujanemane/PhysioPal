import Foundation
import HealthKit

final class HealthKitManager {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }
        if let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(energyType)
        }
        return types
    }()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isAvailable else { return }
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    func fetchSleepHours() async throws -> Double? {
        guard isAvailable else { return nil }

        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let now = Date()
        let startOfYesterday = Calendar.current.date(byAdding: .hour, value: -24, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: results as? [HKCategorySample] ?? [])
                }
            }
            store.execute(query)
        }

        let asleepSamples = samples.filter { sample in
            sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
            sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
            sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
            sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
        }

        guard !asleepSamples.isEmpty else { return nil }

        let totalSeconds = asleepSamples.reduce(0.0) { total, sample in
            total + sample.endDate.timeIntervalSince(sample.startDate)
        }

        return totalSeconds / 3600.0
    }

    func fetchActiveEnergy() async throws -> Double? {
        guard isAvailable else { return nil }

        let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics, Error>) in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let statistics {
                    continuation.resume(returning: statistics)
                } else {
                    continuation.resume(throwing: HealthKitError.noData)
                }
            }
            store.execute(query)
        }

        return statistics.sumQuantity()?.doubleValue(for: .kilocalorie())
    }

    func assessReadiness() async -> HealthReadiness {
        do {
            try await requestAuthorization()

            async let sleepTask = fetchSleepHours()
            async let energyTask = fetchActiveEnergy()

            let sleep = try? await sleepTask
            let energy = try? await energyTask

            return HealthReadiness(
                sleepHours: sleep,
                activeEnergyKcal: energy,
                assessedAt: Date()
            )
        } catch {
            return .noHealthData
        }
    }
}

enum HealthKitError: Error {
    case noData
    case notAvailable
}
