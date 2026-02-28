import Foundation
import MatrixDomain

public protocol WorkspaceSnapshotStoring: Sendable {
    func loadLatestSnapshot() async throws -> MatrixMasterShellSnapshot?
    func saveSnapshot(_ snapshot: MatrixMasterShellSnapshot) async throws
}

public protocol WorkspaceDocumentCoding: Sendable {
    func encode(_ document: MatrixWorkspaceDocument) throws -> Data
    func decode(_ data: Data) throws -> MatrixWorkspaceDocument
}

public enum WorkspaceDocumentCodecError: Error, Equatable {
    case unsupportedSchemaVersion(Int)
}

public enum WorkspaceSnapshotStoreError: Error, LocalizedError, Sendable {
    case createDirectoryFailed(path: String, description: String)
    case readFailed(path: String, description: String)
    case decodeFailed(path: String, description: String)
    case encodeFailed(description: String)
    case writeFailed(path: String, description: String)

    public var errorDescription: String? {
        switch self {
        case let .createDirectoryFailed(path, description):
            return "Could not create snapshot directory at \(path): \(description)"
        case let .readFailed(path, description):
            return "Could not read snapshot file at \(path): \(description)"
        case let .decodeFailed(path, description):
            return "Could not decode snapshot file at \(path): \(description)"
        case let .encodeFailed(description):
            return "Could not encode snapshot payload: \(description)"
        case let .writeFailed(path, description):
            return "Could not write snapshot file at \(path): \(description)"
        }
    }
}

public enum WorkspaceSyncCoordinatorError: Error, LocalizedError, Sendable {
    case createDirectoryFailed(path: String, description: String)
    case readFailed(path: String, description: String)
    case decodeFailed(path: String, description: String)
    case encodeFailed(description: String)
    case writeFailed(path: String, description: String)

    public var errorDescription: String? {
        switch self {
        case let .createDirectoryFailed(path, description):
            return "Could not create sync directory at \(path): \(description)"
        case let .readFailed(path, description):
            return "Could not read sync state at \(path): \(description)"
        case let .decodeFailed(path, description):
            return "Could not decode sync state at \(path): \(description)"
        case let .encodeFailed(description):
            return "Could not encode sync state payload: \(description)"
        case let .writeFailed(path, description):
            return "Could not write sync state at \(path): \(description)"
        }
    }
}

public struct MatrixWorkspaceDocument: Equatable, Codable, Sendable {
    public static let currentSchemaVersion = 1
    public static let fileExtension = "mmws"
    public static let displayName = "Matrix Master Workspace"
    public static let utTypeIdentifier = "com.matrixmaster.workspace"

    public var schemaVersion: Int
    public var workspaceID: UUID
    public var savedAt: Date
    public var snapshot: MatrixMasterShellSnapshot

    public init(
        schemaVersion: Int = MatrixWorkspaceDocument.currentSchemaVersion,
        workspaceID: UUID = UUID(),
        savedAt: Date = Date(),
        snapshot: MatrixMasterShellSnapshot
    ) {
        self.schemaVersion = schemaVersion
        self.workspaceID = workspaceID
        self.savedAt = savedAt
        self.snapshot = snapshot
    }
}

public struct WorkspaceSyncSnapshot: Equatable, Codable, Sendable {
    public var state: MatrixMasterSyncState
    public var pendingWrites: Int
    public var isCloudAvailable: Bool
    public var updatedAt: Date

    public init(
        state: MatrixMasterSyncState = .localOnly,
        pendingWrites: Int = 0,
        isCloudAvailable: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.state = state
        self.pendingWrites = max(0, pendingWrites)
        self.isCloudAvailable = isCloudAvailable
        self.updatedAt = updatedAt
    }
}

public struct JSONWorkspaceDocumentCodec: WorkspaceDocumentCoding {
    public init() {}

    public func encode(_ document: MatrixWorkspaceDocument) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(document)
    }

    public func decode(_ data: Data) throws -> MatrixWorkspaceDocument {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let document = try decoder.decode(MatrixWorkspaceDocument.self, from: data)

        guard document.schemaVersion == MatrixWorkspaceDocument.currentSchemaVersion else {
            throw WorkspaceDocumentCodecError.unsupportedSchemaVersion(document.schemaVersion)
        }

        return document
    }
}

public enum MatrixWorkspaceFileLocations {
    public static func defaultSnapshotURL(fileManager: FileManager = .default) -> URL {
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let appDirectory = baseDirectory.appendingPathComponent("MatrixMaster", isDirectory: true)

        return appDirectory
            .appendingPathComponent("LatestWorkspace")
            .appendingPathExtension(MatrixWorkspaceDocument.fileExtension)
    }

