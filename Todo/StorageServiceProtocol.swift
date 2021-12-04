//
//  Persistence.swift
//  Todo
//
//  Created by Joshua Homann on 11/19/21.
//

import Foundation

protocol StorageServiceProtocol {
    var toDos: AsyncStream<[ToDo]> { get async }
    func create(toDo: ToDo) async throws
    func read(_ id: UUID) async throws -> ToDo?
    func update(toDo: ToDo) async throws
    func delete(id: UUID) async throws
}
