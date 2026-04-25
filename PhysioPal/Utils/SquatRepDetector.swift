import Foundation

/// Matches workout-buddy `RepDetector`: full down-then-up squat cycle from knee angle (hip–knee–ankle), with debounce.
final class SquatRepDetector {
    private(set) var isInSquat: Bool = false
    private var lastRepTime: Date = .distantPast
    private let debounceDuration: TimeInterval = 0.85
    private let squatEnterAngle: Double = 135
    private let squatExitAngle: Double = 155

    /// Returns `true` when a full rep completed (entered squat depth, then stood back up).
    func update(kneeAngle: Double) -> Bool {
        if kneeAngle < squatEnterAngle, !isInSquat {
            isInSquat = true
            return false
        }
        if kneeAngle > squatExitAngle, isInSquat {
            isInSquat = false
            let now = Date()
            if now.timeIntervalSince(lastRepTime) >= debounceDuration {
                lastRepTime = now
                return true
            }
        }
        return false
    }

    func reset() {
        isInSquat = false
        lastRepTime = .distantPast
    }
}

/// Knee Y threshold with hysteresis + debounce (reduces jitter vs a single crossing line).
final class VerticalKneeHysteresisRepDetector {
    private var downLatched = false
    private var lastRepTime: Date = .distantPast
    private let debounceDuration: TimeInterval = 0.85
    private let enterY: Double = 0.62
    private let exitY: Double = 0.48

    func update(kneeY: Double) -> Bool {
        if kneeY > enterY { downLatched = true }
        if downLatched, kneeY < exitY {
            downLatched = false
            let now = Date()
            if now.timeIntervalSince(lastRepTime) >= debounceDuration {
                lastRepTime = now
                return true
            }
        }
        return false
    }

    func reset() {
        downLatched = false
        lastRepTime = .distantPast
    }
}
