import Foundation
import SwiftUI
import WebKit
import MatrixDomain

public struct MatrixResultPresentationView: View {
    public let destination: MatrixMasterDestination
    public let mode: MatrixMasterMathMode
    public let lastResult: MatrixMasterComputationResult?
    @State private var isMathObjectsExpanded = true
    @State private var isDiagnosticsExpanded = false
    @State private var isStepsExpanded = false
    @State private var showsAllMathObjects = false
    @State private var showsAllDiagnostics = false
    @State private var showsAllSteps = false

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
        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
            Text(destination.title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Mode: \(mode.title)")
                .font(.headline)
                .foregroundStyle(.secondary)

            if let lastResult {
                if usesMergedDetailPanels {
                    MatrixResultMetricAccordionView(
                        destination: destination,
                        result: lastResult
                    )
                } else {
                    answerSurface(lastResult)

                    if !lastResult.structuredObjects.isEmpty {
                        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
                            DisclosureGroup(isExpanded: $isMathObjectsExpanded) {
                                let visibleObjects = showsAllMathObjects
                                    ? lastResult.structuredObjects
                                    : Array(lastResult.structuredObjects.prefix(3))

                                LazyVStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
                                    ForEach(visibleObjects) { object in
                                        MatrixMathObjectCardView(object: object)
                                    }
                                }

                                if lastResult.structuredObjects.count > 3 {
                                    Button(showsAllMathObjects ? "Show fewer" : "Show all (\(lastResult.structuredObjects.count))") {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showsAllMathObjects.toggle()
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                }
                            } label: {
                                Text("Math Objects")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if let rowReductionPanels = lastResult.rowReductionPanels {
                    MatrixRowReductionPanelsView(panels: rowReductionPanels)
                }

                if !usesMergedDetailPanels {
                    let diagnostics = MatrixResultTextFormatter.uniqueSegments(lastResult.diagnostics)
                    if !diagnostics.isEmpty {
                        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.compact) {
                            DisclosureGroup(isExpanded: $isDiagnosticsExpanded) {
                                let visibleDiagnostics = showsAllDiagnostics
                                    ? diagnostics
                                    : Array(diagnostics.prefix(8))

                                LazyVStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.compact) {
                                    ForEach(Array(visibleDiagnostics.enumerated()), id: \.offset) { index, line in
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("•")
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                                .padding(.top, 2)
                                            MatrixInlineMathTextView(
                                                line: line,
                                                emphasis: false,
                                                accessibilityIdentifier: "result-diagnostic-text-\(index)"
                                            )
                                        }
                                    }
                                }

                                if diagnostics.count > 8 {
                                    Button(showsAllDiagnostics ? "Show fewer" : "Show all (\(diagnostics.count))") {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showsAllDiagnostics.toggle()
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                }
                            } label: {
                                Text("Diagnostics")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    let steps = MatrixResultTextFormatter.uniqueSegments(lastResult.steps)
                    if !steps.isEmpty {
                        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.compact) {
                            DisclosureGroup(isExpanded: $isStepsExpanded) {
                                let visibleSteps = showsAllSteps
                                    ? steps
                                    : Array(steps.prefix(10))

                                LazyVStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.compact) {
                                    ForEach(Array(visibleSteps.enumerated()), id: \.offset) { index, line in
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("\(index + 1).")
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                                .padding(.top, 2)
                                            MatrixInlineMathTextView(
                                                line: line,
                                                emphasis: false,
                                                accessibilityIdentifier: "result-step-text-\(index)"
                                            )
                                        }
                                    }
                                }

                                if steps.count > 10 {
                                    Button(showsAllSteps ? "Show fewer" : "Show all (\(steps.count))") {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showsAllSteps.toggle()
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                }
                            } label: {
                                Text("Steps")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } else {
                Text("No result in this tab yet. Run a computation to see results.")
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
        .onChange(of: destination) { _, _ in
            resetExpandedSections()
        }
        .onChange(of: lastResult?.answer) { _, _ in
            showsAllMathObjects = false
            showsAllDiagnostics = false
            showsAllSteps = false
        }
        .accessibilityIdentifier("destination-result-surface-\(destination.rawValue)")
    }

    private var usesMergedDetailPanels: Bool {
        destination == .analyze || destination == .spaces
    }

    @ViewBuilder
    private func answerSurface(_ result: MatrixMasterComputationResult) -> some View {
        let lines = MatrixResultTextFormatter.answerSegments(result.answer)

        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.compact) {
            Text("Answer")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if lines.isEmpty {
                Text("No answer available.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("result-answer-text")
            } else {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    HStack(alignment: .top, spacing: 8) {
                        if lines.count > 1 {
                            Text("•")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        }

                        MatrixInlineMathTextView(
                            line: line,
                            emphasis: true,
                            accessibilityIdentifier: index == 0 ? "result-answer-text" : "result-answer-text-\(index)"
                        )
                    }
                }
            }
        }
    }

    private func resetExpandedSections() {
        isMathObjectsExpanded = true
        isDiagnosticsExpanded = false
        isStepsExpanded = false
        showsAllMathObjects = false
        showsAllDiagnostics = false
        showsAllSteps = false
    }
}

private struct MatrixInlineMathTextView: View {
    let line: String
    let emphasis: Bool
    let accessibilityIdentifier: String?

    var body: some View {
        MatrixInlineMathText(
            MatrixResultTextFormatter.formattedLine(line),
            style: emphasis ? .bodyEmphasis : .body,
            accessibilityLabel: line
        )
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .ifLet(accessibilityIdentifier) { view, identifier in
                view.accessibilityIdentifier(identifier)
            }
    }
}

private struct MatrixResultMetricAccordionView: View {
    let destination: MatrixMasterDestination
    let result: MatrixMasterComputationResult
    @State private var expandedMetricIndices: Set<Int> = []
    @State private var metricInfo: MatrixMetricInfoPayload?

    private var answerLines: [String] {
        MatrixResultTextFormatter.answerSegments(result.answer)
    }

    private var diagnostics: [String] {
        MatrixResultTextFormatter.uniqueSegments(result.diagnostics)
    }

    private var steps: [String] {
        MatrixResultTextFormatter.uniqueSegments(result.steps)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.compact) {
            Text("Answer")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if answerLines.isEmpty {
                Text("No answer available.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("result-answer-text")
            } else {
                ForEach(Array(answerLines.enumerated()), id: \.offset) { index, line in
                    DisclosureGroup(isExpanded: expandedBinding(for: index)) {
                        detailSection(for: line)
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            if answerLines.count > 1 {
                                Text("•")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 2)
                            }

                            MatrixInlineMathTextView(
                                line: line,
                                emphasis: true,
                                accessibilityIdentifier: index == 0 ? "result-answer-text" : "result-answer-text-\(index)"
                            )

                            Spacer(minLength: 8)

                            Button {
                                metricInfo = MatrixMetricInfoPayload(
                                    title: MatrixResultTextFormatter.formattedLine(line),
                                    body: metricInfoDescription(for: line)
                                )
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("result-metric-info-\(index)")
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .onChange(of: result.answer) { _, _ in
            expandedMetricIndices = []
        }
        .sheet(item: $metricInfo) { info in
            MatrixMetricInfoSheet(payload: info)
        }
    }

    @ViewBuilder
    private func detailSection(for line: String) -> some View {
        let keywords = detailKeywords(for: line)
        let relatedObjects = Array(matchingObjects(for: keywords).prefix(maxRelatedObjects(for: line)))
        let relatedDiagnostics = relatedLines(in: diagnostics, matching: keywords, limit: 6)
        let relatedSteps = relatedLines(in: steps, matching: keywords, limit: 6)

        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.compact) {
            if !relatedObjects.isEmpty {
                ForEach(relatedObjects) { object in
                    VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.compact) {
                        MatrixInlineMathText(
                            MatrixResultTextFormatter.prettyLabel(object.label),
                            style: .support,
                            color: .secondary
                        )
                        MatrixMathObjectRendererView(object: object)
                    }
                    .padding(MatrixUIDesignTokens.Spacing.compact)
                    .background(
                        RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.control)
                            .fill(MatrixUIDesignTokens.ColorPalette.controlBackground)
                    )
                }
            }

            if !relatedDiagnostics.isEmpty {
                MatrixInlineMathText("Diagnostics", style: .caption, color: .secondary)
                ForEach(Array(relatedDiagnostics.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                        MatrixInlineMathTextView(
                            line: item,
                            emphasis: false,
                            accessibilityIdentifier: "result-metric-diagnostic-\(index)"
                        )
                    }
                }
            }

            if !relatedSteps.isEmpty {
                MatrixInlineMathText("Steps", style: .caption, color: .secondary)
                ForEach(Array(relatedSteps.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                        MatrixInlineMathTextView(
                            line: item,
                            emphasis: false,
                            accessibilityIdentifier: "result-metric-step-\(index)"
                        )
                    }
                }
            }

            if relatedObjects.isEmpty && relatedDiagnostics.isEmpty && relatedSteps.isEmpty {
                MatrixInlineMathText(
                    "No extra details for this item.",
                    style: .support,
                    color: .secondary
                )
            }
        }
        .padding(.top, 4)
        .padding(.leading, answerLines.count > 1 ? 16 : 0)
    }

    private func expandedBinding(for index: Int) -> Binding<Bool> {
        Binding(
            get: { expandedMetricIndices.contains(index) },
            set: { isExpanded in
                if isExpanded {
                    expandedMetricIndices.insert(index)
                } else {
                    expandedMetricIndices.remove(index)
                }
            }
        )
    }

    private func matchingObjects(for keywords: [String]) -> [MatrixMathObject] {
        guard !keywords.isEmpty else {
            return []
        }

        let loweredKeywords = keywords.map { $0.lowercased() }
        let scored = result.structuredObjects.enumerated().compactMap { index, object -> (object: MatrixMathObject, score: Int, index: Int)? in
            let label = MatrixResultTextFormatter.prettyLabel(object.label).lowercased()
            let score = loweredKeywords.reduce(0) { partial, keyword in
                partial + (label.contains(keyword) ? 1 : 0)
            }
            guard score > 0 else {
                return nil
            }
            return (object, score, index)
        }

        return scored
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.index < rhs.index
                }
                return lhs.score > rhs.score
            }
            .map { $0.object }
    }

    private func relatedLines(
        in lines: [String],
        matching keywords: [String],
        limit: Int
    ) -> [String] {
        guard !keywords.isEmpty else {
            return []
        }

        return Array(lines.filter { line in
            matches(line.lowercased(), keywords: keywords)
        }.prefix(limit))
    }

    private func detailKeywords(for line: String) -> [String] {
        let lowered = line.lowercased()

        if lowered.contains("det(") || lowered.contains("determinant") {
            return ["det(", "determinant", "pivot"]
        }
        if lowered.contains("a^-1") || lowered.contains("inverse") {
            return ["inverse", "a^-1"]
        }
        if lowered.contains("dim col") || lowered.contains("col(a)") {
            return ["column", "col(a)", "pivot"]
        }
        if lowered.contains("dim row") || lowered.contains("row(a)") {
            return ["row", "row(a)", "row-space"]
        }
        if lowered.contains("dim null") || lowered.contains("null(a)") {
            return ["null", "null(a)", "free variable"]
        }
        if lowered.contains("rank(") {
            return ["rank", "pivot"]
        }
        if lowered.contains("nullity(") {
            return ["nullity", "free variable", "rank-nullity"]
        }
        if lowered.contains("trace(") || lowered.contains("tr(") {
            return ["trace", "tr("]
        }
        if lowered.contains("injective") {
            return ["injective criterion", "kernel basis", "nullity(t)"]
        }
        if lowered.contains("surjective") {
            return ["surjective criterion", "range basis", "codomain dimension"]
        }
        if lowered.contains("bijective") {
            return ["bijective criterion", "injective criterion", "surjective criterion"]
        }
        if lowered.contains("similar via basis change") || lowered.contains("similarity") {
            return ["similarity", "c_(gamma<-beta)", "c_(beta<-gamma)", "[t]_beta", "[t]_gamma"]
        }
        if lowered.contains("[t]") || lowered.contains("a_std") {
            return ["[t]", "a_std", "linear maps standard matrix a", "basis-relative map matrix", "[t]^beta_gamma"]
        }

        if destination == .spaces {
            if lowered.contains("basis") {
                return ["basis", "independent", "rank"]
            }
            if lowered.contains("span") {
                return ["span", "sum", "intersection", "direct"]
            }
        }

        let tokenized = lowered
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 }
        return Array(tokenized.prefix(3))
    }

    private func matches(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { keyword in
            text.contains(keyword)
        }
    }

    private func maxRelatedObjects(for line: String) -> Int {
        let lowered = line.lowercased()
        if lowered.contains("similar") {
            return 6
        }
        if lowered.contains("[t]") || lowered.contains("a_std") {
            return 4
        }
        return 2
    }

    private func metricInfoDescription(for line: String) -> String {
        let lowered = line.lowercased()

        if lowered.contains("det(") || lowered.contains("determinant") {
            return "Determinant measures oriented volume scaling; 0 means singular and non-invertible."
        }
        if lowered.contains("rank(") {
            return "Rank is the number of pivot columns, i.e. dimension of the image/column space."
        }
        if lowered.contains("nullity(") {
            return "Nullity is dim(ker(T)) and equals number of free variables."
        }
        if lowered.contains("dim col") || lowered.contains("range dim") {
            return "This is the dimension of the image (column space / range), computed from pivots."
        }
        if lowered.contains("dim row") {
            return "This is the row-space dimension, equal to rank."
        }
        if lowered.contains("dim null") || lowered.contains("kernel dim") {
            return "This is the kernel dimension, equal to nullity."
        }
        if lowered.contains("trace(") || lowered.contains("tr(") {
            return "Trace is the sum of diagonal entries and is invariant under basis change."
        }
        if lowered.contains("a^-1") || lowered.contains("inverse") {
            return "Inverse exists only when the matrix is square and full-rank."
        }
        if lowered.contains("injective") {
            return "Injective means ker(T) = {0}; equivalently rank(T) = dim(domain)."
        }
        if lowered.contains("surjective") {
            return "Surjective means Im(T) = codomain; equivalently rank(T) = dim(codomain)."
        }
        if lowered.contains("bijective") {
            return "Bijective means injective and surjective, so T has an inverse map."
        }
        if lowered.contains("similar") {
            return "Similarity compares matrix representations in two bases via C[T]C^{-1}; traces/determinants should match."
        }
        if lowered.contains("[t]") || lowered.contains("a_std") {
            return "This is a matrix representation of the linear map in a specific coordinate system."
        }

        return "This result item summarizes one computed property. Expand it to view supporting matrices, diagnostics, and steps."
    }
}

private struct MatrixMetricInfoPayload: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

private struct MatrixMetricInfoSheet: View {
    let payload: MatrixMetricInfoPayload
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
                MatrixInlineMathText(payload.title, style: .sectionTitle)
                MatrixInlineMathText(payload.body, style: .body)
                Spacer()
            }
            .padding(MatrixUIDesignTokens.Spacing.regular)
            .navigationTitle("Info")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

public struct MatrixMathObjectCardView: View {
    public var object: MatrixMathObject

    public init(object: MatrixMathObject) {
        self.object = object
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
            MatrixInlineMathText(
                MatrixResultTextFormatter.prettyLabel(object.label),
                style: .sectionTitle
            )
            .accessibilityIdentifier("structured-object-label-\(object.id.uuidString)")

            MatrixMathObjectRendererView(object: object)
        }
        .padding(MatrixUIDesignTokens.Spacing.regular)
        .background(
            RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.card)
                .fill(MatrixUIDesignTokens.ColorPalette.controlBackground)
        )
    }
}

public struct MatrixMathObjectRendererView: View {
    public let object: MatrixMathObject

    public init(object: MatrixMathObject) {
        self.object = object
    }

    public var body: some View {
        switch object {
        case let .matrix(matrix):
            MatrixBracketGridView(
                entries: matrix.entries,
                separatorAfterColumn: matrixSeparatorAfterColumn(for: matrix)
            )
        case let .vector(vector):
            MatrixVectorStackView(entries: vector.entries)
        case let .polynomial(polynomial):
            MatrixPolynomialObjectView(object: polynomial)
        }
    }

    private func matrixSeparatorAfterColumn(for object: MatrixMathMatrixObject) -> Int? {
        let lowered = object.label.lowercased()
        guard let columnCount = object.entries.first?.count, columnCount > 1 else {
            return nil
        }

        if lowered.contains("augmented"),
           lowered.contains("a|b") || lowered.contains("a | b") || lowered.contains("[a|b]") {
            return columnCount - 1
        }

        return nil
    }
}

public struct MatrixBracketGridView: View {
    public let entries: [[String]]
    public let separatorAfterColumn: Int?

    public init(entries: [[String]], separatorAfterColumn: Int? = nil) {
        self.entries = entries
        self.separatorAfterColumn = separatorAfterColumn
    }

    public var body: some View {
        MatrixLatexBlockView(
            latex: MatrixResultTextFormatter.matrixLatex(
                entries,
                separatorAfterColumn: separatorAfterColumn
            ),
            displayMode: true,
            accessibilityIdentifier: "structured-matrix-grid",
            allowsHorizontalScroll: true
        )
    }
}

public struct MatrixVectorStackView: View {
    public let entries: [String]

    public init(entries: [String]) {
        self.entries = entries
    }

    public var body: some View {
        MatrixLatexBlockView(
            latex: MatrixResultTextFormatter.columnVectorLatex(entries),
            displayMode: true,
            accessibilityIdentifier: "structured-vector-stack",
            allowsHorizontalScroll: true
        )
    }
}

public struct MatrixPolynomialObjectView: View {
    public let object: MatrixMathPolynomialObject

    public init(object: MatrixMathPolynomialObject) {
        self.object = object
    }

    public var body: some View {
        MatrixLatexBlockView(
            latex: MatrixResultTextFormatter.polynomialLatex(object),
            displayMode: true,
            accessibilityIdentifier: "structured-polynomial-expression",
            allowsHorizontalScroll: false
        )
    }
}

public struct MatrixRowReductionPanelsView: View {
    public let panels: MatrixRowReductionPanels
    @State private var isExpanded: Bool = false

    public init(panels: MatrixRowReductionPanels) {
        self.panels = panels
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
            DisclosureGroup(isExpanded: $isExpanded) {
                HStack(spacing: 6) {
                    Text("Source:")
                        .font(MatrixUIDesignTokens.Typography.supportText)
                        .foregroundStyle(.secondary)
                    MatrixInlineMathText(
                        MatrixResultTextFormatter.prettyLabel(panels.sourceLabel),
                        style: .support,
                        color: .secondary
                    )
                }

                #if os(iOS)
                VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
                    panel(title: "REF", entries: panels.refEntries, identifier: "result-ref-panel")
                    panel(title: "RREF", entries: panels.rrefEntries, identifier: "result-rref-panel")
                }
                #else
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: MatrixUIDesignTokens.Spacing.regular) {
                        panel(title: "REF", entries: panels.refEntries, identifier: "result-ref-panel")
                        panel(title: "RREF", entries: panels.rrefEntries, identifier: "result-rref-panel")
                    }
                    VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
                        panel(title: "REF", entries: panels.refEntries, identifier: "result-ref-panel")
                        panel(title: "RREF", entries: panels.rrefEntries, identifier: "result-rref-panel")
                    }
                }
                #endif
            } label: {
                Text("REF / RREF Panels")
                    .font(.headline)
            }
        }
        .padding(MatrixUIDesignTokens.Spacing.regular)
        .background(
            RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.card)
                .fill(MatrixUIDesignTokens.ColorPalette.controlBackground)
        )
        .accessibilityIdentifier("result-row-reduction-panels")
    }

    private func panel(title: String, entries: [[String]], identifier: String) -> some View {
        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.compact) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            MatrixLatexBlockView(
                latex: MatrixResultTextFormatter.matrixLatex(
                    entries,
                    separatorAfterColumn: panels.separatorAfterColumn
                ),
                displayMode: true,
                accessibilityIdentifier: identifier,
                allowsHorizontalScroll: true
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MatrixLatexBlockView: View {
    let latex: String
    let displayMode: Bool
    let accessibilityIdentifier: String?
    let allowsHorizontalScroll: Bool
    @Environment(\.colorScheme) private var colorScheme

    @State private var dynamicHeight: CGFloat

    init(
        latex: String,
        displayMode: Bool,
        accessibilityIdentifier: String?,
        allowsHorizontalScroll: Bool = false
    ) {
        self.latex = latex
        self.displayMode = displayMode
        self.accessibilityIdentifier = accessibilityIdentifier
        self.allowsHorizontalScroll = allowsHorizontalScroll
        _dynamicHeight = State(initialValue: MatrixLatexSizing.estimatedHeight(for: latex, displayMode: displayMode))
    }

    var body: some View {
        MatrixLatexWebContainer(
            latex: latex,
            displayMode: displayMode,
            isDarkMode: colorScheme == .dark,
            allowsHorizontalScroll: allowsHorizontalScroll,
            dynamicHeight: $dynamicHeight
        )
        .allowsHitTesting(allowsHorizontalScroll)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: max(28, dynamicHeight))
        .ifLet(accessibilityIdentifier) { view, identifier in
            view.accessibilityIdentifier(identifier)
        }
    }
}

