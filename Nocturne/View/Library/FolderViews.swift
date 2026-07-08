//
//  FolderViews.swift
//  Nocturne
//

import SwiftUI

struct CreateFolderSheet: View {
    @Binding var isPresented: Bool
    let onCreate: (String) -> Void

    @State private var name: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("New Folder")
                    .foregroundStyle(.white).font(.system(size: 16, weight: .medium)).padding(.top, 32)
                TextField("Folder name", text: $name)
                    .font(.system(size: 16)).foregroundStyle(.white).tint(.white)
                    .padding().background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                    .padding(.horizontal, 24)
                    .focused($focused)
                Button(action: {
                    let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !n.isEmpty else { return }
                    onCreate(n)
                    isPresented = false
                }) {
                    Text("Create Folder")
                        .foregroundStyle(.black).font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity).padding()
                        .background(name.isEmpty ? Color.white.opacity(0.3) : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 24)
                }
                .disabled(name.isEmpty)
                Button("Cancel") { isPresented = false }
                    .foregroundStyle(.gray).font(.system(size: 13))
                Spacer()
            }
        }
        .presentationDetents([.fraction(0.4)])
        .presentationBackground(Color.black)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { focused = true } }
    }
}

struct MoveSongToFolderSheet: View {
    let song: Song
    @ObservedObject var libraryVM: LibraryViewModel
    var onDone: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Move to Folder")
                    .foregroundStyle(.white).font(.system(size: 16, weight: .medium))
                    .padding(.top, 28).padding(.bottom, 20)
                ScrollView {
                    VStack(spacing: 8) {
                        folderRow(id: nil, name: "Songs (root)", icon: "music.note.list")
                        ForEach(libraryVM.folders) { folder in
                            folderRow(id: folder.id, name: folder.name, icon: "folder")
                        }
                    }
                    .padding(.horizontal, 20)
                }
                Spacer()
                Button("Cancel", action: onDone)
                    .foregroundStyle(.gray).font(.system(size: 13)).padding(.bottom, 24)
            }
        }
        .presentationDetents([.fraction(0.5), .large])
        .presentationBackground(Color.black)
    }

    private func folderRow(id: UUID?, name: String, icon: String) -> some View {
        let isCurrent = song.folderID == id
        return Button(action: {
            libraryVM.moveSong(song, toFolder: id)
            onDone()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 24)
                Text(name).foregroundStyle(.white.opacity(0.85)).font(.system(size: 14))
                Spacer()
                if isCurrent {
                    Image(systemName: "checkmark").foregroundStyle(.white.opacity(0.5)).font(.system(size: 12))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isCurrent ? Color.white.opacity(0.07) : Color.white.opacity(0.03))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(isCurrent ? 0.12 : 0.06), lineWidth: 0.5))
            )
        }
    }
}

struct FolderDetailView: View {
    @ObservedObject var libraryVM: LibraryViewModel
    @ObservedObject var fragmentsVM: FragmentsViewModel
    let folder: SongFolder
    var onNavigateToSong: (UUID) -> Void

    @State private var songToDelete: Song? = nil
    @State private var movingSong: Song? = nil

    private var songs: [Song] { libraryVM.songs(inFolder: folder.id) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "folder")
                        .font(.system(size: 13, weight: .light)).foregroundStyle(.white.opacity(0.4))
                    Text(folder.name)
                        .foregroundStyle(.white.opacity(0.85)).font(.system(size: 15, weight: .medium))
                    Spacer()
                    Button(action: {
                        let song = libraryVM.newSong(inFolder: folder.id)
                        onNavigateToSong(song.id)
                    }) {
                        Image(systemName: "plus").foregroundStyle(.white.opacity(0.7)).font(.system(size: 16, weight: .light))
                    }
                }
                .padding(.horizontal, 28).padding(.vertical, 20)

                if songs.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 32, weight: .ultraLight)).foregroundStyle(.white.opacity(0.15))
                        Text("No songs in this folder")
                            .foregroundStyle(.white.opacity(0.2)).font(.system(size: 14, weight: .light))
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(songs) { song in
                            Button(action: { onNavigateToSong(song.id) }) { songRow(song) }
                                .listRowBackground(Color.clear)
                                .listRowSeparatorTint(.white.opacity(0.06))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        songToDelete = song
                                    } label: { Label("Delete", systemImage: "trash") }
                                        .tint(Color(red: 0.8, green: 0.1, blue: 0.1))
                                    Button { movingSong = song } label: { Label("Move", systemImage: "folder") }
                                        .tint(Color(red: 0.1, green: 0.1, blue: 0.14))
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .sheet(item: $movingSong) { song in
            MoveSongToFolderSheet(song: song, libraryVM: libraryVM) { movingSong = nil }
        }
        .sheet(item: $songToDelete) { song in
            DeleteConfirmSheet(
                title: song.title.isEmpty ? "Untitled" : song.title,
                onDelete: {
                    libraryVM.softDelete(song)
                    songToDelete = nil
                },
                onCancel: { songToDelete = nil }
            )
        }
    }

    private func songRow(_ song: Song) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)).frame(width: 40, height: 40)
                Image(systemName: "music.note").font(.system(size: 14, weight: .light)).foregroundStyle(.white.opacity(0.3))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(song.title.isEmpty ? "Untitled" : song.title)
                    .foregroundStyle(.white.opacity(0.85)).font(.system(size: 15, weight: .regular))
                let preview = song.lyrics.components(separatedBy: "\n")
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.first ?? "No lyrics"
                Text(preview).foregroundStyle(.white.opacity(0.25))
                    .font(.system(size: 12, weight: .regular, design: .monospaced)).lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 10, weight: .light)).foregroundStyle(.white.opacity(0.15))
        }
        .padding(.vertical, 4)
    }
}
