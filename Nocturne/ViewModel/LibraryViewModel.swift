//
//  LibraryViewModel.swift
//  Nocturne
//

import Foundation
import Combine
import SwiftUI

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var folders: [SongFolder] = []
    @Published var lastSaveError: String?

    private let songsKey = "nocturne_songs"
    private let foldersKey = "nocturne_folders"
    private let songsFile = "songs.json"
    private let foldersFile = "folders.json"

    var activeSongCount: Int { songs.filter { !$0.isDeleted }.count }

    func songs(inFolder folderID: UUID?) -> [Song] {
        songs.filter { !$0.isDeleted && $0.folderID == folderID }
    }

    var recentlyDeleted: [Song] {
        songs.filter { $0.isDeleted }.sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
    }

    init() {
        load()
        purgeExpiredDeletes()
        ensureDefaultSongIfNeeded()
    }

    private func ensureDefaultSongIfNeeded() {
        guard songs.filter({ !$0.isDeleted }).isEmpty else { return }
        songs.insert(Song(title: "Untitled", lyrics: ""), at: 0)
        Task { _ = await saveSongs() }
    }

    // MARK: - CRUD

    func newSong(inFolder folderID: UUID? = nil) -> Song {
        var song = Song(title: "Untitled", lyrics: "")
        song.folderID = folderID
        songs.insert(song, at: 0)
        Task { _ = await saveSongs() }
        return song
    }

    @discardableResult
    func update(_ song: Song) async -> Bool {
        guard let index = songs.firstIndex(where: { $0.id == song.id }) else { return false }
        var updatedSong = song
        updatedSong.updatedAt = Date()
        songs.remove(at: index)
        songs.insert(updatedSong, at: 0)
        return await saveSongs()
    }

    func softDelete(_ song: Song) {
        if let index = songs.firstIndex(where: { $0.id == song.id }) {
            songs[index].deletedAt = Date()
            Task { _ = await saveSongs() }
        }
    }

    func permanentlyDelete(_ song: Song) {
        for rec in song.recordings {
            try? FileManager.default.removeItem(at: rec.fileURL)
        }
        songs.removeAll { $0.id == song.id }
        Task { _ = await saveSongs() }
    }

    func restore(_ song: Song) {
        if let index = songs.firstIndex(where: { $0.id == song.id }) {
            songs[index].deletedAt = nil
            Task { _ = await saveSongs() }
        }
    }

    func move(from source: IndexSet, to destination: Int, inFolder folderID: UUID?) {
        var subset = songs(inFolder: folderID)
        subset.move(fromOffsets: source, toOffset: destination)
        var subsetIter = subset.makeIterator()
        songs = songs.map { song in
            (!song.isDeleted && song.folderID == folderID) ? subsetIter.next() ?? song : song
        }
        Task { _ = await saveSongs() }
    }

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
        Task { _ = await saveFolders() }
        return folder
    }

    func renameFolder(_ folder: SongFolder, to name: String) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index].name = name
            Task { _ = await saveFolders() }
        }
    }

    func deleteFolder(_ folder: SongFolder) {
        for i in 0..<songs.count where songs[i].folderID == folder.id {
            songs[i].folderID = nil
        }
        folders.removeAll { $0.id == folder.id }
        Task {
            _ = await saveFolders()
            _ = await saveSongs()
        }
    }

    func moveSong(_ song: Song, toFolder folderID: UUID?) {
        if let index = songs.firstIndex(where: { $0.id == song.id }) {
            songs[index].folderID = folderID
            Task { _ = await saveSongs() }
        }
    }

    // MARK: - Private

    private func purgeExpiredDeletes() {
        let cutoff = Date().addingTimeInterval(-30 * 24 * 3600)
        let toDelete = songs.filter { $0.isDeleted && ($0.deletedAt ?? .distantFuture) < cutoff }
        toDelete.forEach { permanentlyDelete($0) }
    }

    @discardableResult
    private func saveSongs() async -> Bool {
        let snapshot = songs
        let file = songsFile
        do {
            try await Task.detached(priority: .utility) {
                try DataPersistence.save(snapshot, to: file)
            }.value
            lastSaveError = nil
            return true
        } catch {
            lastSaveError = error.localizedDescription
            return false
        }
    }

    @discardableResult
    private func saveFolders() async -> Bool {
        let snapshot = folders
        let file = foldersFile
        do {
            try await Task.detached(priority: .utility) {
                try DataPersistence.save(snapshot, to: file)
            }.value
            lastSaveError = nil
            return true
        } catch {
            lastSaveError = error.localizedDescription
            return false
        }
    }

    private func load() {
        if let decoded: [Song] = DataPersistence.loadOrMigrate(
            userDefaultsKey: songsKey,
            filename: songsFile
        ) {
            songs = decoded
        }
        if let decoded: [SongFolder] = DataPersistence.loadOrMigrate(
            userDefaultsKey: foldersKey,
            filename: foldersFile
        ) {
            folders = decoded
        }
    }
}
