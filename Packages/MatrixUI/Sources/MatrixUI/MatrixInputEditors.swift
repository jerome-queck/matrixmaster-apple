import SwiftUI
import MatrixDomain

public struct MatrixGridEditorView: View {
    @Binding public var matrix: MatrixDraftInput
    public var title: String
    public var showsRandomizeButton: Bool

    public init(
        matrix: Binding<MatrixDraftInput>,
        title: String = "Matrix",
        showsRandomizeButton: Bool = false
    ) {
        self._matrix = matrix
        self.title = title
        self.showsRandomizeButton = showsRandomizeButton
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
            HStack(spacing: MatrixUIDesignTokens.Spacing.regular) {
                MatrixInlineMathText(title, style: .sectionTitle)
                Spacer()
                MatrixInlineMathText(
                    "\(matrix.rows) x \(matrix.columns)",
                    style: .support,
                    color: .secondary
                )
            }

            if showsRandomizeButton {
                VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.compact) {
                    HStack(spacing: MatrixUIDesignTokens.Spacing.compact) {
                        editorButton("+ Row") { matrix.addRow() }
                        editorButton("- Row") { matrix.removeLastRow() }
                        editorButton("+ Col") { matrix.addColumn() }
                    }

                    HStack(spacing: MatrixUIDesignTokens.Spacing.compact) {
                        editorButton("- Col") { matrix.removeLastColumn() }
                        editorButton("Randomize") { randomizeMatrix() }
                    }
                }
            } else {
                HStack(spacing: MatrixUIDesignTokens.Spacing.compact) {
                    editorButton("+ Row") { matrix.addRow() }
                    editorButton("- Row") { matrix.removeLastRow() }
                    editorButton("+ Col") { matrix.addColumn() }
                    editorButton("- Col") { matrix.removeLastColumn() }
                }
            }

            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.compact) {
                    ForEach(0..<matrix.rows, id: \.self) { rowIndex in
                        HStack(spacing: MatrixUIDesignTokens.Spacing.compact) {
                            ForEach(0..<matrix.columns, id: \.self) { columnIndex in
                                TextField(
                                    "",
                                    text: bindingForCell(row: rowIndex, column: columnIndex)
                                )
                                .textFieldStyle(.roundedBorder)
                                .frame(minWidth: 72, maxWidth: 92)
                                .accessibilityIdentifier("matrix-cell-\(rowIndex)-\(columnIndex)")
                                .accessibilityLabel("Matrix entry row \(rowIndex + 1) column \(columnIndex + 1)")
                            }
                        }
                    }
                }
                .padding(.trailing, MatrixUIDesignTokens.Spacing.compact)
            }
        }
        .padding(MatrixUIDesignTokens.Spacing.regular)
        .background(
            RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.card)
                .fill(MatrixUIDesignTokens.ColorPalette.cardBackground)
        )
    }

    private func bindingForCell(row: Int, column: Int) -> Binding<String> {
        Binding(
            get: {
                matrix.value(atRow: row, column: column)
            },
            set: { newValue in
                matrix.setValue(newValue, row: row, column: column)
            }
        )
    }

    private func editorButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .buttonStyle(.bordered)
            .lineLimit(1)
            .accessibilityIdentifier("matrix-editor-action-\(label)")
    }

    private func randomizeMatrix() {
        for row in 0..<matrix.rows {
            for column in 0..<matrix.columns {
                matrix.setValue("\(Int.random(in: -9...9))", row: row, column: column)
            }
        }
    }
}

public struct AugmentedSystemEditorView: View {
    @Binding public var matrix: MatrixDraftInput
    public var title: String
    @State private var isHomogeneous: Bool

