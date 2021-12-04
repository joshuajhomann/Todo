//
//  ContentView.swift
//  Todo
//
//  Created by Joshua Homann on 11/19/21.
//

import SwiftUI
import CoreData

@MainActor
final class ToDoListViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var selectedToDo: ToDo?
    struct Item: Identifiable, Hashable {
        var id: UUID {
            toDo.id
        }
        var toDo: ToDo
        var isCompleted: Bool {
            toDo.completed != nil
        }
        var delete: () -> Void
        var toggleCompleted: () -> Void
        func hash(into hasher: inout Hasher) {
            hasher.combine(toDo)
        }
        static func == (lhs: ToDoListViewModel.Item, rhs: ToDoListViewModel.Item) -> Bool {
            lhs.toDo == rhs.toDo
        }
    }
    private(set) var subscribe: () async -> Void = { }
    private(set) var add: () -> Void = { }
    init(
        storageService: StorageServiceProtocol
    ) {
        add = { [weak self] in
            Task { [weak self] in
                let id = UUID()
                try? await storageService.create(toDo: .init(
                    id: id,
                    created: .now,
                    title: "New Item",
                    subtitle: "Created \(Date.now.formatted())",
                    completed: nil)
                )
                self?.selectedToDo = try await storageService.read(id)
            }
        }
        subscribe = { [weak self] in
            let itemStream = await storageService.toDos.map { toDos in
                toDos.map { toDo in
                    Item(
                        toDo: toDo,
                        delete: {
                            Task {
                                try await storageService.delete(id: toDo.id)
                            }
                        },
                        toggleCompleted: {
                            Task {
                                guard var toDo = try await storageService.read(toDo.id) else { return }
                                toDo.completed = toDo.completed == nil
                                ? Date.now
                                : nil
                                try await storageService.update(toDo: toDo)
                            }
                        }
                    )
                }
            }
            for await items in itemStream {
                self?.items = items
            }
        }
    }

}

struct ListView: View {
    @Environment(\.storageService) private var storageService: StorageServiceProtocol
    @StateObject var viewModel: ToDoListViewModel

    var body: some View {
        NavigationView {
            List($viewModel.items) { $item in
                VStack(alignment: .leading) {
                    Text(item.toDo.title).strikethrough(item.isCompleted, color: .gray)
                    Text(item.toDo.subtitle).foregroundColor(.secondary).strikethrough(item.isCompleted, color: .gray)
                }
                .onTapGesture {
                    viewModel.selectedToDo = item.toDo
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    item.isCompleted
                    ? Button(action: item.toggleCompleted) { Label("Incomplete", systemImage: "circle") }.tint(.yellow)
                    : Button(action: item.toggleCompleted) { Label("Complete", systemImage: "checkmark.circle") }.tint(.green)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(action: item.delete) { Label("Delete", systemImage: "trash") }.tint(.red)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { viewModel.add() }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("To Do List")
        }
        .navigationViewStyle(.stack)
        .task {
            await viewModel.subscribe()
        }
        .sheet(item: $viewModel.selectedToDo) { toDo in
            DetailView(viewModel: .init(toDo: toDo, storageService: storageService))
        }
    }
}
