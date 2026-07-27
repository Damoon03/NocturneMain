//
//  FragmentViewModel.swift
//  Nocturne
//
//  Created by Damoon saber on 3/30/1405 AP.
//

import Foundation
import Combine

@MainActor
class FragmentsViewModel: ObservableObject {
    @Published var fragments: [Fragment] = []
    @Published var filterType: FragmentType? = nil
    @Published var lastSaveError: String?

    private let saveKey = "nocturne_fragments"
    private let fragmentsFile = "fragments.json"

    var activeCount: Int { fragments.filter { !$0.isDeleted }.count }

    init() {
        load()
        purgeExpiredDeletes()
    }

    // MARK: - Live fragments (not deleted)
    var filteredFragments: [Fragment] {
        let sorted = fragments.filter { !$0.isDeleted }.sorted { $0.createdAt > $1.createdAt }
        guard let filterType else { return sorted }
        return sorted.filter { $0.type == filterType }
    }

    // MARK: - Recently deleted
    var recentlyDeleted: [Fragment] {
        fragments.filter { $0.isDeleted }.sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
    }

    // MARK: - Add
    func add(text: String, type: FragmentType) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        fragments.insert(Fragment(text: text, type: type), at: 0)
        save()
    }

    func addRiff(recording: Recording, name: String = "") {
        let fragment = Fragment(
            text: name.trimmingCharacters(in: .whitespacesAndNewlines),
            type: .riff,
            audioRecording: recording
        )
        fragments.insert(fragment, at: 0)
        save()
    }

    // MARK: - Edit
    func update(_ fragment: Fragment) {
        if let index = fragments.firstIndex(where: { $0.id == fragment.id }) {
            fragments[index] = fragment
            save()
        }
    }

    func updateText(_ fragment: Fragment, text: String) {
        if let index = fragments.firstIndex(where: { $0.id == fragment.id }) {
            fragments[index].text = text
            save()
        }
    }

    func updateType(_ fragment: Fragment, type: FragmentType) {
        if let index = fragments.firstIndex(where: { $0.id == fragment.id }) {
            fragments[index].type = type
            save()
        }
    }

    // MARK: - Soft delete
    func delete(_ fragment: Fragment) {
        if let index = fragments.firstIndex(where: { $0.id == fragment.id }) {
            fragments[index].deletedAt = Date()
            save()
        }
    }

    func delete(at offsets: IndexSet, in list: [Fragment]) {
        for index in offsets {
            let fragment = list[index]
            if let i = fragments.firstIndex(where: { $0.id == fragment.id }) {
                fragments[i].deletedAt = Date()
            }
        }
        save()
    }

    // MARK: - Restore
    func restore(_ fragment: Fragment) {
        if let index = fragments.firstIndex(where: { $0.id == fragment.id }) {
            fragments[index].deletedAt = nil
            save()
        }
    }

    // MARK: - Permanent delete
    func permanentlyDelete(_ fragment: Fragment) {
        if let recording = fragment.audioRecording {
            try? FileManager.default.removeItem(at: recording.fileURL)
        }
        fragments.removeAll { $0.id == fragment.id }
        save()
    }

    // MARK: - Attach / detach
    func attach(_ fragment: Fragment, toSongID songID: UUID) {
        guard let index = fragments.firstIndex(where: { $0.id == fragment.id }) else { return }
        fragments[index].attachedSongID = songID
        save()
    }

    func detach(_ fragment: Fragment) {
        guard let index = fragments.firstIndex(where: { $0.id == fragment.id }) else { return }
        fragments[index].attachedSongID = nil
        save()
    }

    func fragments(forSongID songID: UUID) -> [Fragment] {
        fragments
            .filter { !$0.isDeleted && $0.attachedSongID == songID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Purge expired (30 days)
    private func purgeExpiredDeletes() {
        let cutoff = Date().addingTimeInterval(-30 * 24 * 3600)
        let toDelete = fragments.filter { $0.isDeleted && ($0.deletedAt ?? .distantFuture) < cutoff }
        toDelete.forEach { permanentlyDelete($0) }
    }

    // MARK: - Persistence
    private func save() {
        let snapshot = fragments
        let file = fragmentsFile
        Task {
            do {
                try await Task.detached(priority: .utility) {
                    try DataPersistence.save(snapshot, to: file)
                }.value
                lastSaveError = nil
            } catch {
                lastSaveError = error.localizedDescription
            }
        }
    }

    private func load() {
        if let decoded: [Fragment] = DataPersistence.loadOrMigrate(
            userDefaultsKey: saveKey,
            filename: fragmentsFile
        ) {
            fragments = decoded
        }
    }
}
