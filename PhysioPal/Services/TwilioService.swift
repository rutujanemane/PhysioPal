import Foundation

final class TwilioService {
    static let shared = TwilioService()
    private init() {}

    func callPhysiotherapist(patientName: String, exerciseName: String) async throws -> CallResult {
        guard let url = URL(string: "\(TwilioConfig.serverURL)/make-call") else {
            throw TwilioError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let body: [String: String] = [
            "patient_name": patientName,
            "exercise_name": exerciseName,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TwilioError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TwilioError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
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

enum TwilioError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not connect to the calling service."
        case .invalidResponse:
            return "Received an unexpected response."
        case .apiError(_, let message):
            return "Call could not be placed: \(message)"
        }
    }
}

enum TwilioConfig {
    static var serverURL: String {
        if let value = ProcessInfo.processInfo.environment["TWILIO_SERVER_URL"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !value.isEmpty {
            return value
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "TWILIO_SERVER_URL") as? String,
           !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return value
        }
        #if targetEnvironment(simulator)
        return "http://127.0.0.1:5004"
        #else
        return "http://10.30.175.26:5004"
        #endif
    }
}
