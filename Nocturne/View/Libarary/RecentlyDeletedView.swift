//
//  RecentlyDeletedView.swift
//  Nocturne
//

import SwiftUI

struct RecentlyDeletedView: View {
    @ObservedObject var libraryVM: LibraryViewModel
    @ObservedObject var fragmentsVM: FragmentsViewModel
    @State private var songToNuke: Song? = nil
    @State private var fragmentToNuke: Fragment? = nil
    @State private var showNukeSongConfirm = false
    @State private var showNukeFragmentConfirm = false
    @State private var showEmptyConfirm = false

    private var deletedSongs: [Song] { libraryVM.recentlyDeleted }
    private var deletedFragments: [Fragment] { fragmentsVM.recentlyDeleted }
    private var totalCount: Int { deletedSongs.count + deletedFragments.count }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "trash").font(.system(size: 13, weight: .light)).foregroundStyle(.white.opacity(0.4))
                    Text("Recently Deleted").foregroundStyle(.white.opacity(0.85)).font(.system(size: 15, weight: .medium))
                    Spacer()
                    if totalCount > 0 {
                        Button("Empty All") { showEmptyConfirm = true }
                            .font(.system(size: 13)).foregroundStyle(.red.opacity(0.6))
                    }
                }
                .padding(.horizontal, 28).padding(.vertical, 20)

                Text("Items are permanently deleted after 30 days.")
                    .foregroundStyle(.white.opacity(0.2)).font(.system(size: 11, weight: .light))
                    .padding(.horizontal, 28).padding(.bottom, 14)

                if totalCount == 0 {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "trash").font(.system(size: 32, weight: .ultraLight)).foregroundStyle(.white.opacity(0.1))
                        Text("Nothing deleted recently").foregroundStyle(.white.opacity(0.2)).font(.system(size: 14, weight: .light))
                    }
                    Spacer()
                } else {
                    List {
                        if !deletedSongs.isEmpty {
                            Section {
                                ForEach(deletedSongs) { song in
                                    deletedSongRow(song)
                                        .listRowBackground(Color.clear)
                                        .listRowSeparatorTint(.white.opacity(0.06))
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                songToNuke = song; showNukeSongConfirm = true
                                            } label: { Label("Delete Forever", systemImage: "trash.fill") }.tint(.red)
                                        }
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            Button { libraryVM.restore(song) } label: { Label("Restore", systemImage: "arrow.uturn.backward") }.tint(.green)
                                        }
                                }
                            } header: { sectionHeader(icon: "music.note", label: "Songs", count: deletedSongs.count) }
                        }

                        if !deletedFragments.isEmpty {
                            Section {
                                ForEach(deletedFragments) { fragment in
                                    deletedFragmentRow(fragment)
                                        .listRowBackground(Color.clear)
                                        .listRowSeparatorTint(.white.opacity(0.06))
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                fragmentToNuke = fragment; showNukeFragmentConfirm = true
                                            } label: { Label("Delete Forever", systemImage: "trash.fill") }.tint(.red)
                                        }
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            Button { fragmentsVM.restore(fragment) } label: { Label("Restore", systemImage: "arrow.uturn.backward") }.tint(.green)
                                        }
                                }
                            } header: { sectionHeader(icon: "lightbulb", label: "Fragments", count: deletedFragments.count) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showNukeSongConfirm) {
            if let song = songToNuke {
                PermanentDeleteSheet(
                    title: song.title.isEmpty ? "Untitled" : song.title,
                    subtitle: "This song will be permanently deleted and cannot be recovered.",
                    confirmLabel: "Delete Forever",
                    onDelete: { libraryVM.permanentlyDelete(song); showNukeSongConfirm = false; songToNuke = nil },
                    onCancel: { showNukeSongConfirm = false; songToNuke = nil }
                )
            }
        }
        .sheet(isPresented: $showNukeFragmentConfirm) {
            if let fragment = fragmentToNuke {
                PermanentDeleteSheet(
                    title: fragment.text.isEmpty ? fragment.type.rawValue : String(fragment.text.prefix(40)),
                    subtitle: "This fragment will be permanently deleted and cannot be recovered.",
                    confirmLabel: "Delete Forever",
                    onDelete: { fragmentsVM.permanentlyDelete(fragment); showNukeFragmentConfirm = false; fragmentToNuke = nil },
                    onCancel: { showNukeFragmentConfirm = false; fragmentToNuke = nil }
                )
            }
        }
        .sheet(isPresented: $showEmptyConfirm) {
            PermanentDeleteSheet(
                title: "Empty Recently Deleted",
                subtitle: "All \(totalCount) item\(totalCount == 1 ? "" : "s") will be permanently deleted and cannot be recovered.",
                confirmLabel: "Delete All",
                onDelete: {
                    deletedSongs.forEach { libraryVM.permanentlyDelete($0) }
                    deletedFragments.forEach { fragmentsVM.permanentlyDelete($0) }
                    showEmptyConfirm = false
                },
                onCancel: { showEmptyConfirm = false }
            )
        }
    }

    private func sectionHeader(icon: String, label: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.3))
            Text(label.uppercased()).font(.system(size: 9, weight: .semibold, design: .monospaced)).kerning(1.5).foregroundStyle(.white.opacity(0.3))
            Text("\(count)").font(.system(size: 9, design: .monospaced)).foregroundStyle(.white.opacity(0.2))
            Spacer()
        }
        .padding(.horizontal, 28).padding(.top, 8).padding(.bottom, 4)
        .listRowInsets(EdgeInsets())
        .background(Color.black)
    }

    private func deletedSongRow(_ song: Song) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)).frame(width: 40, height: 40)
                Image(systemName: "music.note").font(.system(size: 14, weight: .light)).foregroundStyle(.white.opacity(0.2))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(song.title.isEmpty ? "Untitled" : song.title)
                    .foregroundStyle(.white.opacity(0.5)).font(.system(size: 15, weight: .regular))
                if let d = song.deletedAt {
                    let days = max(0, 30 - Int(Date().timeIntervalSince(d) / 86400))
                    Text("\(days) day\(days == 1 ? "" : "s") remaining")
                        .foregroundStyle(.white.opacity(0.2)).font(.system(size: 11, design: .monospaced))
                }
            }
            Spacer()
            Button(action: { libraryVM.restore(song) }) {
                Text("Restore").font(.system(size: 12)).foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.06)).overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5)))
            }
        }
        .padding(.vertical, 4)
    }

    private func deletedFragmentRow(_ fragment: Fragment) -> some View {
        let c = fragment.type.color
        let color = Color(red: c.r, green: c.g, blue: c.b)
        return HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.08)).frame(width: 40, height: 40)
                Image(systemName: fragment.type.icon).font(.system(size: 14, weight: .light)).foregroundStyle(color.opacity(0.4))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(fragment.text.isEmpty ? fragment.type.rawValue : String(fragment.text.prefix(40)))
                    .foregroundStyle(.white.opacity(0.5)).font(.system(size: 14, weight: .regular)).lineLimit(1)
                HStack(spacing: 5) {
                    Text(fragment.type.rawValue.uppercased())
                        .font(.system(size: 9, weight: .semibold, design: .monospaced)).foregroundStyle(color.opacity(0.5)).kerning(1)
                    if let d = fragment.deletedAt {
                        let days = max(0, 30 - Int(Date().timeIntervalSince(d) / 86400))
                        Text("· \(days)d remaining").foregroundStyle(.white.opacity(0.2)).font(.system(size: 10, design: .monospaced))
                    }
                }
            }
            Spacer()
            Button(action: { fragmentsVM.restore(fragment) }) {
                Text("Restore").font(.system(size: 12)).foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.06)).overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5)))
            }
        }
        .padding(.vertical, 4)
    }
}
