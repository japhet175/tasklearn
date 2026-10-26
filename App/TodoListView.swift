import SwiftUI
import TaskCore

struct TodoListView: View {
    @State var viewModel: TodoListViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("New task", text: $viewModel.newTitle)
                            .onSubmit { Task { await viewModel.add() } }
                        Button("Add") { Task { await viewModel.add() } }
                            .disabled(viewModel.newTitle.isEmpty)
                    }
                }

                Section {
                    ForEach(viewModel.items) { item in
                        Button {
                            Task { await viewModel.toggle(item) }
                        } label: {
                            Label(
                                item.title,
                                systemImage: item.isDone ? "checkmark.circle.fill" : "circle"
                            )
                            .strikethrough(item.isDone)
                        }
                        .buttonStyle(.plain)
                        .accessibilityValue(item.isDone ? "Done" : "Not done")
                        .accessibilityHint("Double tap to change")
                    }
                    .onDelete { offsets in
                        Task { await viewModel.delete(at: offsets) }
                    }
                }
            }
            .navigationTitle("Tasks")
            .task { await viewModel.observe() }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}
