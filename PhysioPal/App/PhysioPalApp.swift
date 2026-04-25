import SwiftUI

@main
struct PhysioPalApp: App {
    init() {
        #if DEBUG
        MelangeVerificationService.verifyPoseModelSetup()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .tint(AppColors.primary)
        }
    }
}
