//
//  DetailView.swift
//  Todo
//
//  Created by Joshua Homann on 11/28/21.
//

import SwiftUI

@MainActor
final class DetailViewModel: ObservableObject {
    @Published var toDo: ToDo
    @Published var isComplete: Bool
    private(set) var save: () async throws -> Void = { }
    init(
        toDo: ToDo,
        storageService: StorageServiceProtocol
    ) {
        self.toDo = toDo
        isComplete = toDo.completed != nil
        $isComplete
            .dropFirst()
            .compactMap { [weak self] isComplete in
                guard var copy = self?.toDo else { return nil }
                copy.completed = isComplete ? Date.now : nil
                return copy
            }
            .assign(to: &$toDo)
        save = { [weak self] in
            guard let toDo = self?.toDo else { return }
            try await storageService.update(toDo: toDo)
        }
    }
}

struct DetailView: View {
    @StateObject var viewModel: DetailViewModel
    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var isFocused: Bool
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                TextField("Title", text: $viewModel.toDo.title, prompt: Text("Enter a title"))
                    .focused($isFocused)
                TextField("Subtitle", text: $viewModel.toDo.subtitle, prompt: Text("Enter a subtitle"))
                Toggle("Completed", isOn: $viewModel.isComplete)
                    .toggleStyle(.button)
                Spacer()
            }
            .task {
                await Task.sleep(UInt64(0.25e9))
                isFocused = true
            }
            .textFieldStyle(.roundedBorder)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            try? await viewModel.save()
                            presentationMode.wrappedValue.dismiss()
                        }
                    } label: {
                        Text("Done")
                    }
                }
            }
            .navigationTitle("Edit To Do")
            .padding()
        }
    }
}
