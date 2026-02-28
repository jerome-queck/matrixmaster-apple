import SwiftUI
import MatrixFeatures

@main
struct MatrixMasterMobileApp: App {
    @StateObject private var coordinator = MatrixMasterFeatureCoordinator.foundationCoordinator()

    var body: some Scene {
        WindowGroup {
            MobileRootView(coordinator: coordinator)
        }
    }
}
