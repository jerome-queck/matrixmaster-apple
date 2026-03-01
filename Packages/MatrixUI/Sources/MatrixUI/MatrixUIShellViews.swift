import Foundation
import SwiftUI
import MatrixDomain

public struct MatrixMasterDestinationPlaceholder: View {
    public let destination: MatrixMasterDestination
    public let mode: MatrixMasterMathMode
    public let lastResult: MatrixMasterComputationResult?

    public init(
        destination: MatrixMasterDestination,
        mode: MatrixMasterMathMode,
        lastResult: MatrixMasterComputationResult?
    ) {
        self.destination = destination
        self.mode = mode
        self.lastResult = lastResult
    }

    public var body: some View {
        MatrixResultPresentationView(
            destination: destination,
            mode: mode,
            lastResult: lastResult
        )
        .accessibilityIdentifier("destination-placeholder-\(destination.rawValue)")
    }
}

public struct MatrixMasterSyncBadge: View {
    public let state: MatrixMasterSyncState

    public init(state: MatrixMasterSyncState) {
        self.state = state
    }

    public var body: some View {
        Label(state.title, systemImage: iconName)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(MatrixUIDesignTokens.ColorPalette.controlBackground))
            .accessibilityIdentifier("sync-state-\(state.rawValue)")
    }

    private var iconName: String {
        switch state {
        case .localOnly:
            return "externaldrive"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .synced:
            return "checkmark.icloud"
        case .needsAttention:
            return "exclamationmark.triangle"
        }
    }

}
