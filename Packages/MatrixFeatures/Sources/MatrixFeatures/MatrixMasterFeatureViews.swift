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
            LazyVStack(alignment: .leading, spacing: 16) {
                MatrixMasterSyncBadge(state: coordinator.syncState)

                MatrixResultPresentationView(
                    destination: destination,
                    mode: coordinator.selectedMode,
                    lastResult: coordinator.result(for: destination)
                )

                editorSurface

                if let validationMessage = coordinator.inputValidationMessage {
                    MatrixValidationMessageView(message: validationMessage)
                }

                if let persistenceMessage = coordinator.persistenceMessage {
                    MatrixValidationMessageView(message: persistenceMessage)
                }

                if let reuseMessage = coordinator.reuseMessage {
                    MatrixValidationMessageView(message: reuseMessage)
                }

                if let libraryMessage = coordinator.libraryMessage {
                    MatrixValidationMessageView(message: libraryMessage)
                }

                reuseActionsSurface
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            runComputationBar
        }
        .navigationTitle(destination.title)
    }

    private var runComputationBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Button("Run Sample \(destination.title) Computation") {
                    Task {
                        await coordinator.runQuickComputation(for: destination)
                    }
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("run-sample-\(destination.rawValue)")
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var reuseActionsSurface: some View {
        if let result = coordinator.result(for: destination),
           !result.reusablePayloads.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Reuse Actions")
                    .font(.headline)

                ForEach(reuseActions(for: result), id: \.id) { action in
                    Button {
                        coordinator.applyReusePayload(action.payload, into: action.target)
                    } label: {
                        MatrixInlineMathText(
                            reuseActionTitle(for: action.payload, target: action.target),
                            style: .body
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("reuse-payload-\(action.payloadIndex)-to-\(action.target.rawValue)")
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: MatrixUIDesignTokens.CornerRadius.card)
                    .fill(MatrixUIDesignTokens.ColorPalette.cardBackground)
            )
        }
    }

    private func compatibleDestinations(for payload: MatrixMasterReusablePayload) -> [MatrixMasterDestination] {
        switch payload {
        case .matrix:
            return [.analyze, .operate]
        case .vector:
            return [.operate, .library]
        }
    }

    private func reuseActionTitle(for payload: MatrixMasterReusablePayload, target: MatrixMasterDestination) -> String {
        switch payload {
        case let .matrix(matrixPayload):
            return "Use \(matrixPayload.source) in \(target.title)"
        case let .vector(vectorPayload):
            return "Use \(vectorPayload.source) in \(target.title)"
        }
    }

    private func reuseActions(for result: MatrixMasterComputationResult) -> [ReuseAction] {
        var actions: [ReuseAction] = []

        for (payloadIndex, payload) in result.reusablePayloads.enumerated() {
            for target in compatibleDestinations(for: payload) where target != destination {
                actions.append(
                    ReuseAction(
                        payloadIndex: payloadIndex,
                        payload: payload,
                        target: target
                    )
                )
            }
        }

        return actions
    }

    @ViewBuilder
    private var editorSurface: some View {
        switch destination {
        case .solve:
            AugmentedSystemEditorView(
                matrix: $coordinator.matrixDraft,
                title: "Solve System Input"
            )
        case .operate:
            OperateConfigurationView(
                operateKind: $coordinator.operateKind,
                scalarToken: $coordinator.operateScalarToken,
                exponent: $coordinator.operateExponent,
                expression: $coordinator.operateExpression
            )
            MatrixGridEditorView(
                matrix: $coordinator.matrixDraft,
                title: "A (primary matrix)",
                showsRandomizeButton: true
            )
            operateAuxiliaryInputs
        case .analyze:
            AnalyzeConfigurationView(
                analyzeKind: $coordinator.analyzeKind,
                matrixPropertiesSelection: $coordinator.analyzeMatrixPropertiesSelection,
                linearMapDefinitionKind: $coordinator.linearMapDefinitionKind
            )
            analyzeAuxiliaryInputs
        case .spaces:
            SpacesConfigurationView(
                spacesKind: $coordinator.spacesKind,
                spacesPresetKind: $coordinator.spacesPresetKind,
                spacesOutputSelection: $coordinator.spacesOutputSelection,
                polynomialDegree: $coordinator.spacesPolynomialDegree,
                matrixSpaceRows: $coordinator.spacesMatrixRowCount,
                matrixSpaceColumns: $coordinator.spacesMatrixColumnCount,
                showsSecondaryApplyActions: spacesWorkflowNeedsSecondarySet,
                onApplyPrimaryPreset: {
                    coordinator.applySpacesPresetToPrimarySet()
                },
                onApplySecondaryPreset: {
                    coordinator.applySpacesPresetToSecondarySet()
                },
                onApplyBothPresets: {
                    coordinator.applySpacesPresetToBothSets()
                }
            )
            spacesAuxiliaryInputs
        case .library:
            VectorEditorView(
                vector: $coordinator.vectorDraft,
                title: "Reusable Vector Draft",
                showsNameField: true
            )
            LibraryCatalogView(
                vectors: coordinator.libraryVectors,
                history: coordinator.libraryHistory,
                exportPath: coordinator.libraryExportPath,
                onSaveDraft: {
                    Task {
                        await coordinator.saveCurrentVectorDraftToLibrary()
                    }
                },
                onLoadVector: { item in
                    coordinator.loadLibraryVectorIntoDraft(item)
                },
                onDeleteVector: { item in
                    Task {
                        await coordinator.deleteLibraryVector(item)
                    }
                },
                onExportCatalog: {
                    Task {
                        await coordinator.exportLibraryCatalog()
                    }
                }
            )
        }
    }

    @ViewBuilder
    private var analyzeAuxiliaryInputs: some View {
        switch coordinator.analyzeKind {
        case .matrixProperties:
            MatrixGridEditorView(
                matrix: $coordinator.matrixDraft,
                title: "Analyze Matrix Input",
                showsRandomizeButton: true
            )
            BasisEditorView(
                basis: $coordinator.basisDraft,
                showsDimensionControls: false
            )
        case .spanMembership:
            BasisEditorView(
                basis: $coordinator.basisDraft,
                showsDimensionControls: false
            )
            VectorEditorView(
                vector: $coordinator.vectorDraft,
                title: "Target vector x",
                showsNameField: true
            )
        case .independence:
            BasisEditorView(
                basis: $coordinator.basisDraft,
                showsDimensionControls: false
            )
        case .coordinates:
            BasisEditorView(
                basis: $coordinator.basisDraft,
                showsDimensionControls: false
            )
            VectorEditorView(
                vector: $coordinator.vectorDraft,
                title: "Vector x for coordinates [x]₍β₎",
                showsNameField: true
            )
        case .linearMaps:
            Group {
                BasisEditorView(
                    basis: $coordinator.basisDraft,
                    title: "Domain basis β",
                    showsDimensionControls: false
                )
                BasisEditorView(
                    basis: $coordinator.secondaryBasisDraft,
                    title: "Codomain / comparison basis γ (or β')",
                    showsDimensionControls: false
                )
                switch coordinator.linearMapDefinitionKind {
                case .matrix:
                    MatrixGridEditorView(
                        matrix: $coordinator.matrixDraft,
                        title: "Map matrix A (standard coordinates)",
                        showsRandomizeButton: true
                    )
                case .basisImages:
                    MatrixGridEditorView(
                        matrix: $coordinator.secondaryMatrixDraft,
                        title: "Image matrix Y = [T(b1) ... T(bn)]",
                        showsRandomizeButton: true
                    )
                }
            }
            .onAppear {
                coordinator.synchronizeAnalyzeLinearMapFromBasis()
            }
            .onChange(of: coordinator.linearMapDefinitionKind) { _, _ in
                coordinator.synchronizeAnalyzeLinearMapFromBasis()
            }
            .onChange(of: coordinator.basisDraft.vectorCount) { _, _ in
                coordinator.synchronizeAnalyzeLinearMapFromBasis()
            }
            .onChange(of: coordinator.secondaryBasisDraft.vectorCount) { _, _ in
                coordinator.synchronizeAnalyzeLinearMapFromBasis()
            }
            .onChange(of: coordinator.basisDraft.dimension) { _, _ in
                coordinator.synchronizeAnalyzeLinearMapFromBasis()
            }
            .onChange(of: coordinator.secondaryBasisDraft.dimension) { _, _ in
                coordinator.synchronizeAnalyzeLinearMapFromBasis()
            }
            .onChange(of: coordinator.matrixDraft.rows) { _, _ in
                coordinator.synchronizeAnalyzeLinearMapFromMatrix()
            }
            .onChange(of: coordinator.matrixDraft.columns) { _, _ in
                coordinator.synchronizeAnalyzeLinearMapFromMatrix()
            }
        }
    }

    @ViewBuilder
    private var spacesAuxiliaryInputs: some View {
        switch coordinator.spacesKind {
        case .basisTestExtract, .basisExtendPrune:
            spacesEditor(
                basis: $coordinator.basisDraft,
                title: "Generating Set U"
            )
        case .subspaceSum, .subspaceIntersection, .directSumCheck:
            spacesEditor(
                basis: $coordinator.basisDraft,
                title: "Generating Set U"
            )
            spacesEditor(
                basis: $coordinator.secondaryBasisDraft,
                title: "Generating Set W"
            )
        }
    }

    private var spacesWorkflowNeedsSecondarySet: Bool {
        switch coordinator.spacesKind {
        case .basisTestExtract, .basisExtendPrune:
            return false
        case .subspaceSum, .subspaceIntersection, .directSumCheck:
            return true
        }
    }

    @ViewBuilder
    private var operateAuxiliaryInputs: some View {
        switch coordinator.operateKind {
        case .matrixAdd, .matrixSubtract, .matrixMultiply:
            MatrixGridEditorView(
                matrix: $coordinator.secondaryMatrixDraft,
                title: "B (secondary matrix)",
                showsRandomizeButton: true
            )
        case .matrixVectorProduct:
            VectorEditorView(
                vector: $coordinator.vectorDraft,
                title: "v (right-hand vector)",
                showsNameField: true
            )
        case .vectorAdd:
            VectorEditorView(
                vector: $coordinator.vectorDraft,
                title: "u (first vector)",
                showsNameField: true
            )
            VectorEditorView(
                vector: $coordinator.secondaryVectorDraft,
                title: "v (second vector)",
                showsNameField: true
            )
        case .scalarVectorMultiply:
            VectorEditorView(
                vector: $coordinator.vectorDraft,
                title: "v (vector)",
                showsNameField: true
            )
        case .expression:
            MatrixGridEditorView(
                matrix: $coordinator.secondaryMatrixDraft,
                title: "B (secondary matrix for expression)",
                showsRandomizeButton: true
            )
            VectorEditorView(
                vector: $coordinator.vectorDraft,
                title: "v (vector for expression)",
                showsNameField: true
            )
            VectorEditorView(
                vector: $coordinator.secondaryVectorDraft,
                title: "u (secondary vector for expression)",
                showsNameField: true
            )
        case .power, .trace, .transpose:
            EmptyView()
        }
    }

    @ViewBuilder
    private func spacesEditor(
        basis: Binding<BasisDraftInput>,
        title: String
    ) -> some View {
        switch coordinator.spacesPresetKind {
        case .none:
            BasisEditorView(
                basis: basis,
                title: title
            )
        case .polynomialSpace:
            PolynomialSpaceElementsEditorView(
                basis: basis,
                polynomialDegree: $coordinator.spacesPolynomialDegree,
                title: "\(title) (Polynomial Entry)"
            )
        case .matrixSpace:
            MatrixSpaceElementsEditorView(
                basis: basis,
                rowCount: $coordinator.spacesMatrixRowCount,
                columnCount: $coordinator.spacesMatrixColumnCount,
                title: "\(title) (Matrix Entry)"
            )
        }
    }
}

private struct ReuseAction: Identifiable {
    let payloadIndex: Int
    let payload: MatrixMasterReusablePayload
    let target: MatrixMasterDestination

    var id: String {
        "\(payloadIndex)-\(target.rawValue)"
    }
}
