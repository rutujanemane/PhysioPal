import Foundation

final class TwilioService {
    static let shared = TwilioService()

    private let accountSID: String
    private let authToken: String
    private let fromNumber: String

    private init() {
        self.accountSID = TwilioConfig.accountSID
        self.authToken = TwilioConfig.authToken
        self.fromNumber = TwilioConfig.fromNumber
    }

    func callPhysiotherapist(ptPhoneNumber: String) async throws -> CallResult {
        let urlString = "https://api.twilio.com/2010-04-01/Accounts/\(accountSID)/Calls.json"
        guard let url = URL(string: urlString) else {
            throw TwilioError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let credentials = "\(accountSID):\(authToken)"
        let encodedCredentials = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(encodedCredentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let twiml = "<Response><Say voice=\"alice\">Your patient needs assistance with their exercise routine. Connecting you now.</Say></Response>"
        let params = [
            "To": ptPhoneNumber,
            "From": fromNumber,
            "Twiml": twiml
        ]
        let bodyString = params.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)

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

        return CallResult(callSID: callSID, status: .initiated)
    }
}

struct CallResult {
    let callSID: String
    let status: CallStatus

    enum CallStatus {
        case initiated
        case ringing
        case connected
        case failed
    }
}

enum TwilioError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Could not connect to the calling service."
        case .invalidResponse: return "Received an unexpected response."
        case .apiError(_, let message): return "Call could not be placed: \(message)"
        }
    }
}

enum TwilioConfig {
    static let accountSID = "YOUR_TWILIO_ACCOUNT_SID"
    static let authToken = "YOUR_TWILIO_AUTH_TOKEN"
    static let fromNumber = "+1XXXXXXXXXX"
    static let ptPhoneNumber = "+1XXXXXXXXXX"
}