    public init(
        matrix: Binding<MatrixDraftInput>,
        title: String = "Solve System Input",
        isHomogeneous: Bool = false
    ) {
        self._matrix = matrix
        self.title = title
        self._isHomogeneous = State(initialValue: isHomogeneous)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
            HStack(spacing: MatrixUIDesignTokens.Spacing.regular) {
                MatrixInlineMathText(title, style: .sectionTitle)
                Spacer()
                MatrixInlineMathText(
                    "\(matrix.rows) x \(coefficientColumnCount)",
                    style: .support,
                    color: .secondary
                )
                    .accessibilityLabel("Coefficient matrix dimensions \(matrix.rows) by \(coefficientColumnCount)")
            }

            Toggle(isOn: $isHomogeneous) {
                MatrixInlineMathText("Homogeneous system (A x = 0)", style: .body)
            }
                .toggleStyle(.switch)
                .onChange(of: isHomogeneous) { _, newValue in
                    if newValue {
                        zeroSolutionVector()
                    }
                }
                .accessibilityIdentifier("solve-homogeneous-toggle")

            VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.compact) {
                HStack(spacing: MatrixUIDesignTokens.Spacing.compact) {
                    editorButton("+ Eq") {
                        matrix.addRow()
                        if isHomogeneous {
                            zeroSolutionVector()
                        }
                    }
                    editorButton("- Eq") { matrix.removeLastRow() }
                    editorButton("+ Var") { addVariableColumn() }
                }

                HStack(spacing: MatrixUIDesignTokens.Spacing.compact) {
                    editorButton("- Var") { removeVariableColumn() }
                    editorButton("Randomize") { randomizeMatrix() }
                }
            }

            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.compact) {
                    ForEach(0..<matrix.rows, id: \.self) { rowIndex in
                        HStack(spacing: MatrixUIDesignTokens.Spacing.compact) {
                            ForEach(0..<coefficientColumnCount, id: \.self) { columnIndex in
                                TextField(
                                    "",
                                    text: bindingForCoefficientCell(row: rowIndex, column: columnIndex)
                                )
                                .textFieldStyle(.roundedBorder)
                                .frame(minWidth: 72, maxWidth: 92)
                                .accessibilityIdentifier("matrix-cell-\(rowIndex)-\(columnIndex)")
                                    .accessibilityLabel("Matrix entry row \(rowIndex + 1) column \(columnIndex + 1)")
                            }

                            Rectangle()
                                .fill(Color.secondary.opacity(0.45))
                                .frame(width: 2, height: 36)
                                .accessibilityHidden(true)

                            TextField(
                                "",
                                text: bindingForSolutionCell(row: rowIndex)
                            )
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 72, maxWidth: 92)
                            .background(
                                RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.control)
                                    .fill(MatrixUIDesignTokens.ColorPalette.controlBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.control)
                                    .stroke(Color.secondary.opacity(0.45), lineWidth: 1)
                            )
                            .disabled(isHomogeneous)
                            .accessibilityIdentifier("solution-vector-entry-\(rowIndex)")
                            .accessibilityLabel("Solution vector entry row \(rowIndex + 1)")
                        }
                    }
                }
                .padding(.trailing, MatrixUIDesignTokens.Spacing.compact)
            }
        }
        .padding(MatrixUIDesignTokens.Spacing.regular)
        .background(
            RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.card)
                .fill(MatrixUIDesignTokens.ColorPalette.cardBackground)
        )
        .onAppear {
            ensureAugmentedSystemShape()
            if isHomogeneous {
                zeroSolutionVector()
            }
        }
    }

    private var coefficientColumnCount: Int {
        max(1, matrix.columns - 1)
    }

    private var solutionColumnIndex: Int {
        max(1, matrix.columns) - 1
    }

    private func ensureAugmentedSystemShape() {
        while matrix.columns < 2 {
            matrix.addColumn()
        }
    }

    private func addVariableColumn() {
        ensureAugmentedSystemShape()
        let oldSolutionIndex = solutionColumnIndex
        matrix.addColumn(fillWith: "0")

        for row in 0..<matrix.rows {
            let oldSolutionValue = matrix.value(atRow: row, column: oldSolutionIndex)
            matrix.setValue("0", row: row, column: oldSolutionIndex)
            matrix.setValue(oldSolutionValue, row: row, column: matrix.columns - 1)
        }
    }

    private func removeVariableColumn() {
        guard matrix.columns > 2 else {
            return
        }

        let currentSolutionIndex = solutionColumnIndex
        let removedVariableIndex = currentSolutionIndex - 1

        for row in 0..<matrix.rows {
            let solutionValue = matrix.value(atRow: row, column: currentSolutionIndex)
            let removedVariableValue = matrix.value(atRow: row, column: removedVariableIndex)
            matrix.setValue(solutionValue, row: row, column: removedVariableIndex)
            matrix.setValue(removedVariableValue, row: row, column: currentSolutionIndex)
        }

        matrix.removeLastColumn()
    }

    private func zeroSolutionVector() {
        ensureAugmentedSystemShape()
        for row in 0..<matrix.rows {
            matrix.setValue("0", row: row, column: solutionColumnIndex)
        }
    }

    private func randomizeMatrix() {
        ensureAugmentedSystemShape()

        for row in 0..<matrix.rows {
            for column in 0..<coefficientColumnCount {
                matrix.setValue("\(Int.random(in: -9...9))", row: row, column: column)
            }

            let solutionValue = isHomogeneous ? "0" : "\(Int.random(in: -9...9))"
            matrix.setValue(solutionValue, row: row, column: solutionColumnIndex)
        }
    }

    private func bindingForCoefficientCell(row: Int, column: Int) -> Binding<String> {
        Binding(
            get: {
                matrix.value(atRow: row, column: column)
            },
            set: { newValue in
                matrix.setValue(newValue, row: row, column: column)
            }
        )
    }

    private func bindingForSolutionCell(row: Int) -> Binding<String> {
        Binding(
            get: {
                matrix.value(atRow: row, column: solutionColumnIndex)
            },
            set: { newValue in
                matrix.setValue(newValue, row: row, column: solutionColumnIndex)
            }
        )
    }

    private func editorButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .buttonStyle(.bordered)
            .lineLimit(1)
            .accessibilityIdentifier("solve-editor-action-\(label)")
    }
}

