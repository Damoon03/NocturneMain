//
//  NocturneShareLink.swift
//  Nocturne
//
//  Created by Damoon saber on 4/3/1405 AP.
//
//  Feature 7: share a "nocturne://" deep link that opens a read-only view
//  of the song with the main recording playable.
//
//  HOW IT WORKS
//  ─────────────
//  1. The sender serialises the song (title + lyrics + chords + sectionLabels
//     + mainRecordingIDs) into JSON, base64-encodes it, and puts it in a URL:
//       nocturne://song/<base64>
//  2. The URL is shared via the system share sheet.
//  3. NocturneApp handles the URL (onOpenURL) and decodes it into a
//     SharedSongPayload, then shows SharedSongView as a sheet.
//  4. SharedSongView is read-only: lyrics + chords rendered the same way as
//     ContentView's lyricsDisplayView, but without editing controls.
//     The main recording is NOT transmitted (audio file paths are device-
//     local), so the playback section simply shows a "No audio included"
//     notice — the sender could attach an audio file via AirDrop separately.
//


import Foundation
import SwiftUI
import UIKit

// MARK: - Payload (Codable subset of Song – no audio file paths)

struct SharedSongPayload: Codable {
    var title: String
    var lyrics: String
    var chords: [Chord]
    var sectionLabels: [SectionLabel]

    init(from song: Song) {
        title = song.title
        lyrics = song.lyrics
        chords = song.chords
        sectionLabels = song.sectionLabels
    }
}

// MARK: - URL builder / parser

struct NocturneShareLink {
    static let scheme = "nocturne"
    static let host   = "song"

    static func url(for song: Song) -> URL? {
        let payload = SharedSongPayload(from: song)
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        let b64 = data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return URL(string: "\(scheme)://\(host)/\(b64)")
    }

    static func decode(_ url: URL) -> SharedSongPayload? {
        guard url.scheme == scheme, url.host == host else { return nil }
        var b64 = url.pathComponents.dropFirst().joined()
        // Re-pad
        let rem = b64.count % 4
        if rem != 0 { b64 += String(repeating: "=", count: 4 - rem) }
        b64 = b64
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        guard let data = Data(base64Encoded: b64),
              let payload = try? JSONDecoder().decode(SharedSongPayload.self, from: data)
        else { return nil }
        return payload
    }
}

// MARK: - Share helper (used in ContentView / LibraryView)

struct SongShareOptions {
    /// Returns share items for a "Nocturne link" share.
    static func linkItems(for song: Song) -> [Any]? {
        guard let url = NocturneShareLink.url(for: song) else { return nil }
        let text = "Check out \"" + song.title + "\" on Nocturne: " + url.absoluteString
        return [text]
    }
}

// MARK: - SharedSongView  (read-only, opened from deep link)

struct SharedSongView: View {
    let payload: SharedSongPayload
    var onDismiss: () -> Void

    // Re-use the same display infrastructure by building a temporary Song
    @StateObject private var vm: SongViewModel

    init(payload: SharedSongPayload, onDismiss: @escaping () -> Void) {
        self.payload = payload
        self.onDismiss = onDismiss
        let tempSong = Song(
            title: payload.title,
            lyrics: payload.lyrics,
            sectionLabels: payload.sectionLabels,
            chords: payload.chords
        )
        _vm = StateObject(wrappedValue: SongViewModel(song: tempSong))
    }

    private let lineSpacing: CGFloat = 10
    private let fontSize: CGFloat = 13

    @State private var wordFrames: [String: CGRect] = [:]
    @State private var chordWidths: [UUID: CGFloat] = [:]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text(payload.title.isEmpty ? "Untitled" : payload.title)
                            .foregroundStyle(.white.opacity(0.9))
                            .font(.system(size: 15, weight: .light))
                            .kerning(1.5)
                        Text("Shared via Nocturne")
                            .foregroundStyle(.white.opacity(0.25))
                            .font(.system(size: 10, weight: .light))
                            .kerning(0.5)
                    }
                    Spacer()
                    // Balance button
                    Image(systemName: "xmark").opacity(0)
                        .font(.system(size: 16, weight: .light))
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 20)

                // No-audio notice
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                    Text("Read-only preview — audio not included in link shares")
                        .font(.system(size: 11))
                }
                .foregroundStyle(.white.opacity(0.2))
                .padding(.horizontal, 24)
                .padding(.bottom, 14)

                // Lyrics display (read-only, same rendering as ContentView)
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.04))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.07), lineWidth: 0.5))

                    lyricsDisplayView
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Lyrics display (mirrors ContentView.lyricsDisplayView, read-only)
    private var lyricsDisplayView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: lineSpacing) {
                ForEach(Array(vm.lyricsLines.enumerated()), id: \.offset) { lineIndex, _ in
                    VStack(alignment: .leading, spacing: 2) {
                        if let label = vm.sectionLabel(forLineIndex: lineIndex) {
                            SectionLabelView(label: label, onDelete: {})
                                .padding(.bottom, 4)
                        }
                        let lineChords = vm.chords(forLineIndex: lineIndex)
                        ZStack(alignment: .topLeading) {
                            FlowLayout(spacing: 0) {
                                ForEach(Array(vm.wordsInLine(lineIndex).enumerated()), id: \.offset) { wordIndex, word in
                                    HStack(spacing: 0) {
                                        Text(word)
                                            .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                                            .foregroundStyle(.white)
                                            .background(GeometryReader { geo in
                                                Color.clear.preference(
                                                    key: WordFramePreferenceKey.self,
                                                    value: ["\(lineIndex):\(wordIndex)": geo.frame(in: .named("sharedCoord"))]
                                                )
                                            })
                                        Text(" ")
                                            .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .padding(.top, lineChords.isEmpty ? 0 : 22)

                            ForEach(lineChords) { chord in
                                let key = "\(lineIndex):\(chord.wordIndex)"
                                if let frame = wordFrames[key] {
                                    chordCapsule(for: chord)
                                        .offset(x: frame.minX - 14, y: 0)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .coordinateSpace(name: "sharedCoord")
            .onPreferenceChange(WordFramePreferenceKey.self) { wordFrames = $0 }
        }
    }

    @ViewBuilder
    private func chordCapsule(for chord: Chord) -> some View {
        HStack(spacing: 2) {
            ForEach(Array(chord.names.enumerated()), id: \.offset) { nameIndex, name in
                if nameIndex > 0 {
                    Text("/")
                        .font(.system(size: fontSize - 4, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Text(name)
                    .font(.system(size: fontSize - 3, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(
                        Capsule().stroke(.white.opacity(0.5), lineWidth: 1)
                            .background(Capsule().fill(Color.white.opacity(0.07)))
                    )
                    .fixedSize()
            }
        }
    }
}
