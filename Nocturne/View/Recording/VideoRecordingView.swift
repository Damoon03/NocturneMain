//
//  VideoRecordingView.swift
//  Nocturne
//

import SwiftUI
import AVFoundation
import AVKit

struct VideoRecorderView: View {
    let songID: UUID
    let onSave: (Recording) -> Void
    @Binding var isPresented: Bool

    @StateObject private var vm = VideoRecorderViewModel()

    var body: some View {
        ZStack {
            Color.nocturneSheetBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Title
                HStack {
                    Button("Close", systemImage: "xmark") { isPresented = false }
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer()
                    Text("Video")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                        .kerning(1)
                    Spacer()
                    // Balance the X button
                    Color.clear.frame(width: 24, height: 24)
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 28)

                // Circular camera preview
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.04))
                        .frame(width: 260, height: 260)
                        .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))

                    if vm.cameraReady {
                        CameraPreviewView(session: vm.session)
                            .frame(width: 256, height: 256)
                            .clipShape(Circle())
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "video")
                                .font(.system(size: 28, weight: .ultraLight))
                                .foregroundStyle(.white.opacity(0.2))
                            Text("Preparing camera…")
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(.white.opacity(0.2))
                        }
                    }

                    // Recording progress ring
                    if vm.isRecording {
                        Circle()
                            .stroke(Color.red.opacity(0.8), lineWidth: 3)
                            .frame(width: 264, height: 264)
                    }
                }
                .padding(.bottom, 36)

                // Timer
                Text(vm.isRecording ? formattedTime(vm.recordingTime) : "Tap to record")
                    .font(.system(size: 13, weight: .light, design: .monospaced))
                    .foregroundStyle(vm.isRecording ? .red.opacity(0.8) : .white.opacity(0.2))
                    .padding(.bottom, 36)

                // Record button
                Button(action: {
                    if vm.isRecording {
                        vm.stopRecording()
                    } else {
                        vm.startRecording(songID: songID) { url, duration in
                            let fileName = url.lastPathComponent
                            let recording = Recording(
                                fileName: fileName,
                                createdAt: Date(),
                                duration: duration,
                                kind: .video
                            )
                            onSave(recording)
                            isPresented = false
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(vm.isRecording ? Color.red.opacity(0.15) : Color.white.opacity(0.08))
                            .frame(width: 72, height: 72)
                            .overlay(Circle().stroke(
                                vm.isRecording ? Color.red.opacity(0.4) : Color.white.opacity(0.15),
                                lineWidth: 1
                            ))

                        if vm.isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.red.opacity(0.9))
                                .frame(width: 22, height: 22)
                        } else {
                            Circle()
                                .fill(Color.red.opacity(0.85))
                                .frame(width: 28, height: 28)
                        }
                    }
                }
                .disabled(!vm.cameraReady)

                Spacer()
            }
        }
        .presentationDetents([.fraction(0.88)])
        .presentationBackground(Color.nocturneSheetBackground)
        .presentationDragIndicator(.hidden)
        .onDisappear {
            vm.stopRecording()
            vm.stopSession()
        }
    }

    private func formattedTime(_ t: TimeInterval) -> String {
        let total = Int(t)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        let tenth = Int((t * 10).truncatingRemainder(dividingBy: 10))
        if h > 0 {
            return String(format: "%d:%02d:%02d.%d", h, m, s, tenth)
        }
        return String(format: "%d:%02d.%d", m, s, tenth)
    }
}

struct VideoNoteSheet: View {
    let recording: Recording
    let onDelete: () -> Void
    @Binding var isPresented: Bool

    @State private var isPlaying = true
    @State private var sharePayload: SharePayload? = nil

    var body: some View {
        ZStack {
            Color.nocturneSheetBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    Text(formatDate(recording.createdAt))
                        .font(.system(size: 12, weight: .light, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))

                    HStack {
                        Button("Close", systemImage: "xmark") { isPresented = false }
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.white.opacity(0.4))

                        Spacer()

                        HStack(spacing: 18) {
                            Button("Share video", systemImage: "square.and.arrow.up") {
                                sharePayload = SharePayload(items: [recording.fileURL])
                            }
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.white.opacity(0.4))

                            Button("Delete video", systemImage: "trash") {
                                isPresented = false
                                onDelete()
                            }
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.red.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 36)

                // Circular player
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.03))
                        .frame(width: 280, height: 280)

                    if recording.fileURL.isReachable {
                        CircularVideoPlayer(url: recording.fileURL, isPlaying: $isPlaying)
                            .frame(width: 276, height: 276)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "video.slash")
                                .font(.system(size: 28, weight: .ultraLight))
                                .foregroundStyle(.white.opacity(0.2))
                            Text("File not found")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.2))
                        }
                    }

                    // Tap to pause/play
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 276, height: 276)
                        .contentShape(Circle())
                        .onTapGesture { isPlaying.toggle() }

                    // Pause indicator
                    if !isPlaying {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.4))
                                .frame(width: 56, height: 56)
                            Image(systemName: "play.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
                .padding(.bottom, 32)

                Text(formattedDuration(recording.duration))
                    .font(.system(size: 12, weight: .light, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.25))

                Spacer()
            }
        }
        .presentationDetents([.fraction(0.75)])
        .presentationBackground(Color.nocturneSheetBackground)
        .presentationDragIndicator(.hidden)
        .onDisappear { isPlaying = false }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(items: payload.items)
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