public struct VectorEditorView: View {
    @Binding public var vector: VectorDraftInput
    public var title: String
    public var showsNameField: Bool

    public init(
        vector: Binding<VectorDraftInput>,
        title: String = "Vector",
        showsNameField: Bool = true
    ) {
        self._vector = vector
        self.title = title
        self.showsNameField = showsNameField
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
            HStack(spacing: MatrixUIDesignTokens.Spacing.regular) {
                MatrixInlineMathText(title, style: .sectionTitle)
                Spacer()
                MatrixInlineMathText(
                    "n = \(vector.dimension)",
                    style: .support,
                    color: .secondary
                )
            }

            if showsNameField {
                MatrixMathPreviewTextField(
                    title: "Vector name",
                    text: $vector.name,
                    accessibilityIdentifier: "vector-name-field"
                )
                .accessibilityLabel("Vector name")
            }

            HStack(spacing: MatrixUIDesignTokens.Spacing.compact) {
                editorButton("+ Entry") { vector.appendEntry() }
                editorButton("- Entry") { vector.removeLastEntry() }
                editorButton("Randomize") { randomizeVector() }
            }

            ScrollView(.horizontal) {
                HStack(spacing: MatrixUIDesignTokens.Spacing.compact) {
                    ForEach(0..<vector.entries.count, id: \.self) { entryIndex in
                        TextField(
                            "",
                            text: bindingForEntry(index: entryIndex)
                        )
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 72, maxWidth: 92)
                        .accessibilityIdentifier("vector-entry-\(entryIndex)")
                        .accessibilityLabel("Vector entry \(entryIndex + 1)")
                    }
                }
            }
        }
        .padding(MatrixUIDesignTokens.Spacing.regular)
        .background(
            RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.card)
                .fill(MatrixUIDesignTokens.ColorPalette.cardBackground)
        )
    }

    private func bindingForEntry(index: Int) -> Binding<String> {
        Binding(
            get: {
                vector.entries[index]
            },
            set: { newValue in
                vector.setValue(newValue, at: index)
            }
        )
    }

    private func editorButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .buttonStyle(.bordered)
            .accessibilityIdentifier("vector-editor-action-\(label)")
    }

    private func randomizeVector() {
        for index in vector.entries.indices {
            vector.setValue("\(Int.random(in: -9...9))", at: index)
        }
    }
}

public struct OperateConfigurationView: View {
    @Binding public var operateKind: MatrixOperateKind
    @Binding public var scalarToken: String
    @Binding public var exponent: Int
    @Binding public var expression: String

    public init(
        operateKind: Binding<MatrixOperateKind>,
        scalarToken: Binding<String>,
        exponent: Binding<Int>,
        expression: Binding<String>
    ) {
        self._operateKind = operateKind
        self._scalarToken = scalarToken
        self._exponent = exponent
        self._expression = expression
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
            MatrixInlineMathText("Operate Configuration", style: .sectionTitle)

            Picker("Operation", selection: $operateKind) {
                ForEach(MatrixOperateKind.allCases, id: \.self) { kind in
                    MatrixInlineMathText(
                        kind.title,
                        style: .body,
                        accessibilityLabel: kind.title
                    )
                    .tag(kind)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("operate-kind-picker")

            if operateKind == .scalarVectorMultiply {
                TextField("Scalar s", text: $scalarToken)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("operate-scalar-field")
            }

            if operateKind == .power {
                Stepper(value: $exponent, in: 1...12) {
                    MatrixInlineMathText("Exponent: \(exponent)", style: .body)
                }
                .accessibilityIdentifier("operate-exponent-stepper")
            }

            if operateKind == .expression {
                TextField(
                    "",
                    text: $expression,
                    prompt: Text(
                        MatrixInlineMathFormatter.attributed(
                            "Expression (e.g. A*B, A*v, 2*v, transpose(A), trace(A), A³)",
                            style: .body
                        )
                    )
                    .foregroundStyle(.secondary)
                )
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("operate-expression-field")
            }
        }
        .padding(MatrixUIDesignTokens.Spacing.regular)
        .background(
            RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.card)
                .fill(MatrixUIDesignTokens.ColorPalette.cardBackground)
        )
    }
}

public struct AnalyzeConfigurationView: View {
    @Binding public var analyzeKind: MatrixAnalyzeKind
    @Binding public var matrixPropertiesSelection: MatrixAnalyzeMatrixPropertiesSelection
    @Binding public var linearMapDefinitionKind: MatrixLinearMapDefinitionKind

