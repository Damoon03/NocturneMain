//
//  Fragment.swift
//  Nocturne
//
//  Created by Damoon saber on 3/30/1405 AP.
//


import Foundation

enum FragmentType: String, Codable, CaseIterable, Hashable {
    case lyric = "Lyric"
    case riff = "Riff"
    case title = "Title"
    case mood = "Mood"

    var icon: String {
        switch self {
        case .lyric: return "text.quote"
        case .riff: return "waveform"
        case .title: return "textformat"
        case .mood: return "cloud"
        }
    }

    var color: (r: Double, g: Double, b: Double) {
        switch self {
        case .lyric: return (0.4, 0.6, 1.0)
        case .riff:  return (0.6, 1.0, 0.7)
        case .title: return (1.0, 0.85, 0.4)
        case .mood:  return (0.8, 0.5, 1.0)
        }
    }
}

struct Fragment: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var text: String
    var type: FragmentType
    var createdAt: Date = Date()
    var attachedSongID: UUID? = nil
    var audioRecording: Recording? = nil
    var deletedAt: Date? = nil          // soft-delete timestamp

    var isDeleted: Bool { deletedAt != nil }

    init(
        id: UUID = UUID(),
        text: String,
        type: FragmentType,
        createdAt: Date = Date(),
        attachedSongID: UUID? = nil,
        audioRecording: Recording? = nil,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.text = text
        self.type = type
        self.createdAt = createdAt
        self.attachedSongID = attachedSongID
        self.audioRecording = audioRecording
        self.deletedAt = deletedAt
    }
}
