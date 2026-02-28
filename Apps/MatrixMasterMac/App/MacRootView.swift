import SwiftUI
import MatrixDomain
import MatrixFeatures

enum MacShellDefaults {
    static let defaultDestination: MatrixMasterDestination = .solve
}

struct MacRootView: View {
    @ObservedObject var coordinator: MatrixMasterFeatureCoordinator
    @State private var selectedDestination: MatrixMasterDestination? = MacShellDefaults.defaultDestination

    var body: some View {
        NavigationSplitView {
            List(MatrixMasterDestination.allCases, selection: $selectedDestination) { destination in
                Label(destination.title, systemImage: destination.systemImageName)
                    .tag(destination)
            }
            .navigationTitle("Matrix Master")
            .accessibilityIdentifier("mac-destination-list")
        } detail: {
            if let selectedDestination {
                MatrixMasterFeatureDestinationView(
                    destination: selectedDestination,
                    coordinator: coordinator
                )
            } else {
                ContentUnavailableView("Select a Tool", systemImage: "sidebar.left")
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                modePicker
            }
        }
        .frame(minWidth: 960, minHeight: 640)
        .task {
            await coordinator.restoreLatestSnapshot()
        }
    }

    private var modePicker: some View {
        Picker("Mode", selection: $coordinator.selectedMode) {
            ForEach(MatrixMasterMathMode.allCases, id: \.self) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 220)
        .accessibilityIdentifier("mac-mode-picker")
        .accessibilityLabel("Math mode")
    }
}