    public init(
        analyzeKind: Binding<MatrixAnalyzeKind>,
        matrixPropertiesSelection: Binding<MatrixAnalyzeMatrixPropertiesSelection> = .constant(.all),
        linearMapDefinitionKind: Binding<MatrixLinearMapDefinitionKind>
    ) {
        self._analyzeKind = analyzeKind
        self._matrixPropertiesSelection = matrixPropertiesSelection
        self._linearMapDefinitionKind = linearMapDefinitionKind
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
            MatrixInlineMathText("Analyze Workflow", style: .sectionTitle)

            Picker("Workflow", selection: $analyzeKind) {
                ForEach(MatrixAnalyzeKind.allCases, id: \.self) { kind in
                    MatrixInlineMathText(
                        kind.title,
                        style: .body,
                        accessibilityLabel: kind.title
                    )
                    .tag(kind)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("analyze-kind-picker")

            if analyzeKind == .matrixProperties {
                VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.compact) {
                    MatrixInlineMathText("Compute Outputs", style: .support, color: .secondary)

                    Toggle("Rank + nullity", isOn: $matrixPropertiesSelection.includeRankNullity)
                        .matrixOutputToggleStyle()
                        .accessibilityIdentifier("analyze-option-rank-nullity")
                    Toggle("Column space basis", isOn: $matrixPropertiesSelection.includeColumnSpaceBasis)
                        .matrixOutputToggleStyle()
                        .accessibilityIdentifier("analyze-option-column-space")
                    Toggle("Row space basis", isOn: $matrixPropertiesSelection.includeRowSpaceBasis)
                        .matrixOutputToggleStyle()
                        .accessibilityIdentifier("analyze-option-row-space")
                    Toggle("Null space basis", isOn: $matrixPropertiesSelection.includeNullSpaceBasis)
                        .matrixOutputToggleStyle()
                        .accessibilityIdentifier("analyze-option-null-space")
                    Toggle("Determinant", isOn: $matrixPropertiesSelection.includeDeterminant)
                        .matrixOutputToggleStyle()
                        .accessibilityIdentifier("analyze-option-determinant")
                    Toggle("Trace", isOn: $matrixPropertiesSelection.includeTrace)
                        .matrixOutputToggleStyle()
                        .accessibilityIdentifier("analyze-option-trace")
                    Toggle("Inverse", isOn: $matrixPropertiesSelection.includeInverse)
                        .matrixOutputToggleStyle()
                        .accessibilityIdentifier("analyze-option-inverse")
                    Toggle("REF / RREF panels", isOn: $matrixPropertiesSelection.includeRowReductionPanels)
                        .matrixOutputToggleStyle()
                        .accessibilityIdentifier("analyze-option-rref-panels")
                }
            }

            if analyzeKind == .linearMaps {
                Picker("Linear map definition", selection: $linearMapDefinitionKind) {
                    ForEach(MatrixLinearMapDefinitionKind.allCases, id: \.self) { kind in
                        MatrixInlineMathText(
                            kind.title,
                            style: .body,
                            accessibilityLabel: kind.title
                        )
                        .tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("linear-map-definition-picker")
            }
        }
        .padding(MatrixUIDesignTokens.Spacing.regular)
        .background(
            RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.card)
                .fill(MatrixUIDesignTokens.ColorPalette.cardBackground)
        )
    }
}

public struct SpacesConfigurationView: View {
    @Binding public var spacesKind: MatrixSpacesKind
    @Binding public var spacesPresetKind: MatrixSpacesPresetKind
    @Binding public var spacesOutputSelection: MatrixSpacesOutputSelection
    @Binding public var polynomialDegree: Int
    @Binding public var matrixSpaceRows: Int
    @Binding public var matrixSpaceColumns: Int
    public var showsSecondaryApplyActions: Bool
    public var onApplyPrimaryPreset: (() -> Void)?
    public var onApplySecondaryPreset: (() -> Void)?
    public var onApplyBothPresets: (() -> Void)?

