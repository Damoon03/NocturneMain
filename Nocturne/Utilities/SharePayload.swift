//
//  SharePayload.swift
//  Nocturne
//
//  Created by Damoon saber on 4/4/1405 AP.
//

import Foundation

struct SharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

struct NoteEditContext: Identifiable {
    let lineIndex: Int
    var id: Int { lineIndex }
}

struct LyricLineItem: Identifiable {
    let id: String
    let index: Int
}

struct LyricWordItem: Identifiable {
    let id: String
    let index: Int
    let word: String
}
