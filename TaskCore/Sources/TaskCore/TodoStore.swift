import Foundation
import GRDB

public enum TodoError: Error, Equatable {
    case emptyTitle
    case notFound
}

/// Accès à la base. Toutes les méthodes sont asynchrones : GRDB exécute le SQL
/// hors du thread principal.
public final class TodoStore: Sendable {
    private let dbQueue: DatabaseQueue

    public init(dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue
        try Self.migrator.migrate(dbQueue)
    }

    public static func inMemory() throws -> TodoStore {
        try TodoStore(dbQueue: DatabaseQueue())
    }

    public static func onDisk(at url: URL) throws -> TodoStore {
        try TodoStore(dbQueue: DatabaseQueue(path: url.path))
    }

    /// Les migrations ne se modifient jamais après publication : on en ajoute une nouvelle.
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "todoItem") { t in
                t.column("id", .blob).notNull().primaryKey()
                t.column("title", .text).notNull()
                t.column("isDone", .boolean).notNull().defaults(to: false)
                t.column("createdAt", .datetime).notNull()
                t.column("dueDate", .datetime)
            }
        }

        migrator.registerMigration("v2") { db in
            try db.alter(table: "todoItem") { t in
                t.add(column: "notes", .text)
            }
        }

        return migrator
    }

    // MARK: - Écriture

    @discardableResult
    public func add(title: String) async throws -> TodoItem {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TodoError.emptyTitle }
        let item = TodoItem(title: trimmed)
        try await dbQueue.write { db in
            try item.insert(db)
        }
        return item
    }

    public func setDone(id: UUID, isDone: Bool) async throws {
        try await dbQueue.write { db in
            guard var item = try TodoItem.fetchOne(db, key: id) else {
                throw TodoError.notFound
            }
            item.isDone = isDone
            try item.update(db)
        }
    }

    public func delete(id: UUID) async throws {
        try await dbQueue.write { db in
            _ = try TodoItem.deleteOne(db, key: id)
        }
    }

    // MARK: - Lecture

    public func all() async throws -> [TodoItem] {
        try await dbQueue.read { db in
            try TodoItem.order(Column("createdAt")).fetchAll(db)
        }
    }

    /// Une séquence asynchrone : émet la liste actuelle, puis une nouvelle liste à chaque changement.
    public func observeAll() -> AsyncValueObservation<[TodoItem]> {
        ValueObservation
            .tracking { db in try TodoItem.order(Column("createdAt")).fetchAll(db) }
            .values(in: dbQueue)
    }
}
