import SwiftUI

@main
struct PhysioPalApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .tint(AppColors.primary)
        }
    }
}
