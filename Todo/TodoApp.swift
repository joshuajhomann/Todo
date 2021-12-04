//
//  TodoApp.swift
//  Todo
//
//  Created by Joshua Homann on 11/19/21.
//

import SwiftUI

@main
struct TodoApp: App {
    @Environment(\.storageService) private var storageService: StorageServiceProtocol
    var body: some Scene {
        WindowGroup {
            ListView(viewModel: .init(storageService: storageService))
        }
    }
}

extension EnvironmentValues {
    private struct StorageServiceKey: EnvironmentKey {
        static let defaultValue = StorageService()
    }
    var storageService: StorageServiceProtocol {
        StorageServiceKey.defaultValue
    }
}
