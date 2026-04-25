import Foundation

struct HealthReadiness {
    let sleepHours: Double?
    let activeEnergyKcal: Double?
    let restingHeartRate: Double?
    let stepCount: Double?
    let heartRateVariability: Double?
    let assessedAt: Date

    var level: ReadinessLevel {
        let lowSleep = (sleepHours ?? 8) < HealthThresholds.lowSleepHours
        let lowEnergy = (activeEnergyKcal ?? 100) < HealthThresholds.lowEnergyKcal
        let elevatedHR = (restingHeartRate ?? 65) > HealthThresholds.elevatedHeartRate

        if lowSleep && lowEnergy { return .low }
        if lowSleep && elevatedHR { return .low }
        if lowSleep || lowEnergy || elevatedHR { return .moderate }
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
        if let hr = restingHeartRate, hr > HealthThresholds.elevatedHeartRate {
            parts.append("your resting heart rate is a bit elevated")
        }
        let reasons = parts.joined(separator: " and ")
        return "It looks like \(reasons) — let's take it easy today with a lighter routine."
    }

    private var moderateReadinessMessage: String {
        if let sleep = sleepHours, sleep < HealthThresholds.lowSleepHours {
            let rounded = String(format: "%.1f", sleep)
            return "You got \(rounded) hours of sleep, which is a little less than ideal. I've adjusted a few exercises to keep things comfortable."
        }
        if let hr = restingHeartRate, hr > HealthThresholds.elevatedHeartRate {
            return "Your resting heart rate is a bit higher than usual. I've eased up the routine a little."
        }
        return "Your energy is a little low today. I've made a few small adjustments so you can still have a great session."
    }

    var formattedSleep: String? {
        guard let h = sleepHours else { return nil }
        return String(format: "%.1f hrs", h)
    }

    var formattedEnergy: String? {
        guard let e = activeEnergyKcal else { return nil }
        return String(format: "%.0f kcal", e)
    }

    var formattedHeartRate: String? {
        guard let hr = restingHeartRate else { return nil }
        return String(format: "%.0f BPM", hr)
    }

    var formattedSteps: String? {
        guard let s = stepCount else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: Int(s)))
    }

    var formattedHRV: String? {
        guard let hrv = heartRateVariability else { return nil }
        return String(format: "%.0f ms", hrv)
    }

    static let noHealthData = HealthReadiness(
        sleepHours: nil,
        activeEnergyKcal: nil,
        restingHeartRate: nil,
        stepCount: nil,
        heartRateVariability: nil,
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