    public init(
        spacesKind: Binding<MatrixSpacesKind>,
        spacesPresetKind: Binding<MatrixSpacesPresetKind> = .constant(.none),
        spacesOutputSelection: Binding<MatrixSpacesOutputSelection> = .constant(.all),
        polynomialDegree: Binding<Int> = .constant(2),
        matrixSpaceRows: Binding<Int> = .constant(2),
        matrixSpaceColumns: Binding<Int> = .constant(2),
        showsSecondaryApplyActions: Bool = false,
        onApplyPrimaryPreset: (() -> Void)? = nil,
        onApplySecondaryPreset: (() -> Void)? = nil,
        onApplyBothPresets: (() -> Void)? = nil
    ) {
        self._spacesKind = spacesKind
        self._spacesPresetKind = spacesPresetKind
        self._spacesOutputSelection = spacesOutputSelection
        self._polynomialDegree = polynomialDegree
        self._matrixSpaceRows = matrixSpaceRows
        self._matrixSpaceColumns = matrixSpaceColumns
        self.showsSecondaryApplyActions = showsSecondaryApplyActions
        self.onApplyPrimaryPreset = onApplyPrimaryPreset
        self.onApplySecondaryPreset = onApplySecondaryPreset
        self.onApplyBothPresets = onApplyBothPresets
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
            MatrixInlineMathText("Spaces Workflow", style: .sectionTitle)

            Picker("Workflow", selection: $spacesKind) {
                ForEach(MatrixSpacesKind.allCases, id: \.self) { kind in
                    MatrixInlineMathText(
                        kind.title,
                        style: .body,
                        accessibilityLabel: kind.title
                    )
                    .tag(kind)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("spaces-kind-picker")

            Picker("Abstract-space preset", selection: $spacesPresetKind) {
                ForEach(MatrixSpacesPresetKind.allCases, id: \.self) { kind in
                    MatrixInlineMathText(
                        kind.title,
                        style: .body,
                        accessibilityLabel: kind.title
                    )
                    .tag(kind)
                    .accessibilityIdentifier("spaces-preset-option-\(kind.rawValue)")
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("spaces-preset-picker")

            switch spacesPresetKind {
            case .none:
                EmptyView()
            case .polynomialSpace:
                Stepper(value: $polynomialDegree, in: 0...8) {
                    MatrixInlineMathText("Polynomial degree n: \(polynomialDegree) (P_n)", style: .body)
                }
                .accessibilityIdentifier("spaces-polynomial-degree-stepper")
            case .matrixSpace:
                Stepper(value: $matrixSpaceRows, in: 1...5) {
                    MatrixInlineMathText("Matrix-space rows m: \(matrixSpaceRows)", style: .body)
                }
                .accessibilityIdentifier("spaces-matrix-rows-stepper")

                Stepper(value: $matrixSpaceColumns, in: 1...5) {
                    MatrixInlineMathText("Matrix-space columns n: \(matrixSpaceColumns)", style: .body)
                }
                .accessibilityIdentifier("spaces-matrix-columns-stepper")
            }

            VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.compact) {
                MatrixInlineMathText("Compute Outputs", style: .support, color: .secondary)

                Toggle("Conclusion", isOn: $spacesOutputSelection.includeConclusion)
                    .matrixOutputToggleStyle()
                    .accessibilityIdentifier("spaces-output-conclusion")
                Toggle("Math objects", isOn: $spacesOutputSelection.includeMathObjects)
                    .matrixOutputToggleStyle()
                    .accessibilityIdentifier("spaces-output-objects")
                Toggle("Diagnostics", isOn: $spacesOutputSelection.includeDiagnostics)
                    .matrixOutputToggleStyle()
                    .accessibilityIdentifier("spaces-output-diagnostics")
                Toggle("Steps", isOn: $spacesOutputSelection.includeSteps)
                    .matrixOutputToggleStyle()
                    .accessibilityIdentifier("spaces-output-steps")
            }

            if spacesPresetKind != .none {
                HStack(spacing: MatrixUIDesignTokens.Spacing.compact) {
                    if let onApplyPrimaryPreset {
                        editorButton("Apply Preset to U", action: onApplyPrimaryPreset)
                            .accessibilityIdentifier("spaces-apply-preset-u")
                    }
                    if showsSecondaryApplyActions, let onApplySecondaryPreset {
                        editorButton("Apply Preset to W", action: onApplySecondaryPreset)
                            .accessibilityIdentifier("spaces-apply-preset-w")
                    }
                    if showsSecondaryApplyActions, let onApplyBothPresets {
                        editorButton("Apply Preset to U and W", action: onApplyBothPresets)
                            .accessibilityIdentifier("spaces-apply-preset-both")
                    }
                }
            }
        }
        .padding(MatrixUIDesignTokens.Spacing.regular)
        .background(
            RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.card)
                .fill(MatrixUIDesignTokens.ColorPalette.cardBackground)
        )
    }

    private func editorButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .buttonStyle(.bordered)
            .lineLimit(1)
    }
}

public struct LibraryCatalogView: View {
    public var vectors: [MatrixLibraryVectorItem]
    public var history: [MatrixLibraryHistoryEntry]
    public var exportPath: String
    public var onSaveDraft: () -> Void
    public var onLoadVector: (MatrixLibraryVectorItem) -> Void
    public var onDeleteVector: (MatrixLibraryVectorItem) -> Void
    public var onExportCatalog: () -> Void

    public init(
        vectors: [MatrixLibraryVectorItem],
        history: [MatrixLibraryHistoryEntry],
        exportPath: String,
        onSaveDraft: @escaping () -> Void,
        onLoadVector: @escaping (MatrixLibraryVectorItem) -> Void,
        onDeleteVector: @escaping (MatrixLibraryVectorItem) -> Void,
        onExportCatalog: @escaping () -> Void
    ) {
        self.vectors = vectors
        self.history = history
        self.exportPath = exportPath
        self.onSaveDraft = onSaveDraft
        self.onLoadVector = onLoadVector
        self.onDeleteVector = onDeleteVector
        self.onExportCatalog = onExportCatalog
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
            Text("Library Catalog")
                .font(MatrixUIDesignTokens.Typography.sectionTitle)

            HStack(spacing: MatrixUIDesignTokens.Spacing.compact) {
                Button("Save Draft", action: onSaveDraft)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("library-save-draft-button")

                Button("Export Catalog", action: onExportCatalog)
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("library-export-button")
            }

            Text("Export path: \(exportPath)")
                .font(MatrixUIDesignTokens.Typography.supportText)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .accessibilityIdentifier("library-export-path")

            Divider()

            Text("Saved Vectors (\(vectors.count))")
                .font(.headline)

            if vectors.isEmpty {
                Text("No saved vectors yet.")
                    .font(MatrixUIDesignTokens.Typography.supportText)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(vectors.prefix(8)) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            MatrixInlineMathText(item.name, style: .bodyEmphasis)
                            Text(item.entries.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button("Load") {
                            onLoadVector(item)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("library-load-\(item.id.uuidString)")

                        Button("Delete") {
                            onDeleteVector(item)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("library-delete-\(item.id.uuidString)")
                    }
                    .padding(.vertical, 2)
                }
            }

            Divider()

            Text("Recent History")
                .font(.headline)

            if history.isEmpty {
                Text("No history yet.")
                    .font(MatrixUIDesignTokens.Typography.supportText)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(history.prefix(6)) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        MatrixInlineMathText(entry.title, style: .body)
                        MatrixInlineMathText(
                            entry.detail,
                            style: .caption,
                            color: .secondary
                        )
                    }
                }
            }
        }
        .padding(MatrixUIDesignTokens.Spacing.regular)
        .background(
            RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.card)
                .fill(MatrixUIDesignTokens.ColorPalette.cardBackground)
        )
    }
}

