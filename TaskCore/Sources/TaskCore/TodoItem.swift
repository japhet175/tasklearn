import Foundation
import GRDB

/// Une tâche. Valeur immuable par copie, sûre à passer entre threads (Sendable).
public struct TodoItem: Identifiable, Hashable, Sendable, Codable, FetchableRecord, PersistableRecord {
    public var id: UUID
    public var title: String
    public var isDone: Bool
    public var createdAt: Date
    public var dueDate: Date?
    /// Ajouté par la migration "v2".
    public var notes: String?

    public static let databaseTableName = "todoItem"

    public init(
        id: UUID = UUID(),
        title: String,
        isDone: Bool = false,
        createdAt: Date = Date(),
        dueDate: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.notes = notes
    }
}
