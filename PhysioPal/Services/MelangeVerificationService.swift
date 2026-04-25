import Foundation

#if canImport(ZeticMLange)
import ZeticMLange
#endif

enum MelangeVerificationService {
    static func verifyPoseModelSetup() {
        #if canImport(ZeticMLange)
        guard let key = MelangeConfig.personalKey else {
            print("[Melange] Missing MELANGE_PERSONAL_KEY. Set it in Scheme environment variables.")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                _ = try ZeticMLangeModel(
                    personalKey: key,
                    name: MelangeConfig.poseModelKey,
                    version: MelangeConfig.poseModelVersion,
                    modelMode: .RUN_AUTO,
                    onDownload: { progress in
                        print("[Melange] Download progress: \(Int(progress * 100))%")
                    }
                )
                print("[Melange] Pose model initialized successfully.")
            } catch {
                print("[Melange] Pose model init failed: \(error)")
            }
        }
        #else
        print("[Melange] SDK not linked in this build (simulator path is expected).")
        #endif
    }
}
