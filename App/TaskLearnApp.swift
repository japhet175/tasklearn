import SwiftUI
import TaskCore

@main
struct TaskLearnApp: App {
    private let store: TodoStore

    init() {
        do {
            let folder = URL.applicationSupportDirectory
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            store = try TodoStore.onDisk(at: folder.appending(path: "tasks.sqlite"))
        } catch {
            // Acceptable pour une démo ; une vraie app afficherait un écran de récupération.
            fatalError("Could not open the database: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            TodoListView(viewModel: TodoListViewModel(store: store))
        }
    }
}