public struct BasisEditorView: View {
    @Binding public var basis: BasisDraftInput
    public var title: String
    public var showsDimensionControls: Bool

    public init(
        basis: Binding<BasisDraftInput>,
        title: String = "Basis",
        showsDimensionControls: Bool = true
    ) {
        self._basis = basis
        self.title = title
        self.showsDimensionControls = showsDimensionControls
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
            HStack(spacing: MatrixUIDesignTokens.Spacing.regular) {
                MatrixInlineMathText(title, style: .sectionTitle)
                Spacer()
                MatrixInlineMathText(
                    "\(basis.vectorCount) vectors in R\(matrixUISuperscriptNumber(basis.dimension))",
                    style: .support,
                    color: .secondary
                )
            }

            MatrixMathPreviewTextField(
                title: "Basis name",
                text: $basis.name,
                accessibilityIdentifier: "basis-name-field"
            )
            .accessibilityLabel("Basis name")

            HStack(spacing: MatrixUIDesignTokens.Spacing.compact) {
                editorButton("+ Vector") { basis.addVector() }
                editorButton("- Vector") { basis.removeLastVector() }
                if showsDimensionControls {
                    editorButton("+ Dim") { basis.increaseDimension() }
                    editorButton("- Dim") { basis.decreaseDimension() }
                }
            }

            VStack(spacing: MatrixUIDesignTokens.Spacing.regular) {
                ForEach(0..<basis.vectors.count, id: \.self) { vectorIndex in
                    VectorEditorView(
                        vector: bindingForVector(index: vectorIndex),
                        title: "Vector \(vectorIndex + 1)",
                        showsNameField: true
                    )
                }
            }
        }
        .padding(MatrixUIDesignTokens.Spacing.regular)
        .background(
            RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.card)
                .fill(MatrixUIDesignTokens.ColorPalette.cardBackground)
        )
    }

    private func bindingForVector(index: Int) -> Binding<VectorDraftInput> {
        Binding(
            get: {
                basis.vectors[index]
            },
            set: { newValue in
                basis.updateVector(newValue, at: index)
            }
        )
    }

    private func editorButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .buttonStyle(.bordered)
            .accessibilityIdentifier("basis-editor-action-\(label)")
    }
}

public struct PolynomialSpaceElementsEditorView: View {
    @Binding public var basis: BasisDraftInput
    @Binding public var polynomialDegree: Int
    public var title: String

