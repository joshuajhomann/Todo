//
//  StorageService.swift
//  Todo
//
//  Created by Joshua Homann on 12/4/21.
//

import CoreData

actor StorageService: StorageServiceProtocol {

    private let container: NSPersistentContainer
    private let delegate: Delegate
    private let context: NSManagedObjectContext
    var toDos: AsyncStream<[ToDo]> {
        get async { delegate.values }
    }
    init() {
        container = NSPersistentCloudKitContainer(name: "ManagedToDo")
        container.loadPersistentStores { storeDescription, error in
            print(storeDescription, String(describing: error))
        }
        context = container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        delegate = .init(context: context)
    }

    func create(toDo: ToDo) async throws {
        _ = ManagedToDo(toDo: toDo, context: context)
        try context.save()
    }

    func read(_ id: UUID) async throws -> ToDo? {
        try fetch(by: id).map(ToDo.init(from:))
    }

    func update(toDo: ToDo) async throws {
        guard let toUpdate = try fetch(by: toDo.id) else { return }
        toUpdate.update(from: toDo)
        try context.save()
    }

    func delete(id: UUID) async throws {
        guard let toDelete = try fetch(by: id) else { return }
        context.delete(toDelete)
        try context.save()
    }

    private func fetch(by id: UUID) throws -> ManagedToDo? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedToDo.description())
        let sort = NSSortDescriptor(key: "id", ascending: false)
        request.sortDescriptors = [sort]
        request.predicate = NSPredicate(format: "id = %@", id as NSUUID)
        guard let found = try context.fetch(request).first as? ManagedToDo else { return nil }
        return found
    }

    private final class Delegate: NSObject, NSFetchedResultsControllerDelegate {
        let values: AsyncStream<[ToDo]>
        let controller:  NSFetchedResultsController<NSFetchRequestResult>
        private let input: ([ToDo]) -> ()
        init(context: NSManagedObjectContext) {
            (input, values) = AsyncStream<[ToDo]>.pipe()
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedToDo.description())
            let sort = NSSortDescriptor(key: "created", ascending: false)
            request.sortDescriptors = [sort]
            controller = NSFetchedResultsController<NSFetchRequestResult>(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            super.init()
            controller.delegate = self
            try? controller.performFetch()
            controllerDidChangeContent(controller)
        }
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            guard let todos = controller
                    .fetchedObjects?
                    .compactMap({ $0 as? ManagedToDo })
                    .map(ToDo.init(from:)) else { return }
            input(todos)
        }
    }

}


private extension ManagedToDo {
    convenience init(toDo: ToDo, context: NSManagedObjectContext) {
        self.init(context: context)
        id = toDo.id
        update(from: toDo)
    }
    func update(from todo: ToDo) {
        created = todo.created
        title = todo.title
        subtitle = todo.subtitle
        completed = todo.completed
    }
}

private extension ToDo {
    init(from managedToDo: ManagedToDo) {
        id = managedToDo.id  ?? .init()
        created = managedToDo.created ?? .now
        title = managedToDo.title ?? ""
        subtitle = managedToDo.subtitle ?? ""
        completed = managedToDo.completed
    }
}
