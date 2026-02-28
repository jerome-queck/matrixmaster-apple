import SwiftUI
import MatrixFeatures

@main
struct MatrixMasterMobileApp: App {
    @StateObject private var coordinator = MatrixMasterFeatureCoordinator()

    var body: some Scene {
        WindowGroup {
            MobileRootView(coordinator: coordinator)
        }
    }
}
