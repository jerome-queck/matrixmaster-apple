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
                Text(title)
                    .font(MatrixUIDesignTokens.Typography.sectionTitle)
                Spacer()
                Text("\(matrix.rows) x \(matrix.columns)")
                    .font(MatrixUIDesignTokens.Typography.supportText)
                    .foregroundStyle(.secondary)
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
                Text(title)
                    .font(MatrixUIDesignTokens.Typography.sectionTitle)
                Spacer()
                Text("\(matrix.rows) x \(coefficientColumnCount)")
                    .font(MatrixUIDesignTokens.Typography.supportText)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Coefficient matrix dimensions \(matrix.rows) by \(coefficientColumnCount)")
            }

            Toggle("Homogeneous system (A x = 0)", isOn: $isHomogeneous)
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
                Text(title)
                    .font(MatrixUIDesignTokens.Typography.sectionTitle)
                Spacer()
                Text("n = \(vector.dimension)")
                    .font(MatrixUIDesignTokens.Typography.supportText)
                    .foregroundStyle(.secondary)
            }

            if showsNameField {
                TextField("Vector name", text: $vector.name)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("vector-name-field")
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
            Text("Operate Configuration")
                .font(MatrixUIDesignTokens.Typography.sectionTitle)

            Picker("Operation", selection: $operateKind) {
                ForEach(MatrixOperateKind.allCases, id: \.self) { kind in
                    Text(kind.title).tag(kind)
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
                    Text("Exponent: \(exponent)")
                }
                .accessibilityIdentifier("operate-exponent-stepper")
            }

            if operateKind == .expression {
                TextField("Expression (e.g. A*B, A*v, 2*v, transpose(A), trace(A), A^3)", text: $expression)
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
    @Binding public var linearMapDefinitionKind: MatrixLinearMapDefinitionKind

    public init(
        analyzeKind: Binding<MatrixAnalyzeKind>,
        linearMapDefinitionKind: Binding<MatrixLinearMapDefinitionKind>
    ) {
        self._analyzeKind = analyzeKind
        self._linearMapDefinitionKind = linearMapDefinitionKind
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
            Text("Analyze Workflow")
                .font(MatrixUIDesignTokens.Typography.sectionTitle)

            Picker("Workflow", selection: $analyzeKind) {
                ForEach(MatrixAnalyzeKind.allCases, id: \.self) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("analyze-kind-picker")

            if analyzeKind == .linearMaps {
                Picker("Linear map definition", selection: $linearMapDefinitionKind) {
                    ForEach(MatrixLinearMapDefinitionKind.allCases, id: \.self) { kind in
                        Text(kind.title).tag(kind)
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
            Text("Spaces Workflow")
                .font(MatrixUIDesignTokens.Typography.sectionTitle)

            Picker("Workflow", selection: $spacesKind) {
                ForEach(MatrixSpacesKind.allCases, id: \.self) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("spaces-kind-picker")

            Picker("Abstract-space preset", selection: $spacesPresetKind) {
                ForEach(MatrixSpacesPresetKind.allCases, id: \.self) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("spaces-preset-picker")

            switch spacesPresetKind {
            case .none:
                EmptyView()
            case .polynomialSpace:
                Stepper(value: $polynomialDegree, in: 0...8) {
                    Text("Polynomial degree n: \(polynomialDegree) (P_n)")
                }
                .accessibilityIdentifier("spaces-polynomial-degree-stepper")
            case .matrixSpace:
                Stepper(value: $matrixSpaceRows, in: 1...5) {
                    Text("Matrix-space rows m: \(matrixSpaceRows)")
                }
                .accessibilityIdentifier("spaces-matrix-rows-stepper")

                Stepper(value: $matrixSpaceColumns, in: 1...5) {
                    Text("Matrix-space columns n: \(matrixSpaceColumns)")
                }
                .accessibilityIdentifier("spaces-matrix-columns-stepper")
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
                            Text(item.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
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
                        Text(entry.title)
                            .font(.subheadline)
                        Text(entry.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
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

    public init(
        basis: Binding<BasisDraftInput>,
        title: String = "Basis"
    ) {
        self._basis = basis
        self.title = title
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
            HStack(spacing: MatrixUIDesignTokens.Spacing.regular) {
                Text(title)
                    .font(MatrixUIDesignTokens.Typography.sectionTitle)
                Spacer()
                Text("\(basis.vectorCount) vectors in R^\(basis.dimension)")
                    .font(MatrixUIDesignTokens.Typography.supportText)
                    .foregroundStyle(.secondary)
            }

            TextField("Basis name", text: $basis.name)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("basis-name-field")
                .accessibilityLabel("Basis name")

            HStack(spacing: MatrixUIDesignTokens.Spacing.compact) {
                editorButton("+ Vector") { basis.addVector() }
                editorButton("- Vector") { basis.removeLastVector() }
                editorButton("+ Dim") { basis.increaseDimension() }
                editorButton("- Dim") { basis.decreaseDimension() }
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

public struct MatrixValidationMessageView: View {
    public var message: String

    public init(message: String) {
        self.message = message
    }

    public var body: some View {
        Text(message)
            .font(MatrixUIDesignTokens.Typography.supportText)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MatrixUIDesignTokens.Spacing.regular)
            .background(
                RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.control)
                    .fill(MatrixUIDesignTokens.ColorPalette.controlBackground)
            )
            .accessibilityIdentifier("matrix-validation-message")
    }
}
