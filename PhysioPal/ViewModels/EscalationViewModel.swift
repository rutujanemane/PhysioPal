import Combine
import Foundation
import SwiftUI

@MainActor
final class EscalationViewModel: ObservableObject {
    @Published var callState: CallState = .idle
    @Published var showError = false
    @Published var errorMessage = ""

    enum CallState: Equatable {
        case idle
        case calling
        case connected
        case failed
    }

    func callPhysiotherapist() async {
        callState = .calling

        let generator = UINotificationFeedbackGenerator()

        do {
            let result = try await TwilioService.shared.callPhysiotherapist(
                ptPhoneNumber: TwilioConfig.ptPhoneNumber
            )

            if result.status == .initiated {
                callState = .connected
                generator.notificationOccurred(.success)
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

    func startVideoCall() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        ZoomService.shared.openVideoCall()
    }

    func reset() {
        callState = .idle
        showError = false
        errorMessage = ""
    }
}
