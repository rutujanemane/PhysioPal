import Foundation
import UIKit

final class ZoomService {
    static let shared = ZoomService()

    func openVideoCall() {
        guard let url = URL(string: ZoomConfig.meetingLink) else { return }

        Task { @MainActor in
            if UIApplication.shared.canOpenURL(url) {
                await UIApplication.shared.open(url)
            } else if let webURL = URL(string: ZoomConfig.webFallbackLink) {
                await UIApplication.shared.open(webURL)
            }
        }
    }
}

enum ZoomConfig {
    static let meetingLink = "https://zoom.us/j/YOUR_MEETING_ID?pwd=YOUR_PASSWORD"
    static let webFallbackLink = "https://zoom.us/j/YOUR_MEETING_ID"
}
