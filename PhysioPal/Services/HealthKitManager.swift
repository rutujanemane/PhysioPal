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
        let quantityTypes: [HKQuantityTypeIdentifier] = [
            .activeEnergyBurned,
            .heartRate,
            .stepCount,
            .heartRateVariabilitySDNN
        ]
        for id in quantityTypes {
            if let type = HKObjectType.quantityType(forIdentifier: id) {
                types.insert(type)
            }
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

    // MARK: - Sleep

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

    // MARK: - Active Energy

    func fetchActiveEnergy() async throws -> Double? {
        guard isAvailable else { return nil }
        return try await fetchCumulativeStat(for: .activeEnergyBurned, unit: .kilocalorie())
    }

    // MARK: - Steps

    func fetchStepCount() async throws -> Double? {
        guard isAvailable else { return nil }
        return try await fetchCumulativeStat(for: .stepCount, unit: .count())
    }

    // MARK: - Heart Rate

    func fetchRestingHeartRate() async throws -> Double? {
        guard isAvailable else { return nil }
        return try await fetchMostRecentSample(for: .heartRate, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    // MARK: - HRV

    func fetchHRV() async throws -> Double? {
        guard isAvailable else { return nil }
        return try await fetchMostRecentSample(for: .heartRateVariabilitySDNN, unit: .secondUnit(with: .milli))
    }

    // MARK: - Combined Assessment

    func assessReadiness() async -> HealthReadiness {
        #if targetEnvironment(simulator)
        return HealthReadiness.simulatorMock
        #else
        do {
            try await requestAuthorization()

            async let sleepTask = fetchSleepHours()
            async let energyTask = fetchActiveEnergy()
            async let hrTask = fetchRestingHeartRate()
            async let stepsTask = fetchStepCount()
            async let hrvTask = fetchHRV()

            let sleep = try? await sleepTask
            let energy = try? await energyTask
            let hr = try? await hrTask
            let steps = try? await stepsTask
            let hrv = try? await hrvTask

            return HealthReadiness(
                sleepHours: sleep,
                activeEnergyKcal: energy,
                restingHeartRate: hr,
                stepCount: steps,
                heartRateVariability: hrv,
                assessedAt: Date()
            )
        } catch {
            return .noHealthData
        }
        #endif
    }

    // MARK: - Helpers

    private func fetchCumulativeStat(for identifier: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> Double? {
        let quantityType = HKObjectType.quantityType(forIdentifier: identifier)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics, Error>) in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
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

        return statistics.sumQuantity()?.doubleValue(for: unit)
    }

    private func fetchMostRecentSample(for identifier: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> Double? {
        let quantityType = HKObjectType.quantityType(forIdentifier: identifier)!
        let now = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -24, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let sample = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKQuantitySample?, Error>) in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: results?.first as? HKQuantitySample)
                }
            }
            store.execute(query)
        }

        return sample?.quantity.doubleValue(for: unit)
    }
}

enum HealthKitError: Error {
    case noData
    case notAvailable
}

extension HealthReadiness {
    static let simulatorMock = HealthReadiness(
        sleepHours: 6.8,
        activeEnergyKcal: 145,
        restingHeartRate: 72,
        stepCount: 3420,
        heartRateVariability: 38,
        assessedAt: Date()
    )
}
