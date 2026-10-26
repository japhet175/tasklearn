import Observation
import SwiftUI
import TaskCore

/// Toute la logique de l'écran. Isolé sur le thread principal car il alimente l'interface.
@MainActor
@Observable
final class TodoListViewModel {
    private(set) var items: [TodoItem] = []
    var newTitle = ""
    var errorMessage: String?

    private let store: TodoStore

    init(store: TodoStore) {
        self.store = store
    }

    /// Appelée par `.task` : s'arrête toute seule quand la vue disparaît.
    func observe() async {
        do {
            for try await latest in store.observeAll() {
                items = latest
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func add() async {
        do {
            try await store.add(title: newTitle)
            newTitle = ""
        } catch TodoError.emptyTitle {
            errorMessage = "Write a title first."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggle(_ item: TodoItem) async {
        do {
            try await store.setDone(id: item.id, isDone: !item.isDone)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(at offsets: IndexSet) async {
        let ids = offsets.map { items[$0].id }
        do {
            for id in ids {
                try await store.delete(id: id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