private enum MatrixLatexSizing {
    static func estimatedHeight(for latex: String, displayMode: Bool) -> CGFloat {
        guard displayMode else {
            return 28
        }

        if latex.contains(#"\begin{bmatrix}"#) || latex.contains(#"\begin{array}"#) {
            let rowCount = rowBreakCount(in: latex) + 1
            return CGFloat(max(1, rowCount)) * 34 + 24
        }

        return 44
    }

    private static func rowBreakCount(in latex: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: #"\\\\"#, options: []) else {
            return 0
        }
        let range = NSRange(latex.startIndex..<latex.endIndex, in: latex)
        return regex.numberOfMatches(in: latex, options: [], range: range)
    }
}

private enum MatrixResultTextFormatter {
    static func answerSegments(_ answer: String) -> [String] {
        uniqueSegments(splitSegments(answer))
    }

    static func uniqueSegments(_ items: [String]) -> [String] {
        var output: [String] = []
        var seenSignatures: Set<String> = []
        for item in items {
            for segment in splitSegments(item) {
                let normalized = normalizeSpacing(in: segment)
                guard !normalized.isEmpty else {
                    continue
                }
                let signature = normalized.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                if !seenSignatures.insert(signature).inserted {
                    continue
                }
                output.append(normalized)
            }
        }
        return output
    }

