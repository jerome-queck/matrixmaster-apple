import SwiftUI
import MatrixDomain
import MatrixFeatures

enum MobileShellDefaults {
    static let defaultDestination: MatrixMasterDestination = .solve
}

struct MobileRootView: View {
    @ObservedObject var coordinator: MatrixMasterFeatureCoordinator
    @State private var selectedDestination: MatrixMasterDestination = MobileShellDefaults.defaultDestination

    var body: some View {
        TabView(selection: $selectedDestination) {
            ForEach(MatrixMasterDestination.allCases) { destination in
                NavigationStack {
                    MatrixMasterFeatureDestinationView(
                        destination: destination,
                        coordinator: coordinator
                    )
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            modePicker
                        }
                    }
                }
                .tabItem {
                    Label(destination.title, systemImage: destination.systemImageName)
                }
                .tag(destination)
            }
        }
        .task {
            await coordinator.restoreLatestSnapshot()
        }
        .accessibilityIdentifier("mobile-root-tab-view")
    }

    private var modePicker: some View {
        Picker("Mode", selection: $coordinator.selectedMode) {
            ForEach(MatrixMasterMathMode.allCases, id: \.self) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 220)
        .accessibilityIdentifier("mobile-mode-picker")
        .accessibilityLabel("Math mode")
    }
}