    public init(
        basis: Binding<BasisDraftInput>,
        polynomialDegree: Binding<Int>,
        title: String = "Polynomial Elements"
    ) {
        self._basis = basis
        self._polynomialDegree = polynomialDegree
        self.title = title
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
            HStack(spacing: MatrixUIDesignTokens.Spacing.regular) {
                MatrixInlineMathText(title, style: .sectionTitle)
                Spacer()
                MatrixInlineMathText(
                    "\(basis.vectorCount) element(s) in P\(matrixUISubscriptNumber(max(0, polynomialDegree)))(F)",
                    style: .support,
                    color: .secondary
                )
            }

            HStack(spacing: MatrixUIDesignTokens.Spacing.compact) {
                editorButton("+ Element") {
                    addPolynomialElement()
                }
                editorButton("- Element") {
                    basis.removeLastVector()
                }
            }

            VStack(spacing: MatrixUIDesignTokens.Spacing.regular) {
                ForEach(0..<basis.vectors.count, id: \.self) { vectorIndex in
                    VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.compact) {
                        MatrixMathPreviewTextField(
                            title: "Element name",
                            text: bindingForVectorName(index: vectorIndex),
                            accessibilityIdentifier: "polynomial-element-name-\(vectorIndex)"
                        )

                        ScrollView(.horizontal) {
                            HStack(spacing: MatrixUIDesignTokens.Spacing.compact) {
                                ForEach(0..<max(1, polynomialDegree + 1), id: \.self) { degreeIndex in
                                    VStack(alignment: .leading, spacing: 2) {
                                        MatrixInlineMathText(
                                            coefficientLabel(for: degreeIndex),
                                            style: .caption,
                                            color: .secondary
                                        )
                                        TextField(
                                            "",
                                            text: bindingForCoefficient(
                                                vectorIndex: vectorIndex,
                                                coefficientIndex: degreeIndex
                                            )
                                        )
                                        .textFieldStyle(.roundedBorder)
                                        .frame(minWidth: 72, maxWidth: 92)
                                        .accessibilityIdentifier("polynomial-element-\(vectorIndex)-coeff-\(degreeIndex)")
                                    }
                                }
                            }
                        }
                    }
                    .padding(MatrixUIDesignTokens.Spacing.regular)
                    .background(
                        RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.control)
                            .fill(MatrixUIDesignTokens.ColorPalette.controlBackground)
                    )
                }
            }
        }
        .padding(MatrixUIDesignTokens.Spacing.regular)
        .background(
            RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.card)
                .fill(MatrixUIDesignTokens.ColorPalette.cardBackground)
        )
        .onAppear {
            ensurePolynomialShape()
        }
        .onChange(of: polynomialDegree) { _, _ in
            ensurePolynomialShape()
        }
    }

    private func coefficientLabel(for degree: Int) -> String {
        switch degree {
        case 0:
            return "1"
        case 1:
            return "x"
        default:
            return "x\(matrixUISuperscriptNumber(degree))"
        }
    }

    private func addPolynomialElement() {
        let dimension = max(1, polynomialDegree + 1)
        basis.addVector(named: "p\(basis.vectorCount + 1)")
        basis.alignVectors(to: dimension)
    }

    private func ensurePolynomialShape() {
        basis.alignVectors(to: max(1, polynomialDegree + 1))
    }

    private func bindingForVectorName(index: Int) -> Binding<String> {
        Binding(
            get: {
                guard index < basis.vectors.count else {
                    return ""
                }
                return basis.vectors[index].name
            },
            set: { newValue in
                guard index < basis.vectors.count else {
                    return
                }
                var vector = basis.vectors[index]
                vector.name = newValue
                basis.updateVector(vector, at: index)
            }
        )
    }

    private func bindingForCoefficient(vectorIndex: Int, coefficientIndex: Int) -> Binding<String> {
        Binding(
            get: {
                guard vectorIndex < basis.vectors.count else {
                    return ""
                }

                let vector = basis.vectors[vectorIndex]
                guard coefficientIndex < vector.entries.count else {
                    return ""
                }
                return vector.entries[coefficientIndex]
            },
            set: { newValue in
                guard vectorIndex < basis.vectors.count else {
                    return
                }

                var vector = basis.vectors[vectorIndex]
                vector.resize(to: max(1, polynomialDegree + 1))
                vector.setValue(newValue, at: coefficientIndex)
                basis.updateVector(vector, at: vectorIndex)
            }
        )
    }

    private func editorButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .buttonStyle(.bordered)
            .accessibilityIdentifier("polynomial-editor-action-\(label)")
    }
}

public struct MatrixSpaceElementsEditorView: View {
    @Binding public var basis: BasisDraftInput
    @Binding public var rowCount: Int
    @Binding public var columnCount: Int
    public var title: String