    static func formattedLine(_ raw: String) -> String {
        let normalized = normalizeSpacing(in: raw)
        guard !normalized.isEmpty else {
            return raw
        }

        let operatorNormalized = replacingRegex(
            in: normalized,
            pattern: #"\\operatorname\{([^}]+)\}"#,
            template: "$1"
        )

        let formatted = operatorNormalized
            .replacingOccurrences(of: "[x]_beta", with: "[x]_{beta}")
            .replacingOccurrences(of: "[x]_gamma", with: "[x]_{gamma}")
            .replacingOccurrences(of: "inverse(A)", with: "A^-1")
            .replacingOccurrences(of: "trace(A)", with: "tr(A)")
            .replacingOccurrences(of: "beta", with: "β")
            .replacingOccurrences(of: "gamma", with: "γ")
            .replacingOccurrences(of: "\\operatorname", with: "")

        return normalizeIndexedSymbols(in: formatted)
    }

    static func prettyLabel(_ label: String) -> String {
        let normalized = normalizeSpacing(in: label)
        let linearMapAdjusted = normalized
            .replacingOccurrences(of: "Linear maps domain basis matrix B", with: "Linear maps B = [β_1 ... β_n] (domain basis columns)")
            .replacingOccurrences(of: "Linear maps codomain basis matrix G", with: "Linear maps G = [γ_1 ... γ_m] (codomain basis columns)")
            .replacingOccurrences(of: "Linear maps standard matrix A", with: "Linear maps A_std (standard-coordinate representation)")
            .replacingOccurrences(of: "Linear maps [T]^beta_gamma", with: "Linear maps [T]_{β→γ} (basis-relative map matrix)")
            .replacingOccurrences(of: "Linear maps C_(gamma<-beta)", with: "Linear maps C_{γ←β} (change of coordinates)")
            .replacingOccurrences(of: "Linear maps C_(beta<-gamma)", with: "Linear maps C_{β←γ} (change of coordinates)")

        return linearMapAdjusted
            .replacingOccurrences(of: "\\beta", with: "β")
            .replacingOccurrences(of: "\\gamma", with: "γ")
            .replacingOccurrences(of: "beta", with: "β")
            .replacingOccurrences(of: "gamma", with: "γ")
            .replacingOccurrences(of: "<-", with: "←")
            .replacingOccurrences(of: "->", with: "→")
    }

