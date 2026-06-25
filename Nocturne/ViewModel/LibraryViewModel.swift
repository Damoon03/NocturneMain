//
//  LibraryViewModel.swift
//  Nocturne
//
//  Created by Damoon saber on 3/28/1405 AP.
//

import Foundation
import Combine
import SwiftUI

class LibraryViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var folders: [SongFolder] = []

    private let songsKey  = "nocturne_songs"
    private let foldersKey = "nocturne_folders"

    /// Songs visible in the main library (not deleted, not in any folder when
    /// folderID == nil, or matching a specific folder).
    func songs(inFolder folderID: UUID?) -> [Song] {
        songs.filter { !$0.isDeleted && $0.folderID == folderID }
    }

    /// Recently-deleted songs, sorted most-recent first.
    var recentlyDeleted: [Song] {
        songs.filter { $0.isDeleted }.sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
    }

    init() {
        load()
        purgeExpiredDeletes()
        if songs.filter({ !$0.isDeleted }).isEmpty {
            let s = Song(title: "Untitled", lyrics: "")
            songs.insert(s, at: 0)
            save()
        }
    }

    // MARK: - CRUD

    func newSong(inFolder folderID: UUID? = nil) -> Song {
        var song = Song(title: "Untitled", lyrics: "")
        song.folderID = folderID
        songs.insert(song, at: 0)
        save()
        return song
    }

    func update(_ song: Song) {
        if let index = songs.firstIndex(where: { $0.id == song.id }) {
            songs[index] = song
            save()
        }
    }

    /// Soft-delete: mark with deletedAt; purged after 30 days.
    func softDelete(_ song: Song) {
        if let index = songs.firstIndex(where: { $0.id == song.id }) {
            songs[index].deletedAt = Date()
            save()
        }
    }

    /// Permanently removes a song and its audio files.
    func permanentlyDelete(_ song: Song) {
        for rec in song.recordings {
            try? FileManager.default.removeItem(at: rec.fileURL)
        }
        songs.removeAll { $0.id == song.id }
        save()
    }

    /// Restore from recently-deleted.
    func restore(_ song: Song) {
        if let index = songs.firstIndex(where: { $0.id == song.id }) {
            songs[index].deletedAt = nil
            save()
        }
    }

    func move(from source: IndexSet, to destination: Int, inFolder folderID: UUID?) {
        // Reorder only within the visible subset, then apply order back to main array
        var subset = songs(inFolder: folderID)
        subset.move(fromOffsets: source, toOffset: destination)
        // Rebuild full array: replace visible subset positions in order
        var subsetIter = subset.makeIterator()
        songs = songs.map { song in
            (!song.isDeleted && song.folderID == folderID) ? subsetIter.next() ?? song : song
        }
        save()
    }

    // Legacy delete(at:) kept for compatibility — now routes to softDelete
    func delete(at offsets: IndexSet, inFolder folderID: UUID? = nil) {
        let subset = songs(inFolder: folderID)
        for index in offsets {
            guard index < subset.count else { continue }
            softDelete(subset[index])
        }
    }

    // MARK: - Folders

    func createFolder(name: String) -> SongFolder {
        let folder = SongFolder(name: name)
        folders.append(folder)
        saveFolders()
        return folder
    }

    func renameFolder(_ folder: SongFolder, to name: String) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index].name = name
            saveFolders()
        }
    }

    func deleteFolder(_ folder: SongFolder) {
        // Move songs in this folder back to root
        for i in 0..<songs.count {
            if songs[i].folderID == folder.id {
                songs[i].folderID = nil
            }
        }
        folders.removeAll { $0.id == folder.id }
        saveFolders()
        save()
    }

    func moveSong(_ song: Song, toFolder folderID: UUID?) {
        if let index = songs.firstIndex(where: { $0.id == song.id }) {
            songs[index].folderID = folderID
            save()
        }
    }

    // MARK: - Private

    /// Auto-purge songs deleted more than 30 days ago.
    private func purgeExpiredDeletes() {
        let cutoff = Date().addingTimeInterval(-30 * 24 * 3600)
        let toDelete = songs.filter { $0.isDeleted && ($0.deletedAt ?? .distantFuture) < cutoff }
        toDelete.forEach { permanentlyDelete($0) }
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(songs) {
            UserDefaults.standard.set(encoded, forKey: songsKey)
        }
    }

    private func saveFolders() {
        if let encoded = try? JSONEncoder().encode(folders) {
            UserDefaults.standard.set(encoded, forKey: foldersKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: songsKey),
           let decoded = try? JSONDecoder().decode([Song].self, from: data) {
            songs = decoded
        }
        if let data = UserDefaults.standard.data(forKey: foldersKey),
           let decoded = try? JSONDecoder().decode([SongFolder].self, from: data) {
            folders = decoded
        }
    }
}
