//
//  SongFragmentSheet.swift
//  Nocturne
//
//  Created by Damoon saber on 3/30/1405 AP.
//
//  Feature 5: categorised fragments in ContentView, matching LibraryView style.
//  Feature 1: edit button opens FragmentEditSheet.
//

import SwiftUI

struct SongFragmentsSheet: View {
    @ObservedObject var fragmentsVM: FragmentsViewModel
    let songID: UUID
    @StateObject private var audioVM = AudioViewModel()
    @State private var filterType: FragmentType? = nil
    @State private var editingFragment: Fragment? = nil

    private var allFragments: [Fragment] {
        fragmentsVM.fragments.sorted { $0.createdAt > $1.createdAt }
    }

    private var displayedFragments: [Fragment] {
        guard let filterType else { return allFragments }
        return allFragments.filter { $0.type == filterType }
    }

    var body: some View {
        ZStack {
            Color.nocturneSheetBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                Text("All Fragments")
                    .foregroundStyle(.white)
                    .font(.system(size: 15, weight: .medium))
                    .padding(.top, 28)
                    .padding(.bottom, 4)

                Text("Tap \(Image(systemName: "link.circle")) to attach an idea to this song")
                    .foregroundStyle(.white.opacity(0.25))
                    .font(.system(size: 11, weight: .light))
                    .padding(.bottom, 14)

                // Feature 5: category filter chips (same as LibraryView)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(nil, label: "All")
                        ForEach(FragmentType.allCases, id: \.self) { type in
                            filterChip(type, label: type.rawValue)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 14)

                if allFragments.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 28, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.15))
                        Text("No fragments yet")
                            .foregroundStyle(.white.opacity(0.2))
                            .font(.system(size: 13, weight: .light))
                    }
                    Spacer()
                } else if displayedFragments.isEmpty {
                    Spacer()
                    Text("No \(filterType?.rawValue ?? "") fragments")
                        .foregroundStyle(.white.opacity(0.2))
                        .font(.system(size: 13, weight: .light))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(displayedFragments) { fragment in
                                fragmentRow(fragment)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.65), .large])
        .presentationBackground(Color.nocturneSheetBackground)
        .sheet(item: $editingFragment) { fragment in
            FragmentEditSheet(fragmentsVM: fragmentsVM, fragment: fragment) {
                editingFragment = nil
            }
        }
    }

    // MARK: - Filter chip
    private func filterChip(_ type: FragmentType?, label: String) -> some View {
        let isSelected = filterType == type
        let color: Color = {
            guard let type else { return .white }
            let c = type.color
            return Color(red: c.r, green: c.g, blue: c.b)
        }()
        return Button(action: { filterType = type }) {
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

    // MARK: - Fragment row
    private func fragmentRow(_ fragment: Fragment) -> some View {
        let c = fragment.type.color
        let color = Color(red: c.r, green: c.g, blue: c.b)
        let isAttachedHere = fragment.attachedSongID == songID

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: fragment.type.icon).font(.system(size: 10, weight: .medium))
                Text(fragment.type.rawValue.uppercased())
                    .font(.system(size: 9, weight: .semibold, design: .monospaced)).kerning(1)
                Spacer()
                // Edit (feature 1)
                Button(action: { editingFragment = fragment }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.2))
                }
                // Attach toggle
                Button(action: {
                    if isAttachedHere { fragmentsVM.detach(fragment) }
                    else { fragmentsVM.attach(fragment, toSongID: songID) }
                }) {
                    Image(systemName: isAttachedHere ? "link.circle.fill" : "link.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(isAttachedHere ? color.opacity(0.9) : .white.opacity(0.2))
                }
            }
            .foregroundStyle(color.opacity(0.9))

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
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isAttachedHere ? color.opacity(0.05) : Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isAttachedHere ? color.opacity(0.25) : Color.white.opacity(0.07),
                                lineWidth: 0.5)
                )
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
}
