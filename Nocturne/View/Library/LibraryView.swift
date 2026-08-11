//
//  LibraryView.swift
//  Nocturne
//

import SwiftUI

struct LibraryView: View {
    @ObservedObject var settings: SettingsStore
    @StateObject private var libraryViewModel = LibraryViewModel()
    @StateObject private var fragmentsViewModel = FragmentsViewModel()
    @State private var path: [UUID] = []
    @State private var selectedTab: LibraryTab = .songs
    @State private var showingCaptureSheet = false
    @State private var searchText = ""
    @State private var sharePayload: SharePayload? = nil
    @State private var songToDelete: Song? = nil
    @State private var pendingSongNavigationID: UUID? = nil
    @State private var showingProfile = false
    @State private var showingCreateFolder = false
    @State private var movingSong: Song? = nil
    @State private var showingFolderDetail: SongFolder? = nil
    @State private var showingRecentlyDeleted = false
    @State private var showingFABMenu = false

    enum LibraryTab { case songs, fragments }

    private var rootSongs: [Song] { libraryViewModel.songs(inFolder: nil) }

    private var filteredRootSongs: [Song] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return rootSongs }
        let q = trimmed.lowercased()
        return rootSongs.filter { song in
            song.title.lowercased().contains(q)
            || song.lyrics.lowercased().contains(q)
            || song.chords.contains { $0.names.contains { $0.lowercased().contains(q) } }
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottomTrailing) {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    headerView
                    tabSwitcher
                    searchBarView
                    contentArea
                }
                fabButton
            }
            .navigationDestination(for: UUID.self) { songID in
                if let song = libraryViewModel.songs.first(where: { $0.id == songID && !$0.isDeleted }) {
                    ContentView(
                        song: song,
                        fragmentsVM: fragmentsViewModel,
                        settings: settings,
                        onSave: { updatedSong in
                            let ok = await libraryViewModel.update(updatedSong)
                            if ok { settings.trackWordCount(for: updatedSong) }
                            return ok
                        },
                        onDismiss: { updatedSong in
                            let ok = await libraryViewModel.update(updatedSong)
                            if ok { settings.trackWordCount(for: updatedSong) }
                            if !path.isEmpty { path.removeLast() }
                        }
                    )
                    .navigationBarBackButtonHidden(true)
                    .toolbar(.hidden, for: .navigationBar)
                } else {
                    ContentUnavailableView("Song unavailable", systemImage: "music.note")
                        .foregroundStyle(.white.opacity(0.5))
                        .onAppear {
                            if !path.isEmpty { path.removeLast() }
                        }
                }
            }
        }
        .tint(.white)
        .sheet(isPresented: $showingFABMenu) {
            FABMenuSheet(
                onNewSong: { let song = libraryViewModel.newSong(); path.append(song.id) },
                onNewFolder: { showingCreateFolder = true },
                onCaptureFragment: { showingCaptureSheet = true },
                isPresented: $showingFABMenu
            )
        }
        .sheet(isPresented: $showingCaptureSheet) {
            FragmentCaptureSheet(fragmentsVM: fragmentsViewModel, isPresented: $showingCaptureSheet)
        }
        .sheet(isPresented: $showingCreateFolder) {
            CreateFolderSheet(isPresented: $showingCreateFolder) { name in _ = libraryViewModel.createFolder(name: name) }
        }
        .sheet(item: $showingFolderDetail, onDismiss: {
            if let songID = pendingSongNavigationID {
                pendingSongNavigationID = nil
                path.append(songID)
            }
        }) { folder in
            NavigationStack {
                FolderDetailView(libraryVM: libraryViewModel, fragmentsVM: fragmentsViewModel, folder: folder) { songID in
                    pendingSongNavigationID = songID
                    showingFolderDetail = nil
                }
            }
            .presentationBackground(Color.nocturneSheetBackground)
        }
        .sheet(item: $movingSong) { song in
            MoveSongToFolderSheet(song: song, libraryVM: libraryViewModel) { movingSong = nil }
        }
        .sheet(isPresented: $showingRecentlyDeleted) {
            RecentlyDeletedView(libraryVM: libraryViewModel, fragmentsVM: fragmentsViewModel)
                .presentationDetents([.fraction(0.65), .large])
                .presentationBackground(Color.nocturneSheetBackground)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView(settings: settings, libraryVM: libraryViewModel, fragmentsVM: fragmentsViewModel, onDismiss: { showingProfile = false })
                .presentationBackground(Color.nocturneSheetBackground)
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(items: payload.items)
        }
        .sheet(item: $songToDelete) { song in
            DeleteConfirmSheet(
                title: song.title.isEmpty ? "Untitled" : song.title,
                onDelete: {
                    libraryViewModel.softDelete(song)
                    songToDelete = nil
                },
                onCancel: { songToDelete = nil }
            )
        }
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "moon.stars").font(.system(size: 11, weight: .medium)).foregroundStyle(.white.opacity(0.65))
                Text("Nocturne").foregroundStyle(.white.opacity(0.7)).font(.system(size: 13, weight: .medium)).kerning(4)
            }
            .padding(.bottom, 20)

            HStack {
                Button("Recently deleted", systemImage: "trash") { showingRecentlyDeleted = true }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Button("Profile", systemImage: "person.circle") { showingProfile = true }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 28)
        }
        .padding(.top, 10)
        .padding(.bottom, 20)
    }

    // MARK: - Tab switcher
    private var tabSwitcher: some View {
        HStack(spacing: 8) {
            tabButton(.songs, label: "Songs", count: libraryViewModel.activeSongCount)
            tabButton(.fragments, label: "Fragments", count: fragmentsViewModel.activeCount)
            Spacer()
        }
        .padding(.horizontal, 28).padding(.bottom, 16)
    }

    // MARK: - Search bar
    @ViewBuilder
    private var searchBarView: some View {
        if selectedTab == .songs && libraryViewModel.activeSongCount > 0 {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.system(size: 13, weight: .regular)).foregroundStyle(.white.opacity(0.3))
                TextField("Search songs, lyrics, chords", text: $searchText)
                    .font(.system(size: 14)).foregroundStyle(.white.opacity(0.9)).tint(.white)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 13)).foregroundStyle(.white.opacity(0.25))
                    }
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 0.5)))
            .padding(.horizontal, 28).padding(.bottom, 14)
        }
    }

    // MARK: - Content area
    @ViewBuilder
    private var contentArea: some View {
        if selectedTab == .songs { songsList } else { FragmentsListView(fragmentsVM: fragmentsViewModel, libraryVM: libraryViewModel) }
    }

    // MARK: - FAB
    private var fabButton: some View {
        Button("New fragment", systemImage: "lightbulb") { showingFABMenu = true }
            .labelStyle(.iconOnly)
            .foregroundStyle(.black)
            .frame(width: 52, height: 52)
            .background(Circle().fill(.white))
            .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
        .padding(.trailing, 24).padding(.bottom, 28)
    }

    // MARK: - Songs list
    private var songsList: some View {
        Group {
            if rootSongs.isEmpty && libraryViewModel.folders.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list").font(.system(size: 32, weight: .ultraLight)).foregroundStyle(.white.opacity(0.15))
                    Text("No songs yet").foregroundStyle(.white.opacity(0.2)).font(.system(size: 14, weight: .light))
                }
                Spacer()
            } else if filteredRootSongs.isEmpty && !searchText.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass").font(.system(size: 28, weight: .ultraLight)).foregroundStyle(.white.opacity(0.15))
                    Text("No matches for \"\(searchText)\"").foregroundStyle(.white.opacity(0.2)).font(.system(size: 14, weight: .light))
                }
                Spacer()
            } else {
                List {
                    if searchText.isEmpty {
                        ForEach(libraryViewModel.folders) { folder in
                            folderRow(folder)
                                .listRowBackground(Color.clear)
                                .listRowSeparatorTint(.white.opacity(0.06))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) { libraryViewModel.deleteFolder(folder) } label: {
                                        Label("Delete Folder", systemImage: "trash")
                                    }.tint(Color(red: 0.8, green: 0.1, blue: 0.1))
                                }
                        }
                    }
                    ForEach(filteredRootSongs) { song in songListRow(song) }
                        .onMove(perform: searchText.isEmpty ? { s, d in libraryViewModel.move(from: s, to: d, inFolder: nil) } : nil)
                }
                .listStyle(.plain)
                .environment(\.editMode, .constant(.inactive))
            }
        }
    }

    // MARK: - Folder row
    private func folderRow(_ folder: SongFolder) -> some View {
        let count = libraryViewModel.songs(inFolder: folder.id).count
        return Button(action: { showingFolderDetail = folder }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)).frame(width: 40, height: 40)
                    Image(systemName: "folder").font(.system(size: 16, weight: .light)).foregroundStyle(.white.opacity(0.5))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(folder.name).foregroundStyle(.white.opacity(0.85)).font(.system(size: 15, weight: .regular))
                    Text("\(count) song\(count == 1 ? "" : "s")").foregroundStyle(.white.opacity(0.25)).font(.system(size: 12, design: .monospaced))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .light)).foregroundStyle(.white.opacity(0.15))
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Song list row
    @ViewBuilder
    private func songListRow(_ song: Song) -> some View {
        Button(action: { path.append(song.id) }) { songRow(song) }
            .listRowBackground(Color.clear)
            .listRowSeparatorTint(.white.opacity(0.06))
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) { songToDelete = song } label: {
                    Label("Delete", systemImage: "trash")
                }.tint(Color(red: 0.8, green: 0.1, blue: 0.1))
                Button { shareSong(song) } label: { Label("Share PDF", systemImage: "square.and.arrow.up") }
                    .tint(Color(red: 0.15, green: 0.15, blue: 0.18))
                Button { movingSong = song } label: { Label("Move", systemImage: "folder") }
                    .tint(Color(red: 0.1, green: 0.1, blue: 0.14))
            }
            .contextMenu {
                Button { movingSong = song } label: { Label("Move to Folder", systemImage: "folder") }
                Button { shareSong(song) } label: { Label("Share PDF", systemImage: "square.and.arrow.up") }
                if let items = SongShareOptions.linkItems(for: song) {
                    Button { sharePayload = SharePayload(items: items) } label: { Label("Share Link", systemImage: "link") }
                }
                Divider()
                Button(role: .destructive) { songToDelete = song } label: {
                    Label("Delete", systemImage: "trash")
                }
            } preview: { SongContextPreview(song: song, lyricsFont: settings.lyricsFont) }
    }

    // MARK: - Song row UI
    @ViewBuilder
    private func songRow(_ song: Song) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)).frame(width: 40, height: 40)
                Image(systemName: "music.note").font(.system(size: 14, weight: .light)).foregroundStyle(.white.opacity(0.3))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(song.title.isEmpty ? "Untitled" : song.title)
                    .foregroundStyle(.white.opacity(0.85)).font(.system(size: 15, weight: .regular))
                Text(previewText(for: song))
                    .foregroundStyle(.white.opacity(0.25)).font(settings.lyricsFont.font(size: 12)).lineLimit(1)
            }
            Spacer()
            if !song.mainRecordingIDs.isEmpty {
                Image(systemName: "star.fill").font(.system(size: 9)).foregroundStyle(Color(red: 1, green: 0.85, blue: 0.4).opacity(0.6))
            }
            let attachedCount = fragmentsViewModel.fragments(forSongID: song.id).count
            if attachedCount > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "lightbulb").font(.system(size: 9))
                    Text("\(attachedCount)").font(.system(size: 11))
                }
                .foregroundStyle(.white.opacity(0.25))
            }
            Image(systemName: "chevron.right").font(.system(size: 10, weight: .light)).foregroundStyle(.white.opacity(0.15))
        }
        .padding(.vertical, 4)
    }

    // MARK: - Tab button
    private func tabButton(_ tab: LibraryTab, label: String, count: Int) -> some View {
        let isSelected = selectedTab == tab
        return Button(action: { selectedTab = tab }) {
            HStack(spacing: 5) {
                Text(label).font(.system(size: 12, weight: .medium))
                Text("\(count)").font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(isSelected ? 0.4 : 0.25))
            }
            .foregroundStyle(isSelected ? .white.opacity(0.9) : .white.opacity(0.35))
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(
                Capsule().fill(isSelected ? Color.white.opacity(0.08) : Color.clear)
                    .overlay(Capsule().stroke(Color.white.opacity(isSelected ? 0.12 : 0.06), lineWidth: 0.5))
            )
        }
    }

    private func previewText(for song: Song) -> String {
        song.lyrics.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.first ?? "No lyrics"
    }

    private func shareSong(_ song: Song) {
        Task {
            let data = SongExporter.pdf(for: song)
            let fileName = SongExporter.sanitizedFileName(for: song.title) + ".pdf"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            guard (try? data.write(to: url)) != nil else { return }
            await MainActor.run { sharePayload = SharePayload(items: [url]) }
        }
    }
}
