//
//  RhymeSheetView.swift
//  Nocturne
//

import SwiftUI

struct RhymeSheetView: View {
    @ObservedObject var viewModel: SongViewModel

    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var sourceSyllables: Int? = nil
    @State private var candidates: [RhymeCandidate] = []
    @State private var filter: SyllableFilter = .all

    private var visible: [RhymeCandidate] {
        Array(RhymeService.filterBySyllables(candidates, filter: filter).prefix(40))
    }

    var body: some View {
        ZStack {
            Color.nocturneSheetBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(viewModel.rhymeSourceWord.isEmpty ? "Rhymes" : "Rhymes with \(viewModel.rhymeSourceWord)")
                        .foregroundStyle(.white)
                        .font(.headline)
                        .kerning(1)

                    if let syll = sourceSyllables {
                        Text("\(syll) syllable\(syll == 1 ? "" : "s")")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .padding(.top, 24)

                HStack(spacing: 8) {
                    filterChip(.all, label: "All")
                    filterChip(.count(1), label: "1")
                    filterChip(.count(2), label: "2")
                    filterChip(.count(3), label: "3")
                    filterChip(.count(4), label: "4+")
                }
                .padding(.horizontal, 20)

                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                } else if let errorMessage {
                    Spacer()
                    Text(errorMessage)
                        .foregroundStyle(.white.opacity(0.3))
                        .font(.system(size: 13))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                } else if visible.isEmpty {
                    Spacer()
                    Text("Nothing in this syllable filter.")
                        .foregroundStyle(.white.opacity(0.3))
                        .font(.system(size: 13))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(visible) { candidate in
                                rhymeRow(candidate)
                                Divider()
                                    .background(Color.white.opacity(0.06))
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                Button("Cancel", action: viewModel.cancelRhymeSheet)
                    .foregroundStyle(.gray)
                    .font(.system(size: 13))
                    .padding(.bottom, 12)
            }
        }
        .presentationDetents([.fraction(0.6), .large])
        .presentationBackground(Color.nocturneSheetBackground)
        .task(id: viewModel.rhymeSourceWord) {
            await load()
        }
    }

    private func filterChip(_ value: SyllableFilter, label: String) -> some View {
        let isSelected = filter == value
        return Button(action: {
            filter = value
            HapticManager.selection()
        }) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? .white.opacity(0.95) : .white.opacity(0.4))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
                        .overlay(Capsule().stroke(Color.white.opacity(isSelected ? 0.3 : 0.08), lineWidth: 0.5))
                )
        }
    }

    private func rhymeRow(_ candidate: RhymeCandidate) -> some View {
        HStack(spacing: 10) {
            Button(action: {
                HapticManager.impact(.medium)
                viewModel.replaceRhymeTarget(with: candidate.word)
            }) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(candidate.word)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                    Text(metaText(candidate))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.25))
                        .lineLimit(1)
                    Spacer()
                }
                .fixedSize(horizontal: false, vertical: true)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: {
                HapticManager.impact(.light)
                viewModel.insertRhymeAsNewLine(candidate.word)
            }) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(.vertical, 10)
    }

    private func metaText(_ c: RhymeCandidate) -> String {
        var parts: [String] = []
        if c.kind == .near { parts.append("near") }
        if let s = c.syllables { parts.append("\(s)") }
        return parts.joined(separator: " · ")
    }

    private func load() async {
        let word = viewModel.rhymeSourceWord
        guard !word.isEmpty else {
            candidates = []
            errorMessage = nil
            sourceSyllables = nil
            return
        }

        isLoading = true
        errorMessage = nil
        filter = .all

        do {
            let result = try await RhymeService.lookupRhymes(for: word)
            sourceSyllables = result.sourceSyllables
            candidates = result.rhymes
            if let s = result.sourceSyllables, (1...3).contains(s) {
                filter = .count(s)
            } else if let s = result.sourceSyllables, s >= 4 {
                filter = .count(4)
            }
            if result.rhymes.isEmpty {
                errorMessage = "No rhymes found for this word."
            }
        } catch {
            candidates = []
            errorMessage = "Couldn't reach rhyme suggestions. Check your connection."
        }

        isLoading = false
    }
}

#Preview {
    RhymeSheetView(viewModel: SongViewModel(song: Song()))
}
