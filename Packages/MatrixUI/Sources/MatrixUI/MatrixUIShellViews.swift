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
                    Text("Answer")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(formattedMath(lastResult.answer))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }

                if !lastResult.diagnostics.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Diagnostics")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ForEach(lastResult.diagnostics, id: \.self) { diagnostic in
                            Text("- \(formattedMath(diagnostic))")
                                .font(.footnote)
                                .monospacedDigit()
                        }
                    }
                }

                if !lastResult.steps.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Steps")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ForEach(Array(lastResult.steps.enumerated()), id: \.offset) { index, step in
                            Text("\(index + 1). \(formattedMath(step))")
                                .font(.footnote)
                                .monospacedDigit()
                        }
                    }
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
                .fill(MatrixUIDesignTokens.ColorPalette.cardBackground)
        )
        .accessibilityIdentifier("destination-placeholder-\(destination.rawValue)")
    }

    private func formattedMath(_ text: String) -> String {
        var rendered = text.replacingOccurrences(of: "A^-1", with: "A⁻¹")
        rendered = replacingIndexedSymbol(in: rendered, symbol: "x")
        rendered = replacingIndexedSymbol(in: rendered, symbol: "c")
        rendered = replacingIndexedSymbol(in: rendered, symbol: "R")
        return rendered
    }

    private func replacingIndexedSymbol(in text: String, symbol: Character) -> String {
        var output = ""
        var index = text.startIndex

        while index < text.endIndex {
            let current = text[index]
            if current == symbol {
                let previous = index > text.startIndex ? text[text.index(before: index)] : nil
                let hasWordPrefix = previous.map { character in
                    character.isLetter || character.isNumber || character == "_"
                } ?? false

                if !hasWordPrefix {
                    var digits = ""
                    var digitIndex = text.index(after: index)

                    while digitIndex < text.endIndex, text[digitIndex].isNumber {
                        digits.append(text[digitIndex])
                        digitIndex = text.index(after: digitIndex)
                    }

                    if !digits.isEmpty {
                        output.append(symbol)
                        output.append(subscriptDigits(digits))
                        index = digitIndex
                        continue
                    }
                }
            }

            output.append(current)
            index = text.index(after: index)
        }

        return output
    }

    private func subscriptDigits(_ digits: String) -> String {
        let mapping: [Character: Character] = [
            "0": "₀",
            "1": "₁",
            "2": "₂",
            "3": "₃",
            "4": "₄",
            "5": "₅",
            "6": "₆",
            "7": "₇",
            "8": "₈",
            "9": "₉"
        ]

        return String(digits.map { mapping[$0] ?? $0 })
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
