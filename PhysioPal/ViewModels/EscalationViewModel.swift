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

    func callPhysiotherapist(contextMessage: String = "Please check incidents of the patient.") async {
        callState = .calling
        ptAction = nil

        let generator = UINotificationFeedbackGenerator()

        do {
            let result = try await TwilioService.shared.callPhysiotherapist(
                patientName: PatientProfile.mock.name,
                exerciseName: contextMessage
            )

            if result.status == .initiated {
                callSID = result.callSID
                callState = .connected
                generator.notificationOccurred(.success)
                startPolling()
            } else {
                callState = .failed
                generator.notificationOccurred(.error)
            }
        } catch {
            callState = .failed
            errorMessage = error.localizedDescription
            showError = true
            generator.notificationOccurred(.error)
        }
    }

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task {
            guard let sid = callSID else { return }

            for _ in 0..<30 {
                if Task.isCancelled { return }

                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if Task.isCancelled { return }

                do {
                    let response = try await TwilioService.shared.pollCallStatus(callSID: sid)

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
                        callState = .completed
                        return
                    }

                    if response.callStatus == "no-answer" || response.callStatus == "busy" || response.callStatus == "failed" {
                        callState = .failed
                        errorMessage = "The call couldn't be completed — your physiotherapist may be unavailable."
                        showError = true
                        return
                    }
                } catch {
                    // Network blip — keep polling
                }
            }

            if callState != .ptResponded {
                callState = .failed
                errorMessage = "Call timed out. Please verify ngrok PUBLIC_URL and Twilio webhook reachability."
                showError = true
            }
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
    }
}
