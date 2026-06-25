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
    var notes: [SongNote] = []              // inline lyric notes (feature 4)
    var mainRecordingIDs: [UUID] = []       // feature 6: pinned "main" recordings
    var folderID: UUID? = nil               // feature 2: folder assignment
    var deletedAt: Date? = nil              // feature 8: soft delete

    init(
        id: UUID = UUID(),
        title: String = "Untitled",
        lyrics: String = "",
        sectionLabels: [SectionLabel] = [],
        recordings: [Recording] = [],
        chords: [Chord] = [],
        notes: [SongNote] = [],
        mainRecordingIDs: [UUID] = [],
        folderID: UUID? = nil,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.lyrics = lyrics
        self.sectionLabels = sectionLabels
        self.recordings = recordings
        self.chords = chords
        self.notes = notes
        self.mainRecordingIDs = mainRecordingIDs
        self.folderID = folderID
        self.deletedAt = deletedAt
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
