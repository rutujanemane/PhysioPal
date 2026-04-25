import Foundation

struct HealthReadiness {
    let sleepHours: Double?
    let activeEnergyKcal: Double?
    let assessedAt: Date

    var level: ReadinessLevel {
        let lowSleep = (sleepHours ?? 8) < HealthThresholds.lowSleepHours
        let lowEnergy = (activeEnergyKcal ?? 100) < HealthThresholds.lowEnergyKcal

        if lowSleep && lowEnergy { return .low }
        if lowSleep || lowEnergy { return .moderate }
        return .normal
    }

    var explanation: String {
        switch level {
        case .low:
            return lowReadinessMessage
        case .moderate:
            return moderateReadinessMessage
        case .normal:
            return "You're looking well-rested and ready! Let's do your full routine today."
        }
    }

    private var lowReadinessMessage: String {
        var parts: [String] = []
        if let sleep = sleepHours, sleep < HealthThresholds.lowSleepHours {
            let rounded = String(format: "%.1f", sleep)
            parts.append("you only got \(rounded) hours of sleep last night")
        }
        if let energy = activeEnergyKcal, energy < HealthThresholds.lowEnergyKcal {
            parts.append("your energy levels are a bit low today")
        }
        let reasons = parts.joined(separator: " and ")
        return "It looks like \(reasons) — let's take it easy today with a lighter routine."
    }

    private var moderateReadinessMessage: String {
        if let sleep = sleepHours, sleep < HealthThresholds.lowSleepHours {
            let rounded = String(format: "%.1f", sleep)
            return "You got \(rounded) hours of sleep, which is a little less than ideal. I've adjusted a few exercises to keep things comfortable."
        }
        return "Your energy is a little low today. I've made a few small adjustments so you can still have a great session."
    }

    static let noHealthData = HealthReadiness(
        sleepHours: nil,
        activeEnergyKcal: nil,
        assessedAt: Date()
    )
}

enum ReadinessLevel: String {
    case normal
    case moderate
    case low

    var shouldReduceRoutine: Bool {
        self != .normal
    }

    var displayLabel: String {
        switch self {
        case .normal: return "Ready to go"
        case .moderate: return "Taking it easy"
        case .low: return "Light session today"
        }
    }

    var iconName: String {
        switch self {
        case .normal: return "sun.max.fill"
        case .moderate: return "cloud.sun.fill"
        case .low: return "moon.fill"
        }
    }
}
