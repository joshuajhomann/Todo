//
//  AsyncStream+Pipe.swift
//  Todo
//
//  Created by Joshua Homann on 12/4/21.
//

import Foundation

extension AsyncStream {
    static func pipe() -> ((Element) -> Void, Self) {
        var input: (Element) -> Void = { _ in }
        let output = Self { continuation in
            input = { element in
                continuation.yield(element)
            }
        }
        return (input, output)
    }
}
