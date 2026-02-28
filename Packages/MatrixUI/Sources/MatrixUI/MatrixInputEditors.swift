import SwiftUI
import MatrixDomain

public struct MatrixGridEditorView: View {
    @Binding public var matrix: MatrixDraftInput
    public var title: String

    public init(matrix: Binding<MatrixDraftInput>, title: String = "Matrix") {
        self._matrix = matrix
        self.title = title
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

            HStack(spacing: MatrixUIDesignTokens.Spacing.compact) {
                editorButton("+ Row") { matrix.addRow() }
                editorButton("- Row") { matrix.removeLastRow() }
                editorButton("+ Col") { matrix.addColumn() }
                editorButton("- Col") { matrix.removeLastColumn() }
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
            .accessibilityIdentifier("matrix-editor-action-\(label)")
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
}

public struct BasisEditorView: View {
    @Binding public var basis: BasisDraftInput

    public init(basis: Binding<BasisDraftInput>) {
        self._basis = basis
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MatrixUIDesignTokens.Spacing.regular) {
            HStack(spacing: MatrixUIDesignTokens.Spacing.regular) {
                Text("Basis")
                    .font(MatrixUIDesignTokens.Typography.sectionTitle)
                Spacer()
                Text("\(basis.vectorCount) vectors")
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
