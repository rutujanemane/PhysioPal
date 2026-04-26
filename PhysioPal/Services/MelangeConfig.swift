import Foundation

enum MelangeConfig {
    // Keep model key in source (safe), keep personal key out of source.
    static let poseModelKey = "Steve/pose_estimation"
    static let poseModelVersion: Int? = 1

    static let llmModelName = "Steve/Qwen3.5-2B"
    static let llmModelVersion: Int = 1
    static let llmPersonalKey = "dev_3d7e6b41c97e4e32965e5de26c9f2154"

    static var personalKey: String? {
        // 1) Preferred: Scheme Environment Variable
        if let env = ProcessInfo.processInfo.environment["MELANGE_PERSONAL_KEY"], !env.isEmpty {
            return env
        }
        // 2) Optional: Info.plist value
        if let plist = Bundle.main.object(forInfoDictionaryKey: "MELANGE_PERSONAL_KEY") as? String,
           !plist.isEmpty {
            return plist
        }
        return nil
    }
}
