//
//  RecordingsAndWaveform.swift
//  Nocturne
//
//  Created by Damoon saber on 3/28/1405 AP.
//

import SwiftUI
import AVFoundation

// ─────────────────────────────────────────────
// MARK: - WaveformView (unchanged)
// ─────────────────────────────────────────────

struct WaveformView: View {
    let duration: TimeInterval
    let currentTime: TimeInterval
    let onSeek: (TimeInterval) -> Void
    var accentColor: Color = .white

    private let barCount = 40

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(currentTime / duration, 1.0)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                HStack(spacing: 2) {
                    ForEach(0..<barCount, id: \.self) { i in
                        let filled = Double(i) / Double(barCount) <= progress
                        RoundedRectangle(cornerRadius: 1)
                            .fill(filled ? accentColor.opacity(0.8) : Color.white.opacity(0.15))
                            .frame(
                                width: (geo.size.width - CGFloat(barCount - 1) * 2) / CGFloat(barCount),
                                height: barHeight(for: i)
                            )
                    }
                }

                Circle()
                    .fill(accentColor == .white ? .white : accentColor)
                    .frame(width: 10, height: 10)
                    .offset(x: geo.size.width * progress - 5)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
            .frame(height: 28)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let pct = max(0, min(1, value.location.x / geo.size.width))
                        onSeek(pct * duration)
                    }
                    .onEnded { value in
                        let pct = max(0, min(1, value.location.x / geo.size.width))
                        onSeek(pct * duration)
                    }
            )
            .accessibilityLabel("Playback position")
            .accessibilityValue("\(Int(progress * 100)) percent")
        }
        .frame(height: 28)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let seed = Double(index * 7 + 3)
        let height = (sin(seed) + cos(seed * 0.7) + 1.5) / 3.0
        return CGFloat(height) * 18 + 4
    }
}

// ─────────────────────────────────────────────
// MARK: - RecordingsSheetView
// ─────────────────────────────────────────────

struct RecordingsSheetView: View {
    @ObservedObject var audioVM: AudioViewModel
    @ObservedObject var viewModel: SongViewModel
    let onSaveRecording: (Recording) -> Void
    let onDeleteRecording: (Recording) -> Void

    @State private var showingVideoRecorder = false
    @State private var playingVideoNote: Recording? = nil
    @State private var recordingToDelete: Recording? = nil
    @State private var sharePayload: SharePayload? = nil

    private var audioRecordings: [Recording] { viewModel.song.recordings.filter { $0.kind == .audio } }
    private var videoNotes: [Recording] { viewModel.song.recordings.filter { $0.kind == .video } }
    private var isEmpty: Bool { viewModel.song.recordings.isEmpty && !audioVM.isRecording }

