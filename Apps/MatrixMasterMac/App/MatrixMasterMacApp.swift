import SwiftUI
import MatrixFeatures

@main
struct MatrixMasterMacApp: App {
    @StateObject private var coordinator = MatrixMasterFeatureCoordinator.foundationCoordinator()

    var body: some Scene {
        WindowGroup {
            MacRootView(coordinator: coordinator)
        }
        .windowResizability(.contentSize)
    }
}
