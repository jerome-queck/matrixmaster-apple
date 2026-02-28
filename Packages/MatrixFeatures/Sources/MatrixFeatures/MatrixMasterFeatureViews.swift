import SwiftUI
import MatrixDomain
import MatrixUI

public struct MatrixMasterFeatureDestinationView: View {
    public let destination: MatrixMasterDestination
    @ObservedObject private var coordinator: MatrixMasterFeatureCoordinator

    public init(
        destination: MatrixMasterDestination,
        coordinator: MatrixMasterFeatureCoordinator
    ) {
        self.destination = destination
        self.coordinator = coordinator
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MatrixMasterSyncBadge(state: coordinator.syncState)

                MatrixMasterDestinationPlaceholder(
                    destination: destination,
                    mode: coordinator.selectedMode,
                    lastResult: coordinator.lastResult
                )

                editorSurface

                if let validationMessage = coordinator.inputValidationMessage {
                    MatrixValidationMessageView(message: validationMessage)
                }

                if let persistenceMessage = coordinator.persistenceMessage {
                    MatrixValidationMessageView(message: persistenceMessage)
                }

                Button("Run Sample \(destination.title) Computation") {
                    Task {
                        await coordinator.runQuickComputation(for: destination)
                    }
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("run-sample-\(destination.rawValue)")
            }
            .padding()
        }
        .navigationTitle(destination.title)
    }

    @ViewBuilder
    private var editorSurface: some View {
        switch destination {
        case .solve, .operate:
            MatrixGridEditorView(
                matrix: $coordinator.matrixDraft,
                title: "\(destination.title) Matrix Input"
            )
        case .analyze:
            MatrixGridEditorView(
                matrix: $coordinator.matrixDraft,
                title: "Analyze Matrix Input"
            )
            BasisEditorView(basis: $coordinator.basisDraft)
        case .library:
            VectorEditorView(
                vector: $coordinator.vectorDraft,
                title: "Reusable Vector Draft",
                showsNameField: true
            )
        }
    }
}
