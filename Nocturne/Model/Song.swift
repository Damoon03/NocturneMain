//
//  Song.swift
//  Nocturne
//
//  Created by Damoon saber on 3/28/1405 AP.
//

import Foundation

struct SongNote: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var lineIndex: Int          // which line the note is attached to
    var text: String
    var createdAt: Date = Date()
}

struct Song: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var lyrics: String
    var sectionLabels: [SectionLabel] = []
    var recordings: [Recording] = []
    var chords: [Chord] = []
    var recentChords: [String] = []         // most-recently-used chord names, this song only
    var notes: [SongNote] = []              // inline lyric notes (feature 4)
    var mainRecordingIDs: [UUID] = []       // feature 6: pinned "main" recordings
    var folderID: UUID? = nil               // feature 2: folder assignment
    var deletedAt: Date? = nil              // feature 8: soft delete
    var updatedAt: Date = Date()            // bumped on every edit; drives library sort order

    init(
        id: UUID = UUID(),
        title: String = "Untitled",
        lyrics: String = "",
        sectionLabels: [SectionLabel] = [],
        recordings: [Recording] = [],
        chords: [Chord] = [],
        recentChords: [String] = [],
        notes: [SongNote] = [],
        mainRecordingIDs: [UUID] = [],
        folderID: UUID? = nil,
        deletedAt: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.lyrics = lyrics
        self.sectionLabels = sectionLabels
        self.recordings = recordings
        self.chords = chords
        self.recentChords = recentChords
        self.notes = notes
        self.mainRecordingIDs = mainRecordingIDs
        self.folderID = folderID
        self.deletedAt = deletedAt
        self.updatedAt = updatedAt
    }

    // Custom decoding so existing saved songs (from before `updatedAt` existed)
    // load fine instead of failing to decode — missing key just defaults to "now".
    enum CodingKeys: String, CodingKey {
        case id, title, lyrics, sectionLabels, recordings, chords, recentChords, notes, mainRecordingIDs, folderID, deletedAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? "Untitled"
        lyrics = try c.decodeIfPresent(String.self, forKey: .lyrics) ?? ""
        sectionLabels = try c.decodeIfPresent([SectionLabel].self, forKey: .sectionLabels) ?? []
        recordings = try c.decodeIfPresent([Recording].self, forKey: .recordings) ?? []
        chords = try c.decodeIfPresent([Chord].self, forKey: .chords) ?? []
        recentChords = try c.decodeIfPresent([String].self, forKey: .recentChords) ?? []
        notes = try c.decodeIfPresent([SongNote].self, forKey: .notes) ?? []
        mainRecordingIDs = try c.decodeIfPresent([UUID].self, forKey: .mainRecordingIDs) ?? []
        folderID = try c.decodeIfPresent(UUID.self, forKey: .folderID)
        deletedAt = try c.decodeIfPresent(Date.self, forKey: .deletedAt)
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(lyrics, forKey: .lyrics)
        try c.encode(sectionLabels, forKey: .sectionLabels)
        try c.encode(recordings, forKey: .recordings)
        try c.encode(chords, forKey: .chords)
        try c.encode(recentChords, forKey: .recentChords)
        try c.encode(notes, forKey: .notes)
        try c.encode(mainRecordingIDs, forKey: .mainRecordingIDs)
        try c.encodeIfPresent(folderID, forKey: .folderID)
        try c.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try c.encode(updatedAt, forKey: .updatedAt)
    }

    var mainRecordings: [Recording] {
        mainRecordingIDs.compactMap { rid in recordings.first { $0.id == rid } }
    }

    var isDeleted: Bool { deletedAt != nil }
}

// MARK: - Folder model
struct SongFolder: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
}
