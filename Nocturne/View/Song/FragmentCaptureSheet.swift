//
//  FragmentCaptureSheet.swift
//  Nocturne
//
//  Created by Damoon saber on 3/30/1405 AP.
//

import SwiftUI

struct FragmentCaptureSheet: View {
    @ObservedObject var fragmentsVM: FragmentsViewModel
    @Binding var isPresented: Bool

    @State private var text: String = ""
    @State private var selectedType: FragmentType = .lyric
    @FocusState private var isTextFocused: Bool

    @StateObject private var audioVM = AudioViewModel()
    @State private var pendingRiffRecording: Recording? = nil
    @State private var riffName: String = ""
    @FocusState private var isRiffNameFocused: Bool

    // A fragment isn't tied to a specific Song, but Recording storage and
    // AudioViewModel.startRecording(for:) both expect one — we use a
    // throwaway placeholder Song purely to namespace the recorded file.
    private let riffSongPlaceholder = Song(title: "fragment-riff", lyrics: "")

    var body: some View {
        ZStack {
            Color.nocturneSheetBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Capture a fragment")
                    .foregroundStyle(.white)
                    .font(.system(size: 16, weight: .medium))
                    .kerning(1)
                    .padding(.top, 28)

                // Type picker
                HStack(spacing: 8) {
                    ForEach(FragmentType.allCases, id: \.self) { type in
                        typeChip(type)
                    }
                }
                .padding(.horizontal, 20)

                if selectedType == .riff {
                    riffRecorder
                } else {
                    TextField("Rain on fluorescent streets...", text: $text, axis: .vertical)
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(.white)
                        .tint(.white)
                        .lineLimit(3...6)
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 20)
                        .focused($isTextFocused)
                }

                Button(action: save) {
                    Text("Save fragment")
                        .foregroundStyle(.black)
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSave ? Color.white : Color.white.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 20)
                }
                .disabled(!canSave)

                Button("Cancel") {
                    if audioVM.isRecording {
                        audioVM.stopRecording(for: riffSongPlaceholder) { _ in }
                    }
                    text = ""
                    pendingRiffRecording = nil
                    riffName = ""
                    isPresented = false
                }
                .foregroundStyle(.gray)
                .font(.system(size: 13))

                Spacer()
            }
        }
        .presentationDetents([.fraction(0.5)])
        .presentationBackground(Color.nocturneSheetBackground)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if selectedType != .riff {
                    isTextFocused = true
                }
            }
        }
        .onChange(of: selectedType) { _, newValue in
            // Stop any in-progress riff recording if the user switches away
            // from Riff mid-recording, so we don't leave a dangling recorder.
            if newValue != .riff && audioVM.isRecording {
                audioVM.stopRecording(for: riffSongPlaceholder) { _ in }
            }
        }
    }

    private var canSave: Bool {
        if selectedType == .riff {
            return pendingRiffRecording != nil
        }
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        if selectedType == .riff {
            guard let recording = pendingRiffRecording else { return }
            fragmentsVM.addRiff(recording: recording, name: riffName)
            pendingRiffRecording = nil
            riffName = ""
        } else {
            fragmentsVM.add(text: text, type: selectedType)
            text = ""
        }
        isPresented = false
    }

    // MARK: - Riff recorder UI

    private var riffRecorder: some View {
        VStack(spacing: 14) {
            if let recording = pendingRiffRecording {
                // Recorded — show a small playback row, allow re-record
                HStack(spacing: 12) {
                    Button(action: {
                        if audioVM.activeRecording?.id == recording.id {
                            audioVM.stopPlayback()
                        } else {
                            audioVM.play(recording)
                        }
                    }) {
                        Image(systemName: audioVM.activeRecording?.id == recording.id ? "stop.fill" : "play.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }

                    Text(audioVM.formattedTime(recording.duration))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))

                    Spacer()

                    Button(action: {
                        try? FileManager.default.removeItem(at: recording.fileURL)
                        pendingRiffRecording = nil
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 11))
                            Text("Re-record")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                )
                .padding(.horizontal, 20)

                TextField("Name this riff (optional)", text: $riffName)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.white)
                    .tint(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
                    .padding(.horizontal, 20)
                    .focused($isRiffNameFocused)
                    .onAppear { isRiffNameFocused = true }
            } else {
                // Idle or recording — show the record button
                Button(action: {
                    if audioVM.isRecording {
                        audioVM.stopRecording(for: riffSongPlaceholder) { recording in
                            pendingRiffRecording = recording
                        }
                    } else {
                        audioVM.startRecording(for: riffSongPlaceholder)
                    }
                }) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(audioVM.isRecording ? Color.red.opacity(0.9) : Color.white.opacity(0.08))
                                .frame(width: 22, height: 22)
                            if audioVM.isRecording {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.white)
                                    .frame(width: 8, height: 8)
                            } else {
                                Circle()
                                    .fill(.red.opacity(0.8))
                                    .frame(width: 9, height: 9)
                            }
                        }
                        Text(audioVM.isRecording ? audioVM.formattedTime(audioVM.recordingTime) : "Tap to record a riff")
                            .font(.system(size: 14, weight: .medium,
                                          design: audioVM.isRecording ? .monospaced : .default))
                            .foregroundStyle(audioVM.isRecording ? .red : .white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(audioVM.isRecording ? Color.red.opacity(0.1) : Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(audioVM.isRecording ? Color.red.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                    )
                    .padding(.horizontal, 20)
                }

                if !audioVM.permissionGranted {
                    Text("Microphone access is needed to record riffs")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.25))
                }
            }
        }
    }

    private func typeChip(_ type: FragmentType) -> some View {
        let c = type.color
        let color = Color(red: c.r, green: c.g, blue: c.b)
        let isSelected = selectedType == type

        return Button(action: { selectedType = type }) {
            HStack(spacing: 5) {
                Image(systemName: type.icon)
                    .font(.system(size: 10, weight: .medium))
                Text(type.rawValue)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(isSelected ? color.opacity(0.95) : .white.opacity(0.4))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.12) : Color.white.opacity(0.05))
                    .overlay(
                        Capsule().stroke(isSelected ? color.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 0.5)
                    )
            )
        }
    }
}
