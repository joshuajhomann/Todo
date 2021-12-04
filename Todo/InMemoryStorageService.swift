//
//  InMemroyStorageService.swift
//  Todo
//
//  Created by Joshua Homann on 12/4/21.
//

import Foundation

actor InMemoryStorageService: StorageServiceProtocol {
    var toDos: AsyncStream<[ToDo]> {
        get async {
            values
        }
    }
    private let (input, values) = AsyncStream<[ToDo]>.pipe()
    private var value: [ToDo] = [] {
        didSet {
            input(value)
        }
    }
    func create(toDo: ToDo) async throws {
        guard index(with: toDo.id) == nil else { return }
        value.append(toDo)
    }

    func read(_ id: UUID) async throws -> ToDo? {
        index(with: id).map { value[$0] }
    }

    func update(toDo: ToDo) async throws {
        guard let index = index(with: toDo.id) else { return }
        value[index] = toDo
    }

    func delete(id: UUID) async throws {
        guard let index = index(with: id) else { return }
        value.remove(at: index)
    }

    private func index(with id: UUID) -> Int? {
        value.firstIndex(where: { $0.id == id })
    }

}
