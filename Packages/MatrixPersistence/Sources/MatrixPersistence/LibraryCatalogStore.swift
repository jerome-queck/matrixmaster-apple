import Foundation
import MatrixDomain

public protocol LibraryCatalogStoring: Sendable {
    func loadSnapshot() async throws -> MatrixLibrarySnapshot
    func loadVectors() async throws -> [MatrixLibraryVectorItem]
    func loadHistory(limit: Int?) async throws -> [MatrixLibraryHistoryEntry]
    func saveVector(name: String, entries: [String]) async throws -> MatrixLibraryVectorItem
    func deleteVector(id: UUID) async throws
    func appendHistory(_ entry: MatrixLibraryHistoryEntry) async throws
    func exportSnapshotData() async throws -> Data
}

public enum LibraryCatalogStoreError: Error, LocalizedError, Sendable {
    case createDirectoryFailed(path: String, description: String)
    case readFailed(path: String, description: String)
    case decodeFailed(path: String, description: String)
    case encodeFailed(description: String)
    case writeFailed(path: String, description: String)

    public var errorDescription: String? {
        switch self {
        case let .createDirectoryFailed(path, description):
            return "Could not create library directory at \(path): \(description)"
        case let .readFailed(path, description):
            return "Could not read library file at \(path): \(description)"
        case let .decodeFailed(path, description):
            return "Could not decode library file at \(path): \(description)"
        case let .encodeFailed(description):
            return "Could not encode library payload: \(description)"
        case let .writeFailed(path, description):
            return "Could not write library file at \(path): \(description)"
        }
    }
}

public actor InMemoryLibraryCatalogStore: LibraryCatalogStoring {
    private var snapshot: MatrixLibrarySnapshot

    public init(snapshot: MatrixLibrarySnapshot = MatrixLibrarySnapshot()) {
        self.snapshot = snapshot
    }

    public func loadSnapshot() async throws -> MatrixLibrarySnapshot {
        snapshot
    }

    public func loadVectors() async throws -> [MatrixLibraryVectorItem] {
        snapshot.vectors.sorted { $0.savedAt > $1.savedAt }
    }

    public func loadHistory(limit: Int? = nil) async throws -> [MatrixLibraryHistoryEntry] {
        let ordered = snapshot.history.sorted { $0.recordedAt > $1.recordedAt }
        guard let limit else {
            return ordered
        }

        return Array(ordered.prefix(max(0, limit)))
    }

    public func saveVector(name: String, entries: [String]) async throws -> MatrixLibraryVectorItem {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedName = trimmedName.isEmpty ? "Untitled Vector" : trimmedName
        let safeEntries = entries.isEmpty ? ["0"] : entries

        let vector = MatrixLibraryVectorItem(
            name: sanitizedName,
            entries: safeEntries,
            savedAt: Date()
        )

        snapshot.vectors.insert(vector, at: 0)
        snapshot.updatedAt = Date()

        return vector
    }

    public func deleteVector(id: UUID) async throws {
        snapshot.vectors.removeAll { $0.id == id }
        snapshot.updatedAt = Date()
    }

    public func appendHistory(_ entry: MatrixLibraryHistoryEntry) async throws {
        snapshot.history.insert(entry, at: 0)
        if snapshot.history.count > 250 {
            snapshot.history = Array(snapshot.history.prefix(250))
        }
        snapshot.updatedAt = Date()
    }

    public func exportSnapshotData() async throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            return try encoder.encode(snapshot)
        } catch {
            throw LibraryCatalogStoreError.encodeFailed(description: error.localizedDescription)
        }
    }
}

public actor FileLibraryCatalogStore: LibraryCatalogStoring {
    private let fileURL: URL
    private let fileManager: FileManager

    public init(
        fileURL: URL,
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    public func loadSnapshot() async throws -> MatrixLibrarySnapshot {
        try readSnapshot()
    }

    public func loadVectors() async throws -> [MatrixLibraryVectorItem] {
        let snapshot = try readSnapshot()
        return snapshot.vectors.sorted { $0.savedAt > $1.savedAt }
    }

    public func loadHistory(limit: Int? = nil) async throws -> [MatrixLibraryHistoryEntry] {
        let snapshot = try readSnapshot()
        let ordered = snapshot.history.sorted { $0.recordedAt > $1.recordedAt }

        guard let limit else {
            return ordered
        }

        return Array(ordered.prefix(max(0, limit)))
    }

    public func saveVector(name: String, entries: [String]) async throws -> MatrixLibraryVectorItem {
        var snapshot = try readSnapshot()

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedName = trimmedName.isEmpty ? "Untitled Vector" : trimmedName
        let safeEntries = entries.isEmpty ? ["0"] : entries

        let vector = MatrixLibraryVectorItem(
            name: sanitizedName,
            entries: safeEntries,
            savedAt: Date()
        )

        snapshot.vectors.insert(vector, at: 0)
        snapshot.updatedAt = Date()

        try persist(snapshot)
        return vector
    }

    public func deleteVector(id: UUID) async throws {
        var snapshot = try readSnapshot()
        snapshot.vectors.removeAll { $0.id == id }
        snapshot.updatedAt = Date()

        try persist(snapshot)
    }

    public func appendHistory(_ entry: MatrixLibraryHistoryEntry) async throws {
        var snapshot = try readSnapshot()
        snapshot.history.insert(entry, at: 0)
        if snapshot.history.count > 250 {
            snapshot.history = Array(snapshot.history.prefix(250))
        }
        snapshot.updatedAt = Date()

        try persist(snapshot)
    }

    public func exportSnapshotData() async throws -> Data {
        let snapshot = try readSnapshot()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            return try encoder.encode(snapshot)
        } catch {
            throw LibraryCatalogStoreError.encodeFailed(description: error.localizedDescription)
        }
    }

    private func readSnapshot() throws -> MatrixLibrarySnapshot {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return MatrixLibrarySnapshot()
        }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw LibraryCatalogStoreError.readFailed(
                path: fileURL.path,
                description: error.localizedDescription
            )
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(MatrixLibrarySnapshot.self, from: data)
        } catch {
            throw LibraryCatalogStoreError.decodeFailed(
                path: fileURL.path,
                description: error.localizedDescription
            )
        }
    }

    private func persist(_ snapshot: MatrixLibrarySnapshot) throws {
        let parentDirectory = fileURL.deletingLastPathComponent()

        do {
            try fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
        } catch {
            throw LibraryCatalogStoreError.createDirectoryFailed(
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
            throw LibraryCatalogStoreError.encodeFailed(description: error.localizedDescription)
        }

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw LibraryCatalogStoreError.writeFailed(
                path: fileURL.path,
                description: error.localizedDescription
            )
        }
    }
}
