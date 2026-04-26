import Foundation

final class TwilioService {
    static let shared = TwilioService()
    private init() {}

    func warmUpConnection() async {
        guard let url = URL(string: "\(TwilioConfig.serverURL)/call-status/warmup") else { return }
        var request = URLRequest(url: url)
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("PhysioPal/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 5
        print("[Twilio] Warming up ngrok tunnel...")
        let start = Date()
        _ = try? await URLSession.shared.data(for: request)
        print("[Twilio] Warmup completed in \(String(format: "%.2f", Date().timeIntervalSince(start)))s")
    }

    func callPhysiotherapist(patientName: String, exerciseName: String, context: String? = nil) async throws -> CallResult {
        guard let url = URL(string: "\(TwilioConfig.serverURL)/make-call") else {
            throw TwilioError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.setValue("PhysioPal/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        var body: [String: String] = [
            "patient_name": patientName,
            "exercise_name": exerciseName,
        ]
        if let context { body["context"] = context }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TwilioError.invalidResponse
        }

        let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? ""
        let bodyString = String(data: data, encoding: .utf8) ?? ""
        if contentType.contains("text/html") || bodyString.hasPrefix("<!DOCTYPE") || bodyString.contains("<html") {
            print("[Twilio] Received HTML instead of JSON — ngrok interstitial detected")
            throw TwilioError.ngrokInterstitial
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw TwilioError.apiError(statusCode: httpResponse.statusCode, message: bodyString)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let callSID = json?["sid"] as? String ?? "unknown"
        let status = json?["status"] as? String

        return CallResult(
            callSID: callSID,
            status: status == "initiated" ? .initiated : .failed
        )
    }

    func pollCallStatus(callSID: String) async throws -> PTResponse {
        guard let url = URL(string: "\(TwilioConfig.serverURL)/call-status/\(callSID)") else {
            throw TwilioError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.setValue("PhysioPal/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let callStatus = json?["call_status"] as? String ?? "unknown"
        let ptResponse = json?["pt_response"] as? String
        let meetingURL = json?["meeting_url"] as? String

        return PTResponse(
            callStatus: callStatus,
            ptAction: ptResponse.flatMap { PTAction(rawValue: $0) },
            meetingURL: meetingURL
        )
    }
}

struct CallResult {
    let callSID: String
    let status: CallStatus

    enum CallStatus {
        case initiated
        case failed
    }
}

struct PTResponse {
    let callStatus: String
    let ptAction: PTAction?
    let meetingURL: String?

    var isComplete: Bool {
        ptAction != nil || callStatus == "completed" || callStatus == "no-answer" || callStatus == "busy" || callStatus == "failed"
    }
}

enum PTAction: String {
    case callback
    case encouragement
    case videocall
    case dismissed
    case unknown

    var displayMessage: String {
        switch self {
        case .callback:
            return "Your physiotherapist will call you back shortly!"
        case .encouragement:
            return "Your physiotherapist says: Keep going, you're doing great!"
        case .videocall:
            return "Your physiotherapist wants to see you. Join the video call below."
        case .dismissed:
            return "Your physiotherapist has been notified."
        case .unknown:
            return "Your physiotherapist has been reached."
        }
    }

    var icon: String {
        switch self {
        case .callback: return "phone.arrow.down.left"
        case .encouragement: return "hand.thumbsup.fill"
        case .videocall: return "video.fill"
        case .dismissed: return "checkmark.circle.fill"
        case .unknown: return "info.circle.fill"
        }
    }
}

enum TwilioError: LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case ngrokInterstitial
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not connect to the calling service."
        case .invalidResponse:
            return "Received an unexpected response."
        case .ngrokInterstitial:
            return "The server connection is warming up. Please try again."
        case .apiError(_, let message):
            return "Call could not be placed: \(message)"
        }
    }
}

enum TwilioConfig {
    #if targetEnvironment(simulator)
    static let serverURL = "http://127.0.0.1:5004"
    #else
    static let serverURL = "https://lagoon-handgrip-glance.ngrok-free.dev"
    #endif
}