    public init(
        basis: Binding<BasisDraftInput>,
        rowCount: Binding<Int>,
        columnCount: Binding<Int>,
        title: String = "Matrix-Space Elements"
    ) {
        self._basis = basis
        self._rowCount = rowCount
        self._columnCount = columnCount
        self.title = title
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
            HStack(spacing: MatrixUIDesignTokens.Spacing.regular) {
                MatrixInlineMathText(title, style: .sectionTitle)
                Spacer()
                MatrixInlineMathText(
                    "\(basis.vectorCount) element(s) in M(\(safeRows)×\(safeColumns))(F)",
                    style: .support,
                    color: .secondary
                )
            }

            HStack(spacing: MatrixUIDesignTokens.Spacing.compact) {
                editorButton("+ Element") {
                    addMatrixElement()
                }
                editorButton("- Element") {
                    basis.removeLastVector()
                }
            }

            VStack(spacing: MatrixUIDesignTokens.Spacing.regular) {
                ForEach(0..<basis.vectors.count, id: \.self) { vectorIndex in
                    VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.compact) {
                        MatrixMathPreviewTextField(
                            title: "Element name",
                            text: bindingForVectorName(index: vectorIndex),
                            accessibilityIdentifier: "matrix-space-element-name-\(vectorIndex)"
                        )

                        ScrollView([.horizontal, .vertical]) {
                            VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.compact) {
                                ForEach(0..<safeRows, id: \.self) { row in
                                    HStack(spacing: MatrixUIDesignTokens.Spacing.compact) {
                                        ForEach(0..<safeColumns, id: \.self) { column in
                                            TextField(
                                                "",
                                                text: bindingForMatrixCell(
                                                    vectorIndex: vectorIndex,
                                                    row: row,
                                                    column: column
                                                )
                                            )
                                            .textFieldStyle(.roundedBorder)
                                            .frame(minWidth: 72, maxWidth: 92)
                                            .accessibilityIdentifier("matrix-space-element-\(vectorIndex)-cell-\(row)-\(column)")
                                        }
                                    }
                                }
                            }
                            .padding(.trailing, MatrixUIDesignTokens.Spacing.compact)
                        }
                    }
                    .padding(MatrixUIDesignTokens.Spacing.regular)
                    .background(
                        RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.control)
                            .fill(MatrixUIDesignTokens.ColorPalette.controlBackground)
                    )
                }
            }
        }
        .padding(MatrixUIDesignTokens.Spacing.regular)
        .background(
            RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.card)
                .fill(MatrixUIDesignTokens.ColorPalette.cardBackground)
        )
        .onAppear {
            ensureMatrixSpaceShape()
        }
        .onChange(of: rowCount) { _, _ in
            ensureMatrixSpaceShape()
        }
        .onChange(of: columnCount) { _, _ in
            ensureMatrixSpaceShape()
        }
    }

    private var safeRows: Int {
        max(1, rowCount)
    }

    private var safeColumns: Int {
        max(1, columnCount)
    }

    private var matrixDimension: Int {
        safeRows * safeColumns
    }

    private func addMatrixElement() {
        basis.addVector(named: "M\(basis.vectorCount + 1)")
        basis.alignVectors(to: matrixDimension)
    }

    private func ensureMatrixSpaceShape() {
        basis.alignVectors(to: matrixDimension)
    }

    private func flattenIndex(row: Int, column: Int) -> Int {
        (row * safeColumns) + column
    }

    private func bindingForVectorName(index: Int) -> Binding<String> {
        Binding(
            get: {
                guard index < basis.vectors.count else {
                    return ""
                }
                return basis.vectors[index].name
            },
            set: { newValue in
                guard index < basis.vectors.count else {
                    return
                }
                var vector = basis.vectors[index]
                vector.name = newValue
                basis.updateVector(vector, at: index)
            }
        )
    }

    private func bindingForMatrixCell(vectorIndex: Int, row: Int, column: Int) -> Binding<String> {
        Binding(
            get: {
                guard vectorIndex < basis.vectors.count else {
                    return ""
                }

                let index = flattenIndex(row: row, column: column)
                let vector = basis.vectors[vectorIndex]
                guard index < vector.entries.count else {
                    return ""
                }
                return vector.entries[index]
            },
            set: { newValue in
                guard vectorIndex < basis.vectors.count else {
                    return
                }

                let index = flattenIndex(row: row, column: column)
                var vector = basis.vectors[vectorIndex]
                vector.resize(to: matrixDimension)
                vector.setValue(newValue, at: index)
                basis.updateVector(vector, at: vectorIndex)
            }
        )
    }

    private func editorButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .buttonStyle(.bordered)
            .accessibilityIdentifier("matrix-space-editor-action-\(label)")
    }
}

private struct MatrixMathPreviewTextField: View {
    let title: String
    @Binding var text: String
    let accessibilityIdentifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(title, text: $text)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier(accessibilityIdentifier)

            if showsMathPreview {
                MatrixInlineMathText(text, style: .body, color: .secondary)
                    .padding(.leading, 2)
            }
        }
    }

    private var showsMathPreview: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return false
        }
        return trimmed.contains("^")
            || trimmed.contains("_")
            || trimmed.contains("\\")
            || trimmed.contains("{")
            || trimmed.contains("}")
    }
}

public struct MatrixValidationMessageView: View {
    public var message: String

    public init(message: String) {
        self.message = message
    }

    public var body: some View {
        MatrixInlineMathText(
            message,
            style: .support,
            color: .red
        )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MatrixUIDesignTokens.Spacing.regular)
            .background(
                RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.control)
                    .fill(MatrixUIDesignTokens.ColorPalette.controlBackground)
            )
            .accessibilityIdentifier("matrix-validation-message")
    }
}

private extension Toggle where Label == Text {
    @ViewBuilder
    func matrixOutputToggleStyle() -> some View {
#if os(macOS)
        self.toggleStyle(.checkbox)
#else
        self
#endif
    }
}

private let matrixUISuperscriptDigits: [Character: Character] = [
    "-": "⁻",
    "0": "⁰",
    "1": "¹",
    "2": "²",
    "3": "³",
    "4": "⁴",
    "5": "⁵",
    "6": "⁶",
    "7": "⁷",
    "8": "⁸",
    "9": "⁹"
]

private let matrixUISubscriptDigits: [Character: Character] = [
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

private func matrixUISuperscriptNumber(_ number: Int) -> String {
    String(String(number).map { matrixUISuperscriptDigits[$0] ?? $0 })
}

private func matrixUISubscriptNumber(_ number: Int) -> String {
    String(String(number).map { matrixUISubscriptDigits[$0] ?? $0 })
}
