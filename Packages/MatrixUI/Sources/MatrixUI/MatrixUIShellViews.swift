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
        VStack(alignment: .leading, spacing: 16) {
            Text(destination.title)
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Mode: \(mode.title)")
                .font(.headline)
                .foregroundStyle(.secondary)
            if let lastResult {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last Result")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(lastResult.answer)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            } else {
                Text("No result yet. Run a sample computation to validate the shell.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBackgroundColor)
        )
        .accessibilityIdentifier("destination-placeholder-\(destination.rawValue)")
    }

    private var cardBackgroundColor: Color {
        #if os(iOS) || os(tvOS) || os(visionOS)
        return Color(uiColor: .secondarySystemBackground)
        #elseif os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color.gray.opacity(0.12)
        #endif
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
            .background(Capsule().fill(badgeBackgroundColor))
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

    private var badgeBackgroundColor: Color {
        #if os(iOS) || os(tvOS) || os(visionOS)
        return Color(uiColor: .tertiarySystemBackground)
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color.gray.opacity(0.2)
        #endif
    }
}
