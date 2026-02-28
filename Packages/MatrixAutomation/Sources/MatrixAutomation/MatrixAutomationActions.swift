import Foundation
import MatrixDomain

public struct MatrixAutomationAction: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let destination: MatrixMasterDestination

    public init(id: String, title: String, destination: MatrixMasterDestination) {
        self.id = id
        self.title = title
        self.destination = destination
    }
}

public protocol MatrixAutomationProviding: Sendable {
    func defaultActions() -> [MatrixAutomationAction]
}

public struct DefaultMatrixAutomationProvider: MatrixAutomationProviding {
    public init() {}

    public func defaultActions() -> [MatrixAutomationAction] {
        MatrixMasterDestination.allCases.map { destination in
            MatrixAutomationAction(
                id: destination.rawValue,
                title: "Open \(destination.title)",
                destination: destination
            )
        }
    }
}