    public static func defaultSyncStatusURL(fileManager: FileManager = .default) -> URL {
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let appDirectory = baseDirectory.appendingPathComponent("MatrixMaster", isDirectory: true)

        return appDirectory
            .appendingPathComponent("SyncStatus")
            .appendingPathExtension("json")
    }

    public static func defaultLibraryCatalogURL(fileManager: FileManager = .default) -> URL {
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let appDirectory = baseDirectory.appendingPathComponent("MatrixMaster", isDirectory: true)

        return appDirectory
            .appendingPathComponent("LibraryCatalog")
            .appendingPathExtension("json")
    }

    public static func defaultLibraryExportURL(fileManager: FileManager = .default) -> URL {
        let baseDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return baseDirectory
            .appendingPathComponent("MatrixMaster-Library-Export")
            .appendingPathExtension("json")
    }
}

public actor InMemoryWorkspaceSnapshotStore: WorkspaceSnapshotStoring {
    private var latestSnapshot: MatrixMasterShellSnapshot?

    public init() {}

    public func loadLatestSnapshot() async throws -> MatrixMasterShellSnapshot? {
        latestSnapshot
    }

    public func saveSnapshot(_ snapshot: MatrixMasterShellSnapshot) async throws {
        latestSnapshot = snapshot
    }
}

public actor FileWorkspaceSnapshotStore: WorkspaceSnapshotStoring {
    private let fileURL: URL
    private let codec: any WorkspaceDocumentCoding
    private let fileManager: FileManager
    private var activeWorkspaceID: UUID

    public init(
        fileURL: URL,
        codec: any WorkspaceDocumentCoding = JSONWorkspaceDocumentCodec(),
        fileManager: FileManager = .default,
        activeWorkspaceID: UUID = UUID()
    ) {
        self.fileURL = fileURL
        self.codec = codec
        self.fileManager = fileManager
        self.activeWorkspaceID = activeWorkspaceID
    }

    public func loadLatestSnapshot() async throws -> MatrixMasterShellSnapshot? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw WorkspaceSnapshotStoreError.readFailed(
                path: fileURL.path,
                description: error.localizedDescription
            )
        }

        do {
            let document = try codec.decode(data)
            activeWorkspaceID = document.workspaceID
            return document.snapshot
        } catch {
            throw WorkspaceSnapshotStoreError.decodeFailed(
                path: fileURL.path,
                description: error.localizedDescription
            )
        }
    }

    public func saveSnapshot(_ snapshot: MatrixMasterShellSnapshot) async throws {
        let parentDirectory = fileURL.deletingLastPathComponent()
        do {
            try fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
        } catch {
            throw WorkspaceSnapshotStoreError.createDirectoryFailed(
                path: parentDirectory.path,
                description: error.localizedDescription
            )
        }

        let data: Data
        do {
            let document = MatrixWorkspaceDocument(
                workspaceID: activeWorkspaceID,
                savedAt: Date(),
                snapshot: snapshot
            )
            data = try codec.encode(document)
        } catch {
            throw WorkspaceSnapshotStoreError.encodeFailed(description: error.localizedDescription)
        }

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw WorkspaceSnapshotStoreError.writeFailed(
                path: fileURL.path,
                description: error.localizedDescription
            )
        }
    }
}

public protocol WorkspaceSyncCoordinating: Sendable {
    func currentState() async -> MatrixMasterSyncState
    func currentSnapshot() async -> WorkspaceSyncSnapshot
    func recordLocalWrite() async throws
    func markRemoteConverged() async throws
    func markNeedsAttention() async throws
    func resetToLocalOnly() async throws
    func setCloudAvailable(_ isCloudAvailable: Bool) async throws
}

public actor InMemoryWorkspaceSyncCoordinator: WorkspaceSyncCoordinating {
    private var snapshot: WorkspaceSyncSnapshot

    public init(initialSnapshot: WorkspaceSyncSnapshot = WorkspaceSyncSnapshot()) {
        self.snapshot = initialSnapshot
    }

    public func currentState() async -> MatrixMasterSyncState {
        snapshot.state
    }

    public func currentSnapshot() async -> WorkspaceSyncSnapshot {
        snapshot
    }

    public func recordLocalWrite() async throws {
        applyMutation { snapshot in
            snapshot.pendingWrites += 1
            snapshot.state = snapshot.isCloudAvailable ? .syncing : .localOnly
        }
    }

    public func markRemoteConverged() async throws {
        applyMutation { snapshot in
            if snapshot.pendingWrites > 0 {
                snapshot.pendingWrites -= 1
            }

            if snapshot.pendingWrites == 0 {
                snapshot.state = snapshot.isCloudAvailable ? .synced : .localOnly
            } else {
                snapshot.state = .syncing
            }
        }
    }

    public func markNeedsAttention() async throws {
        applyMutation { snapshot in
            snapshot.state = .needsAttention
        }
    }

    public func resetToLocalOnly() async throws {
        applyMutation { snapshot in
            snapshot.pendingWrites = 0
            snapshot.state = .localOnly
        }
    }

    public func setCloudAvailable(_ isCloudAvailable: Bool) async throws {
        applyMutation { snapshot in
            snapshot.isCloudAvailable = isCloudAvailable

            if snapshot.state == .needsAttention {
                return
            }

            if !snapshot.isCloudAvailable {
                snapshot.state = .localOnly
            } else if snapshot.pendingWrites > 0 {
                snapshot.state = .syncing
            } else {
                snapshot.state = .synced
            }
        }
    }

    private func applyMutation(_ mutation: (inout WorkspaceSyncSnapshot) -> Void) {
        mutation(&snapshot)
        snapshot.updatedAt = Date()
    }
}

