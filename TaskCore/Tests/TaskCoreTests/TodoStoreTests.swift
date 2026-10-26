import Foundation
import GRDB
import Testing
@testable import TaskCore

@Suite struct TodoStoreTests {
    @Test func addTrimsTitleAndStoresIt() async throws {
        let store = try TodoStore.inMemory()
        let item = try await store.add(title: "  Buy milk  ")
        let all = try await store.all()
        #expect(item.title == "Buy milk")
        #expect(all.count == 1)
        #expect(all.first?.id == item.id)
    }

    @Test func emptyTitleIsRejected() async throws {
        let store = try TodoStore.inMemory()
        await #expect(throws: TodoError.emptyTitle) {
            try await store.add(title: "   ")
        }
        let all = try await store.all()
        #expect(all.isEmpty)
    }

    @Test func setDoneUpdatesTheItem() async throws {
        let store = try TodoStore.inMemory()
        let item = try await store.add(title: "Write tests")
        try await store.setDone(id: item.id, isDone: true)
        let all = try await store.all()
        #expect(all.first?.isDone == true)
    }

    @Test func setDoneOnUnknownIdThrows() async throws {
        let store = try TodoStore.inMemory()
        await #expect(throws: TodoError.notFound) {
            try await store.setDone(id: UUID(), isDone: true)
        }
    }

    @Test func deleteRemovesOnlyThatItem() async throws {
        let store = try TodoStore.inMemory()
        let a = try await store.add(title: "A")
        _ = try await store.add(title: "B")
        try await store.delete(id: a.id)
        let all = try await store.all()
        #expect(all.map(\.title) == ["B"])
    }

    @Test func itemsComeBackInCreationOrder() async throws {
        let store = try TodoStore.inMemory()
        _ = try await store.add(title: "first")
        try await Task.sleep(for: .milliseconds(5))
        _ = try await store.add(title: "second")
        let all = try await store.all()
        #expect(all.map(\.title) == ["first", "second"])
    }

    /// Le test qui compte le plus pour une vraie app : les données d'un utilisateur
    /// existant survivent à une nouvelle migration.
    @Test func migrationKeepsExistingRows() throws {
        let dbQueue = try DatabaseQueue()
        let migrator = TodoStore.migrator

        try migrator.migrate(dbQueue, upTo: "v1")
        try dbQueue.write { db in
            try db.execute(
                sql: "INSERT INTO todoItem (id, title, isDone, createdAt) VALUES (?, ?, 0, ?)",
                arguments: [UUID(), "old task", Date()]
            )
        }

        try migrator.migrate(dbQueue)

        let items = try dbQueue.read { db in try TodoItem.fetchAll(db) }
        #expect(items.count == 1)
        #expect(items.first?.title == "old task")
        #expect(items.first?.notes == nil)
    }

    @Test func observationEmitsAfterEachChange() async throws {
        let store = try TodoStore.inMemory()
        var iterator = store.observeAll().makeAsyncIterator()

        let first = try await iterator.next()
        #expect(first?.isEmpty == true)

        _ = try await store.add(title: "A")
        let second = try await iterator.next()
        #expect(second?.count == 1)
    }
}
