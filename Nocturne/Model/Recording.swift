//
//  Recording.swift
//  Nocturne
//
//  Created by Damoon saber on 3/28/1405 AP.
//

import Foundation

enum RecordingKind: String, Codable, Hashable {
    case audio
    case video
}

struct Recording: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var fileName: String
    var createdAt: Date
    var duration: TimeInterval
    var kind: RecordingKind = .audio   // backward-compatible default

    var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
}

extension URL {
    var isReachable: Bool {
        (try? checkResourceIsReachable()) ?? false
    }
}