public actor FileWorkspaceSyncCoordinator: WorkspaceSyncCoordinating {
    private let fileURL: URL
    private let fileManager: FileManager
    private var snapshot: WorkspaceSyncSnapshot

    public init(
        fileURL: URL,
        fileManager: FileManager = .default,
        initialSnapshot: WorkspaceSyncSnapshot = WorkspaceSyncSnapshot()
    ) throws {
        self.fileURL = fileURL
        self.fileManager = fileManager

        if fileManager.fileExists(atPath: fileURL.path) {
            let data: Data
            do {
                data = try Data(contentsOf: fileURL)
            } catch {
                throw WorkspaceSyncCoordinatorError.readFailed(
                    path: fileURL.path,
                    description: error.localizedDescription
                )
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            do {
                self.snapshot = try decoder.decode(WorkspaceSyncSnapshot.self, from: data)
            } catch {
                throw WorkspaceSyncCoordinatorError.decodeFailed(
                    path: fileURL.path,
                    description: error.localizedDescription
                )
            }
        } else {
            self.snapshot = initialSnapshot
        }
    }

    public func currentState() async -> MatrixMasterSyncState {
        snapshot.state
    }

    public func currentSnapshot() async -> WorkspaceSyncSnapshot {
        snapshot
    }

    public func recordLocalWrite() async throws {
        try mutateAndPersist { snapshot in
            snapshot.pendingWrites += 1
            snapshot.state = snapshot.isCloudAvailable ? .syncing : .localOnly
        }
    }

    public func markRemoteConverged() async throws {
        try mutateAndPersist { snapshot in
            if snapshot.pendingWrites > 0 {
                snapshot.pendingWrites -= 1
            }

            if snapshot.pendingWrites == 0 {
                snapshot.state = snapshot.isCloudAvailable ? .synced : .localOnly
            } else {
                snapshot.state = .syncing
            }
        }
    }

    public func markNeedsAttention() async throws {
        try mutateAndPersist { snapshot in
            snapshot.state = .needsAttention
        }
    }

    public func resetToLocalOnly() async throws {
        try mutateAndPersist { snapshot in
            snapshot.pendingWrites = 0
            snapshot.state = .localOnly
        }
    }

    public func setCloudAvailable(_ isCloudAvailable: Bool) async throws {
        try mutateAndPersist { snapshot in
            snapshot.isCloudAvailable = isCloudAvailable

            if snapshot.state == .needsAttention {
                return
            }

            if !snapshot.isCloudAvailable {
                snapshot.state = .localOnly
            } else if snapshot.pendingWrites > 0 {
                snapshot.state = .syncing
            } else {
                snapshot.state = .synced
            }
        }
    }

    private func mutateAndPersist(_ mutation: (inout WorkspaceSyncSnapshot) -> Void) throws {
        var proposedSnapshot = snapshot
        mutation(&proposedSnapshot)
        proposedSnapshot.updatedAt = Date()

        try persist(snapshot: proposedSnapshot)
        snapshot = proposedSnapshot
    }

    private func persist(snapshot: WorkspaceSyncSnapshot) throws {
        let parentDirectory = fileURL.deletingLastPathComponent()
        do {
            try fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
        } catch {
            throw WorkspaceSyncCoordinatorError.createDirectoryFailed(
                path: parentDirectory.path,
                description: error.localizedDescription
            )
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data: Data
        do {
            data = try encoder.encode(snapshot)
        } catch {
            throw WorkspaceSyncCoordinatorError.encodeFailed(description: error.localizedDescription)
        }

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw WorkspaceSyncCoordinatorError.writeFailed(
                path: fileURL.path,
                description: error.localizedDescription
            )
        }
    }
}