    var body: some View {
        ZStack {
            Color.nocturneSheetBackground.ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Header
                HStack(spacing: 12) {
                    Text("Recordings")
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .regular))
                        .kerning(1)

                    Spacer()

                    // Video note button
                    Button("Record", systemImage: "video") { showingVideoRecorder = true }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.06))
                                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                        )

                    Button(action: {
                        if audioVM.isRecording {
                            audioVM.stopRecording(for: viewModel.song) { recording in
                                onSaveRecording(recording)
                            }
                        } else {
                            audioVM.startRecording(for: viewModel.song)
                        }
                    }) {
                        HStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(audioVM.isRecording ? Color.red.opacity(0.9) : Color.white.opacity(0.08))
                                    .frame(width: 20, height: 20)
                                if audioVM.isRecording {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(.white)
                                        .frame(width: 7, height: 7)
                                } else {
                                    Circle()
                                        .fill(.red.opacity(0.8))
                                        .frame(width: 7, height: 7)
                                }
                            }
                            Text(audioVM.isRecording
                                 ? audioVM.formattedTime(audioVM.recordingTime)
                                 : "Record")
                                .font(.system(size: 12, weight: .medium,
                                              design: audioVM.isRecording ? .monospaced : .default))
                                .foregroundStyle(audioVM.isRecording ? .red : .white.opacity(0.7))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(audioVM.isRecording ? Color.red.opacity(0.12) : Color.white.opacity(0.06))
                                .overlay(Capsule().stroke(
                                    audioVM.isRecording ? Color.red.opacity(0.4) : Color.white.opacity(0.1),
                                    lineWidth: 0.5))
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 20)

                if isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "waveform")
                            .font(.system(size: 32, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.15))
                        Text("No recordings yet")
                            .foregroundStyle(.white.opacity(0.25))
                            .font(.system(size: 13, weight: .light))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {

                            // MARK: Video notes strip
                            if !videoNotes.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "video")
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundStyle(.white.opacity(0.3))
                                        Text("VIDEO")
                                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                            .kerning(1.5)
                                            .foregroundStyle(.white.opacity(0.3))
                                    }
                                    .padding(.horizontal, 20)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(videoNotes) { note in
                                                videoNoteThumbnail(note)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }

                            // MARK: Audio recordings
                            if !audioRecordings.isEmpty || audioVM.isRecording {
                                VStack(alignment: .leading, spacing: 12) {
                                    if !videoNotes.isEmpty {
                                        HStack(spacing: 6) {
                                            Image(systemName: "waveform")
                                                .font(.system(size: 9, weight: .medium))
                                                .foregroundStyle(.white.opacity(0.3))
                                            Text("AUDIO")
                                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                                .kerning(1.5)
                                                .foregroundStyle(.white.opacity(0.3))
                                        }
                                        .padding(.horizontal, 20)
                                    }

                                    VStack(spacing: 12) {
                                        if let active = audioVM.activeRecording {
                                            activePlayerView(for: active)
                                                .padding(.horizontal, 20)
                                        }

                                        ForEach(audioRecordings) { recording in
                                            audioRecordingRow(for: recording)
                                                .padding(.horizontal, 20)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.bottom, 20)
                    }
                }
            }

            if let recording = recordingToDelete {
                recordingDeleteOverlay(for: recording)
            }
        }
        .motionAwareAnimation(.easeInOut(duration: 0.2), value: recordingToDelete?.id)
        .presentationDetents([.fraction(0.55), .large])
        .presentationBackground(Color.nocturneSheetBackground)
        .sheet(isPresented: $showingVideoRecorder) {
            VideoRecorderView(
                songID: viewModel.song.id,
                onSave: { recording in onSaveRecording(recording) },
                isPresented: $showingVideoRecorder
            )
        }
        .sheet(item: $playingVideoNote) { note in
            VideoNoteSheet(
                recording: note,
                onDelete: {
                    recordingToDelete = note
                    playingVideoNote = nil
                },
                isPresented: Binding(
                    get: { playingVideoNote?.id == note.id },
                    set: { if !$0 { playingVideoNote = nil } }
                )
            )
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(items: payload.items)
        }
    }

    @ViewBuilder
    private func recordingDeleteOverlay(for recording: Recording) -> some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { recordingToDelete = nil }

            VStack(spacing: 0) {
                Spacer()
                DeleteConfirmSheet(
                    title: formatDate(recording.createdAt),
                    heading: recording.kind == .video ? "Delete Video" : "Delete Recording",
                    subtitle: "This \(recording.kind == .video ? "video" : "recording") will be permanently deleted.",
                    onDelete: {
                        audioVM.delete(recording)
                        onDeleteRecording(recording)
                        recordingToDelete = nil
                    },
                    onCancel: { recordingToDelete = nil }
                )
                .frame(maxHeight: 340)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Video note thumbnail

    private func videoNoteThumbnail(_ note: Recording) -> some View {
        Button(action: { playingVideoNote = note }) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 80, height: 80)
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))

                // Thumbnail from first frame
                VideoThumbnailView(url: note.fileURL)
                    .frame(width: 76, height: 76)
                    .clipShape(Circle())

                // Play icon overlay
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.35))
                        .frame(width: 28, height: 28)
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.9))
                        .offset(x: 1)
                }

                // Duration badge
                VStack {
                    Spacer()
                    Text(formattedDuration(note.duration))
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(Color.black.opacity(0.6))
                        )
                        .padding(.bottom, 6)
                }
                .frame(width: 80, height: 80)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                sharePayload = SharePayload(items: [note.fileURL])
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Button(role: .destructive) {
                recordingToDelete = note
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Active audio player

    private func activePlayerView(for recording: Recording) -> some View {
        VStack(spacing: 12) {
            WaveformView(
                duration: audioVM.duration,
                currentTime: audioVM.currentTime,
                onSeek: audioVM.seek
            )

            HStack {
                Text(audioVM.formattedTime(audioVM.currentTime))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                Spacer()
                Button(audioVM.isPlaying ? "Pause" : "Play", systemImage: audioVM.isPlaying ? "pause.fill" : "play.fill") {
                    audioVM.isPlaying ? audioVM.pausePlayback() : audioVM.resumePlayback()
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.white.opacity(0.1)))
                Spacer()
                Text(audioVM.formattedTime(audioVM.duration))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
        )
    }

    // MARK: - Audio recording row

    private func audioRecordingRow(for recording: Recording) -> some View {
        let isActive = audioVM.activeRecording?.id == recording.id

        return HStack(spacing: 14) {
                Button(isActive ? "Stop playback" : "Play recording", systemImage: isActive ? "stop.fill" : "play.fill") {
                    if isActive { audioVM.stopPlayback() } else { audioVM.play(recording) }
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.white.opacity(isActive ? 0.9 : 0.5))
                .frame(width: 36, height: 36)
                .background(Circle().fill(isActive ? Color.white.opacity(0.15) : Color.white.opacity(0.06)))

            VStack(alignment: .leading, spacing: 3) {
                Text(formatDate(recording.createdAt))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.75))
                Text(audioVM.formattedTime(recording.duration))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.25))
            }

            Spacer()

            Button("Share recording", systemImage: "square.and.arrow.up") {
                sharePayload = SharePayload(items: [recording.fileURL])
            }
            .labelStyle(.iconOnly)
            .foregroundStyle(.white.opacity(0.3))

            Button("Delete recording", systemImage: "trash") { recordingToDelete = recording }
                .labelStyle(.iconOnly)
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isActive ? 0.06 : 0.03))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
        )
        .contextMenu {
            Button {
                sharePayload = SharePayload(items: [recording.fileURL])
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Button(role: .destructive) {
                recordingToDelete = recording
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mm a"
        return f.string(from: date)
    }

    private func formattedDuration(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// ─────────────────────────────────────────────
// MARK: - Video thumbnail (first frame)
// ─────────────────────────────────────────────

struct VideoThumbnailView: View {
    let url: URL
    @State private var thumbnail: UIImage? = nil

    var body: some View {
        Group {
            if let img = thumbnail {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.white.opacity(0.04)
                    .overlay(
                        Image(systemName: "video")
                            .font(.system(size: 14, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.2))
                    )
            }
        }
        .task {
            thumbnail = await generateThumbnail(url: url)
        }
    }

    private func generateThumbnail(url: URL) async -> UIImage? {
        guard url.isReachable else { return nil }
        return await Task.detached(priority: .userInitiated) {
            let asset = AVURLAsset(url: url)
            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true
            gen.maximumSize = CGSize(width: 160, height: 160)
            let time = CMTime(seconds: 0.1, preferredTimescale: 600)
            guard let cgImage = try? gen.copyCGImage(at: time, actualTime: nil) else { return nil }
            return UIImage(cgImage: cgImage)
        }.value
    }
}
