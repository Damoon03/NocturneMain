//
//  FragmentEditSheet.swift
//  Nocturne
//
//  Created by Damoon saber on 4/3/1405 AP.
//

import SwiftUI

struct FragmentEditSheet: View {
    @ObservedObject var fragmentsVM: FragmentsViewModel
    let fragment: Fragment
    var onDismiss: () -> Void

    @State private var text: String
    @State private var selectedType: FragmentType
    @StateObject private var audioVM = AudioViewModel()

    init(fragmentsVM: FragmentsViewModel, fragment: Fragment, onDismiss: @escaping () -> Void) {
        self.fragmentsVM = fragmentsVM
        self.fragment = fragment
        self.onDismiss = onDismiss
        _text = State(initialValue: fragment.text)
        _selectedType = State(initialValue: fragment.type)
    }

    var body: some View {
        ZStack {
            Color.nocturneSheetBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button("Cancel") { onDismiss() }
                        .foregroundStyle(.white.opacity(0.4))
                        .font(.system(size: 14))
                    Spacer()
                    Text("Edit Fragment")
                        .foregroundStyle(.white)
                        .font(.system(size: 15, weight: .medium))
                        .kerning(0.5)
                    Spacer()
                    Button("Save") { save() }
                        .foregroundStyle(.white.opacity(0.85))
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // Type picker (disabled for riff since audio can't change here)
                if fragment.type != .riff {
                    HStack(spacing: 8) {
                        ForEach(FragmentType.allCases.filter { $0 != .riff }, id: \.self) { type in
                            typeChip(type)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Text editor
                if fragment.type == .riff {
                    // Riff: only name is editable, plus playback
                    VStack(spacing: 14) {
                        if let recording = fragment.audioRecording {
                            riffPlaybackRow(recording)
                        }
                        TextField("Name this riff (optional)", text: $text)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(.white)
                            .tint(.white)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
                            .padding(.horizontal, 20)
                    }
                } else {
                    TextField("", text: $text, axis: .vertical)
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(.white)
                        .tint(.white)
                        .lineLimit(4...10)
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                        .padding(.horizontal, 20)
                }

                Spacer()
            }
        }
        .presentationDetents([.fraction(0.55), .large])
        .presentationBackground(Color.nocturneSheetBackground)
    }

    private func save() {
        var updated = fragment
        updated.text = text
        updated.type = selectedType
        fragmentsVM.update(updated)
        onDismiss()
    }

    private func typeChip(_ type: FragmentType) -> some View {
        let c = type.color
        let color = Color(red: c.r, green: c.g, blue: c.b)
        let isSelected = selectedType == type

        return Button(action: { selectedType = type }) {
            HStack(spacing: 5) {
                Image(systemName: type.icon).font(.system(size: 10, weight: .medium))
                Text(type.rawValue).font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(isSelected ? color.opacity(0.95) : .white.opacity(0.4))
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.12) : Color.white.opacity(0.05))
                    .overlay(Capsule().stroke(isSelected ? color.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 0.5))
            )
        }
    }

    private func riffPlaybackRow(_ recording: Recording) -> some View {
        let isPlaying = audioVM.activeRecording?.id == recording.id
        return HStack(spacing: 12) {
            Button(action: {
                if isPlaying { audioVM.stopPlayback() } else { audioVM.play(recording) }
            }) {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            Text(audioVM.formattedTime(recording.duration))
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        )
        .padding(.horizontal, 20)
    }
}
