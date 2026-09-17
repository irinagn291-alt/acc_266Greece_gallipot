import Foundation

enum StillroomFault: Error, Equatable, Sendable {
    case emptyBay
    case nothingToUndo
    case invalidQuantity
    case invalidIdentity
    case missingBay
}

enum StillroomDocumentError: Error, Equatable, Sendable {
    case unsupportedSchema(Int)
}
