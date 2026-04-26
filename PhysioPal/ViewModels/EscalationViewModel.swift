import Combine
import Foundation
import SwiftUI

@MainActor
final class EscalationViewModel: ObservableObject {
    @Published var callState: CallState = .idle
    @Published var ptAction: PTAction?
    @Published var meetingURL: URL?
    @Published var showError = false
    @Published var errorMessage = ""

    private var callSID: String?
    private var pollingTask: Task<Void, Never>?

    enum CallState: Equatable {
        case idle
        case calling
        case ringing
        case connected
        case ptResponded
        case completed
        case failed
    }

    private var lastExerciseName: String?
    private var lastContext: String?

    func callPhysiotherapist(exerciseName: String = "general check-in", context: String? = nil) async {
        callState = .calling
        ptAction = nil
        lastExerciseName = exerciseName
        lastContext = context

        let generator = UINotificationFeedbackGenerator()
        print("[Escalation] Calling PT at \(TwilioConfig.serverURL)/make-call (exercise: \(exerciseName))")

        await TwilioService.shared.warmUpConnection()

        var lastError: Error?
        for attempt in 0..<3 {
            if attempt > 0 {
                print("[Escalation] Retry \(attempt)/2 after ngrok interstitial...")
                try? await Task.sleep(nanoseconds: 1_500_000_000)
            }
            do {
                let result = try await TwilioService.shared.callPhysiotherapist(
                    patientName: PatientProfile.mock.name,
                    exerciseName: exerciseName,
                    context: context
                )
                print("[Escalation] Call result: SID=\(result.callSID), status=\(result.status)")

                if result.status == .initiated {
                    callSID = result.callSID
                    callState = .connected
                    generator.notificationOccurred(.success)
                    startPolling()
                    return
                } else {
                    lastError = TwilioError.apiError(statusCode: 0, message: "Call not initiated")
                }
            } catch let error as TwilioError where error == .ngrokInterstitial {
                print("[Escalation] Attempt \(attempt): ngrok interstitial — will retry")
                lastError = error
                continue
            } catch {
                print("[Escalation] Call failed: \(error)")
                lastError = error
                break
            }
        }

        callState = .failed
        errorMessage = lastError?.localizedDescription ?? "Could not reach the calling service."
        showError = true
        generator.notificationOccurred(.error)
    }

    private var hasAutoRetried = false

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task {
            guard let sid = callSID else { return }

            for pollIndex in 0..<30 {
                if Task.isCancelled { return }

                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if Task.isCancelled { return }

                do {
                    let response = try await TwilioService.shared.pollCallStatus(callSID: sid)
                    print("[Escalation] Poll \(pollIndex): status=\(response.callStatus) ptAction=\(response.ptAction?.rawValue ?? "nil")")

                    if response.callStatus == "ringing" && callState == .connected {
                        callState = .ringing
                    }

                    if let action = response.ptAction {
                        ptAction = action
                        if let urlString = response.meetingURL, let url = URL(string: urlString) {
                            meetingURL = url
                        }
                        callState = .ptResponded
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        return
                    }

                    if response.callStatus == "completed" && response.ptAction == nil {
                        if pollIndex <= 3, !hasAutoRetried {
                            print("[Escalation] Call completed too quickly (poll \(pollIndex)) — auto-retrying")
                            hasAutoRetried = true
                            autoRetry()
                            return
                        }
                        callState = .completed
                        return
                    }

                    if response.callStatus == "no-answer" || response.callStatus == "busy" || response.callStatus == "failed" {
                        if pollIndex <= 3, !hasAutoRetried {
                            print("[Escalation] Call failed early (poll \(pollIndex), status=\(response.callStatus)) — auto-retrying")
                            hasAutoRetried = true
                            autoRetry()
                            return
                        }
                        callState = .failed
                        errorMessage = "The call couldn't be completed — your physiotherapist may be unavailable."
                        showError = true
                        return
                    }
                } catch {
                    print("[Escalation] Poll \(pollIndex) network error: \(error)")
                }
            }

            if callState != .ptResponded {
                callState = .failed
                errorMessage = "Call timed out. Please verify ngrok PUBLIC_URL and Twilio webhook reachability."
                showError = true
            }
        }
    }

    private func autoRetry() {
        Task {
            print("[Escalation] Auto-retry: placing call again")
            await callPhysiotherapist(
                exerciseName: lastExerciseName ?? "general check-in",
                context: lastContext
            )
        }
    }

    func startVideoCall() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        ZoomService.shared.openVideoCall()
    }

    func joinMeeting() {
        guard let url = meetingURL else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        UIApplication.shared.open(url)
    }

    func reset() {
        pollingTask?.cancel()
        callState = .idle
        ptAction = nil
        meetingURL = nil
        callSID = nil
        showError = false
        errorMessage = ""
        hasAutoRetried = false
        lastExerciseName = nil
        lastContext = nil
    }
}
