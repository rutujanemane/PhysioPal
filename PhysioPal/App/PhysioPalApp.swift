import SwiftUI

@main
struct PhysioPalApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RoleSelectionView()
            }
            .tint(AppColors.primary)
        }
    }
}
