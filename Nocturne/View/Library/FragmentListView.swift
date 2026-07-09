//
//  FragmentsListView.swift
//  Nocturne
//
//  Created by Damoon saber on 3/30/1405 AP.
//


import SwiftUI

// MARK: - FragmentsListView (library tab – feature 1: edit)

struct FragmentsListView: View {
    @ObservedObject var fragmentsVM: FragmentsViewModel
    @ObservedObject var libraryVM: LibraryViewModel
    @State private var showingAttachSheet: Fragment? = nil
    @State private var editingFragment: Fragment? = nil
    @State private var deletingFragment: Fragment? = nil
    @StateObject private var audioVM = AudioViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("Fragments")
                        .foregroundStyle(.white.opacity(0.9))
                        .font(.system(size: 16, weight: .medium))
                        .kerning(1)
                    Spacer()
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(nil, label: "All")
                        ForEach(FragmentType.allCases, id: \.self) { type in
                            filterChip(type, label: type.rawValue)
                        }
                    }
                    .padding(.horizontal, 28)
                }
                .padding(.bottom, 16)

                if fragmentsVM.filteredFragments.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 32, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.15))
                        Text("No fragments yet")
                            .foregroundStyle(.white.opacity(0.2))
                            .font(.system(size: 14, weight: .light))
                        Text("Capture stray ideas before they slip away")
                            .foregroundStyle(.white.opacity(0.15))
                            .font(.system(size: 12, weight: .light))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(fragmentsVM.filteredFragments) { fragment in
                                fragmentCard(fragment)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .sheet(item: $showingAttachSheet) { fragment in
            AttachFragmentSheet(
                fragment: fragment,
                songs: libraryVM.songs.filter { !$0.isDeleted },
                onAttach: { songID in
                    fragmentsVM.attach(fragment, toSongID: songID)
                    showingAttachSheet = nil
                },
                onDetach: {
                    fragmentsVM.detach(fragment)
                    showingAttachSheet = nil
                }
            )
        }
        .sheet(item: $editingFragment) { fragment in
            FragmentEditSheet(fragmentsVM: fragmentsVM, fragment: fragment) {
                editingFragment = nil
            }
        }
        .sheet(item: $deletingFragment) { fragment in
            DeleteConfirmSheet(
                title: fragment.text.isEmpty ? fragment.type.rawValue : String(fragment.text.prefix(40)),
                heading: "Delete Fragment",
                subtitle: "\"\(fragment.text.isEmpty ? fragment.type.rawValue : String(fragment.text.prefix(40)))\" will be moved to Recently Deleted.",
                onDelete: {
                    fragmentsVM.delete(fragment)
                    deletingFragment = nil
                },
                onCancel: { deletingFragment = nil }
            )
        }
    }

    private func filterChip(_ type: FragmentType?, label: String) -> some View {
        let isSelected = fragmentsVM.filterType == type
        let color: Color = {
            guard let type else { return .white }
            let c = type.color
            return Color(red: c.r, green: c.g, blue: c.b)
        }()
        return Button(action: { fragmentsVM.filterType = type }) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? color.opacity(0.95) : .white.opacity(0.4))
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? color.opacity(0.12) : Color.white.opacity(0.05))
                        .overlay(Capsule().stroke(isSelected ? color.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 0.5))
                )
        }
    }

    private func fragmentCard(_ fragment: Fragment) -> some View {
        let c = fragment.type.color
        let color = Color(red: c.r, green: c.g, blue: c.b)
        let attachedSong = libraryVM.songs.first { $0.id == fragment.attachedSongID }

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: fragment.type.icon).font(.system(size: 10, weight: .medium))
                    Text(fragment.type.rawValue.uppercased())
                        .font(.system(size: 9, weight: .semibold, design: .monospaced)).kerning(1)
                }
                .foregroundStyle(color.opacity(0.9))
                Spacer()
                Text(relativeDate(fragment.createdAt))
                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.2))
            }

            if fragment.type == .riff, let recording = fragment.audioRecording {
                VStack(alignment: .leading, spacing: 6) {
                    if !fragment.text.isEmpty {
                        Text(fragment.text)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    riffPlaybackRow(recording, color: color)
                }
            } else {
                Text(fragment.text)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Button(action: { showingAttachSheet = fragment }) {
                    HStack(spacing: 4) {
                        Image(systemName: "link").font(.system(size: 10))
                        Text(attachedSong != nil
                             ? (attachedSong!.title.isEmpty ? "Untitled" : attachedSong!.title)
                             : "Attach to song")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(attachedSong != nil ? color.opacity(0.8) : .white.opacity(0.3))
                }
                Spacer()
                // Edit button (feature 1)
                Button(action: { editingFragment = fragment }) {
                    Image(systemName: "pencil").font(.system(size: 11)).foregroundStyle(.white.opacity(0.25))
                }
                .padding(.trailing, 6)
                // Delete button — opens confirmation
                Button(action: { deletingFragment = fragment }) {
                    Image(systemName: "trash").font(.system(size: 11)).foregroundStyle(.white.opacity(0.2))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
        )
    }

    private func riffPlaybackRow(_ recording: Recording, color: Color) -> some View {
        let isPlaying = audioVM.activeRecording?.id == recording.id
        let currentTime = isPlaying ? audioVM.currentTime : 0
        let displayDuration = audioVM.activeRecording?.id == recording.id ? audioVM.duration : recording.duration

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Button(action: {
                    if isPlaying { audioVM.stopPlayback() } else { audioVM.play(recording) }
                }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(color.opacity(0.9))
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(color.opacity(0.1)))
                }
                WaveformView(
                    duration: displayDuration, currentTime: currentTime,
                    onSeek: { time in
                        if isPlaying { audioVM.seek(to: time) } else { audioVM.play(recording); audioVM.seek(to: time) }
                    },
                    accentColor: color
                )
                .frame(height: 22)
            }
            HStack {
                Text(audioVM.formattedTime(currentTime))
                    .font(.system(size: 10, design: .monospaced)).foregroundStyle(.white.opacity(0.3))
                Spacer()
                Text("-" + audioVM.formattedTime(max(0, displayDuration - currentTime)))
                    .font(.system(size: 10, design: .monospaced)).foregroundStyle(.white.opacity(0.3))
            }
            .padding(.leading, 40)
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - AttachFragmentSheet
struct AttachFragmentSheet: View {
    let fragment: Fragment
    let songs: [Song]
    let onAttach: (UUID) -> Void
    let onDetach: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Attach to song")
                    .foregroundStyle(.white)
                    .font(.system(size: 16, weight: .medium))
                    .padding(.top, 28)

                if fragment.attachedSongID != nil {
                    Button(action: onDetach) {
                        HStack {
                            Image(systemName: "link.badge.minus")
                            Text("Detach from current song")
                        }
                        .foregroundStyle(.red.opacity(0.8))
                        .font(.system(size: 13))
                    }
                    .padding(.bottom, 4)
                }

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(songs.filter { !$0.isDeleted }) { song in
                            Button(action: { onAttach(song.id) }) {
                                HStack {
                                    Text(song.title.isEmpty ? "Untitled" : song.title)
                                        .foregroundStyle(.white.opacity(0.85))
                                        .font(.system(size: 14))
                                    Spacer()
                                    if fragment.attachedSongID == song.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white.opacity(0.5))
                                            .font(.system(size: 12))
                                    }
                                }
                                .padding(14)
                                .background(Color.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                Spacer()
            }
        }
        .presentationDetents([.fraction(0.55)])
        .presentationBackground(Color.black)
    }
}
