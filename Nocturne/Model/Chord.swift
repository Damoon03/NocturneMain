//
//  Chord.swift
//  Nocturne
//
//  Created by Damoon saber on 3/31/1405 AP.
//
//

import Foundation

struct Chord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var lineIndex: Int
    var wordIndex: Int
    var names: [String]   // e.g. ["Em"] or ["Em", "G"] for multi-chord on one word

    init(id: UUID = UUID(), lineIndex: Int, wordIndex: Int, names: [String]) {
        self.id = id
        self.lineIndex = lineIndex
        self.wordIndex = wordIndex
        self.names = names
    }

    /// Display text, e.g. "Em" or "Em/G"
    var displayText: String {
        names.joined(separator: "/")
    }
}