    static func matrixLatex(
        _ entries: [[String]],
        separatorAfterColumn: Int? = nil
    ) -> String {
        guard !entries.isEmpty, (entries.first?.isEmpty == false) else {
            return #"\begin{bmatrix}\end{bmatrix}"#
        }

        let rows = entries.map { row in
            row.map(tokenLatex).joined(separator: " & ")
        }.joined(separator: #" \\ "#)

        if let separatorAfterColumn {
            let columnCount = entries.first?.count ?? 0
            let safeSeparator = max(0, min(separatorAfterColumn, columnCount))
            var columnSpec = ""
            for index in 0..<columnCount {
                if index == safeSeparator {
                    columnSpec.append("|")
                }
                columnSpec.append("c")
            }

            return #"\left[\begin{array}{"# + columnSpec + #"} "# + rows + #" \end{array}\right]"#
        }

        return #"\begin{bmatrix} "# + rows + #" \end{bmatrix}"#
    }

    static func columnVectorLatex(_ entries: [String]) -> String {
        guard !entries.isEmpty else {
            return #"\begin{bmatrix} 0 \end{bmatrix}"#
        }

        let rows = entries.map(tokenLatex).joined(separator: #" \\ "#)
        return #"\begin{bmatrix} "# + rows + #" \end{bmatrix}"#
    }

    static func polynomialLatex(_ object: MatrixMathPolynomialObject) -> String {
        let raw = MatrixMathExportFormatter.latex(for: .polynomial(object))
        guard let equalsIndex = raw.firstIndex(of: "=") else {
            return raw
        }
        return String(raw[raw.index(after: equalsIndex)...]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func splitSegments(_ raw: String) -> [String] {
        raw
            .replacingOccurrences(of: "\n", with: " | ")
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { String($0) }
            .map(normalizeSpacing)
            .filter { !$0.isEmpty }
    }

    private static func normalizeSpacing(in text: String) -> String {
        var output = text.trimmingCharacters(in: .whitespacesAndNewlines)
        output = replacingRegex(in: output, pattern: #"\s+"#, template: " ")
        output = replacingRegex(in: output, pattern: #"\s*:\s*"#, template: ": ")
        output = replacingRegex(in: output, pattern: #"\s*,\s*"#, template: ", ")
        output = replacingRegex(in: output, pattern: #"\s*\|\s*"#, template: " | ")
        output = replacingRegex(in: output, pattern: #"\(\s+"#, template: "(")
        output = replacingRegex(in: output, pattern: #"\s+\)"#, template: ")")
        output = replacingRegex(in: output, pattern: #"\s+\."#, template: ".")
        return output
    }

    private static func normalizeIndexedSymbols(in text: String) -> String {
        var output = text
        output = replacingRegex(in: output, pattern: #"\b([A-Za-z])([0-9]+)\b"#, template: #"$1_$2"#)
        return output
    }

    private static func tokenLatex(_ token: String) -> String {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "0"
        }

        if let fraction = fractionLatex(trimmed) {
            return fraction
        }

        if trimmed == "∞" {
            return #"\infty"#
        }

        return trimmed
            .replacingOccurrences(of: "beta", with: #"\beta"#)
            .replacingOccurrences(of: "gamma", with: #"\gamma"#)
    }

    private static func fractionLatex(_ token: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: #"^(-?[0-9]+)\/([0-9]+)$"#, options: []) else {
            return nil
        }

        let range = NSRange(token.startIndex..<token.endIndex, in: token)
        guard let match = regex.firstMatch(in: token, options: [], range: range),
              let numeratorRange = Range(match.range(at: 1), in: token),
              let denominatorRange = Range(match.range(at: 2), in: token) else {
            return nil
        }

        return #"\frac{"# + token[numeratorRange] + "}{" + token[denominatorRange] + "}"
    }

    private static func replacingRegex(in text: String, pattern: String, template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: template)
    }
}

private struct MatrixLatexWebContainer: View {
    let latex: String
    let displayMode: Bool
    let isDarkMode: Bool
    let allowsHorizontalScroll: Bool
    @Binding var dynamicHeight: CGFloat

    var body: some View {
        MatrixLatexWebRepresentable(
            latex: latex,
            displayMode: displayMode,
            isDarkMode: isDarkMode,
            allowsHorizontalScroll: allowsHorizontalScroll,
            dynamicHeight: $dynamicHeight
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if os(iOS)
private struct MatrixLatexWebRepresentable: UIViewRepresentable {
    let latex: String
    let displayMode: Bool
    let isDarkMode: Bool
    let allowsHorizontalScroll: Bool
    @Binding var dynamicHeight: CGFloat

    func makeCoordinator() -> MatrixLatexWebCoordinator {
        MatrixLatexWebCoordinator(dynamicHeight: $dynamicHeight)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.suppressesIncrementalRendering = true
        configuration.userContentController.add(context.coordinator, name: MatrixLatexWebCoordinator.heightMessageName)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = allowsHorizontalScroll
        webView.scrollView.showsHorizontalScrollIndicator = allowsHorizontalScroll
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.bounces = false
        webView.isUserInteractionEnabled = allowsHorizontalScroll
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.scrollView.isScrollEnabled = allowsHorizontalScroll
        webView.scrollView.showsHorizontalScrollIndicator = allowsHorizontalScroll
        webView.isUserInteractionEnabled = allowsHorizontalScroll
        context.coordinator.loadIfNeeded(
            latex: latex,
            displayMode: displayMode,
            isDarkMode: isDarkMode,
            into: webView
        )
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: MatrixLatexWebCoordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: MatrixLatexWebCoordinator.heightMessageName)
    }
}
#elseif os(macOS)
private struct MatrixLatexWebRepresentable: NSViewRepresentable {
    let latex: String
    let displayMode: Bool
    let isDarkMode: Bool
    let allowsHorizontalScroll: Bool
    @Binding var dynamicHeight: CGFloat

    func makeCoordinator() -> MatrixLatexWebCoordinator {
        MatrixLatexWebCoordinator(dynamicHeight: $dynamicHeight)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.suppressesIncrementalRendering = true
        configuration.userContentController.add(context.coordinator, name: MatrixLatexWebCoordinator.heightMessageName)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.loadIfNeeded(
            latex: latex,
            displayMode: displayMode,
            isDarkMode: isDarkMode,
            into: webView
        )
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator: MatrixLatexWebCoordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: MatrixLatexWebCoordinator.heightMessageName)
    }
}
#endif

private final class MatrixLatexWebCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    static let heightMessageName = "matrixHeight"

    @Binding private var dynamicHeight: CGFloat
    private var renderedSignature: String?

    init(dynamicHeight: Binding<CGFloat>) {
        self._dynamicHeight = dynamicHeight
    }

    func loadIfNeeded(latex: String, displayMode: Bool, isDarkMode: Bool, into webView: WKWebView) {
        let signature = "\(displayMode)|\(isDarkMode)|\(latex)"
        guard renderedSignature != signature else {
            return
        }

        renderedSignature = signature
        webView.loadHTMLString(
            MatrixLatexHTMLDocument.html(
                latex: latex,
                displayMode: displayMode,
                isDarkMode: isDarkMode
            ),
            baseURL: URL(string: "https://cdn.jsdelivr.net")
        )
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == Self.heightMessageName else {
            return
        }

        let postedHeight: CGFloat?
        if let value = message.body as? NSNumber {
            postedHeight = CGFloat(truncating: value)
        } else if let value = message.body as? Double {
            postedHeight = CGFloat(value)
        } else if let value = message.body as? Int {
            postedHeight = CGFloat(value)
        } else {
            postedHeight = nil
        }

        guard let postedHeight else {
            return
        }

        let clampedHeight = max(28, min(postedHeight, 1600))
        guard abs(clampedHeight - dynamicHeight) > 5 else {
            return
        }

        DispatchQueue.main.async {
            self.dynamicHeight = clampedHeight
        }
    }
}

private enum MatrixLatexHTMLDocument {
    private static let htmlCache = NSCache<NSString, NSString>()

    static func html(latex: String, displayMode: Bool, isDarkMode: Bool) -> String {
        let cacheKey = "\(displayMode)|\(isDarkMode)|\(latex)" as NSString
        if let cached = htmlCache.object(forKey: cacheKey) {
            return String(cached)
        }

        let escapedLatex = escapeJavaScriptString(latex)
        let renderedDisplayMode = displayMode ? "true" : "false"
        let foregroundColor = isDarkMode ? "#e5e7eb" : "#111827"
        let fallbackColor = isDarkMode ? "#d1d5db" : "#374151"

        let html = """
        <!doctype html>
        <html>
        <head>
          <meta charset=\"utf-8\" />
          <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />
          <link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css\" />
          <style>
            html, body {
              margin: 0;
              padding: 0;
              background: transparent;
              overflow: hidden;
              color: \(foregroundColor);
              font-family: \"Times New Roman\", Times, serif;
            }
            #math-root {
              display: inline-block;
              width: 100%;
              box-sizing: border-box;
              padding: 2px 0;
              font-size: 1.06rem;
            }
            .katex-display {
              margin: 0;
              overflow-x: auto;
              overflow-y: hidden;
              padding-bottom: 2px;
            }
            .katex {
              white-space: nowrap;
            }
            .fallback {
              font-family: Menlo, Monaco, Consolas, monospace;
              white-space: pre-wrap;
              color: \(fallbackColor);
              font-size: 0.9rem;
            }
          </style>
          <script src=\"https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js\"></script>
        </head>
        <body>
          <div id=\"math-root\"></div>
          <script>
            const latex = \"\(escapedLatex)\";
            const displayMode = \(renderedDisplayMode);

            const reportHeight = () => {
              const root = document.getElementById('math-root');
              if (!root) return;
              const height = Math.max(
                28,
                Math.ceil(root.getBoundingClientRect().height) + 6,
                Math.ceil(document.body.scrollHeight),
                Math.ceil(document.documentElement.scrollHeight)
              );

              if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.matrixHeight) {
                window.webkit.messageHandlers.matrixHeight.postMessage(height);
              }
            };

            const render = () => {
              const root = document.getElementById('math-root');
              if (!root) return;

              try {
                if (window.katex) {
                  katex.render(latex, root, {
                    displayMode,
                    throwOnError: false,
                    strict: 'ignore'
                  });
                } else {
                  root.classList.add('fallback');
                  root.textContent = latex;
                }
              } catch (_) {
                root.classList.add('fallback');
                root.textContent = latex;
              }

              requestAnimationFrame(reportHeight);
            };

            render();
          </script>
        </body>
        </html>
        """

        htmlCache.setObject(html as NSString, forKey: cacheKey)
        return html
    }

    private static func escapeJavaScriptString(_ text: String) -> String {
        text
            .replacingOccurrences(of: #"\"#, with: #"\\"#)
            .replacingOccurrences(of: "\"", with: #"\\\""#)
            .replacingOccurrences(of: "\n", with: #"\\n"#)
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\t", with: #"\\t"#)
    }
}

private extension View {
    @ViewBuilder
    func ifLet<T, Content: View>(
        _ value: T?,
        transform: (Self, T) -> Content
    ) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }
}
