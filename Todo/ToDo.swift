//
//  ToDo.swift
//  Todo
//
//  Created by Joshua Homann on 12/4/21.
//

import Foundation

struct ToDo: Hashable, Identifiable {
    var id: UUID
    var created: Date
    var title: String
    var subtitle: String
    var completed: Date?
}
