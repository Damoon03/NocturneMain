//
//  LyricsWithChordsView.swift
//  Nocturne
//

import SwiftUI

struct LyricsWithChordsView: View {
    @ObservedObject var viewModel: SongViewModel
    let fontSize: CGFloat
    let lineSpacing: CGFloat
    let coordinateSpaceName: String
    @Binding var wordFrames: [String: CGRect]
    var isInteractive: Bool = true
    var lyricsFont: LyricsFontOption = .monospaced
    var onEditNote: ((Int) -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: lineSpacing) {
                ForEach(viewModel.lyricLineItems) { lineItem in
                    lineView(lineIndex: lineItem.index)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .padding(.bottom, 4)
            .coordinateSpace(name: coordinateSpaceName)
            .onPreferenceChange(WordFramePreferenceKey.self) { wordFrames = $0 }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func lineView(lineIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let label = viewModel.sectionLabel(forLineIndex: lineIndex) {
                SectionLabelView(label: label) {
                    if isInteractive { viewModel.removeSection(atLineIndex: lineIndex) }
                }
                .padding(.bottom, 4)
            }

            let lineChords = viewModel.chords(forLineIndex: lineIndex)
            let measureWords = !lineChords.isEmpty
            let lineIsRTL = TextDirection.isRTL(viewModel.lyricsLines[lineIndex])

            // ZStack alignment is intentionally fixed at .topLeading regardless
            // of line direction. FlowLayout already fills the full proposed
            // width (see FlowLayout.sizeThatFits), so this alignment has no
            // effect on how words are laid out — RTL row-filling is handled
            // entirely inside FlowLayout via `isRTL`. What alignment *does*
            // control is the default, pre-offset anchor point for the chord
            // capsule overlay below. Word frames are measured in absolute,
            // left-origin coordinates (WordFrameMeasurement uses
            // `geo.frame(in: .named(coordinateSpace))`), so the offset math
            // `frame.minX - 14` is only correct when the overlay's own
            // untransformed position also starts at the left edge — i.e.
            // alignment must stay .topLeading for both directions.
            ZStack(alignment: .topLeading) {
                FlowLayout(spacing: 0, isRTL: lineIsRTL) {
                    ForEach(viewModel.wordItems(inLine: lineIndex)) { wordItem in
                        HStack(spacing: 0) {
                            Text(wordItem.word)
                                .font(lyricsFont.font(size: fontSize))
                                .foregroundStyle(.white)
                                .wordFrameMeasurement(
                                    lineIndex: lineIndex,
                                    wordIndex: wordItem.index,
                                    coordinateSpace: coordinateSpaceName,
                                    enabled: measureWords
                                )
                            Text(" ")
                                .font(lyricsFont.font(size: fontSize))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.top, lineChords.isEmpty ? 0 : 22)
                .modifier(LineContextMenuModifier(
                    isInteractive: isInteractive,
                    hasSection: viewModel.sectionLabel(forLineIndex: lineIndex) != nil,
                    hasNote: viewModel.note(forLineIndex: lineIndex) != nil,
                    onAddSection: { type in
                        viewModel.addSection(type, atLineIndex: lineIndex)
                        HapticManager.impact(.light)
                    },
                    onRemoveSection: { viewModel.removeSection(atLineIndex: lineIndex) },
                    onEditNote: { onEditNote?(lineIndex) }
                ))

                ForEach(lineChords) { chord in
                    let key = "\(lineIndex):\(chord.wordIndex)"
                    if let frame = wordFrames[key] {
                        chordCapsuleGroup(for: chord, lineIndex: lineIndex)
                            .offset(x: frame.minX - 14, y: 0)
                    }
                }
            }

            if isInteractive, let note = viewModel.note(forLineIndex: lineIndex) {
                noteRow(note: note, lineIndex: lineIndex)
            }
        }
    }

    private func noteRow(note: SongNote, lineIndex: Int) -> some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(Color(red: 0.486, green: 0.553, blue: 0.651).opacity(0.4))
                .frame(width: 2)
            Text(note.text)
                .font(.system(size: fontSize - 1).italic())
                .foregroundStyle(Color(red: 0.486, green: 0.553, blue: 0.651).opacity(0.75))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
        }
        .padding(.top, 3)
        .contextMenu {
            Button(action: { onEditNote?(lineIndex) }) {
                Label("Edit note", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) {
                viewModel.removeNote(atLineIndex: lineIndex)
                HapticManager.impact(.medium)
            } label: {
                Label("Delete note", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private func chordCapsuleGroup(for chord: Chord, lineIndex: Int) -> some View {
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
                    .modifier(ChordDeleteMenuModifier(
                        isInteractive: isInteractive,
                        name: name,
                        onDelete: {
                            viewModel.deleteChord(name, atLineIndex: lineIndex, wordIndex: chord.wordIndex)
                            HapticManager.impact(.medium)
                        }
                    ))
            }
        }
    }
}

private struct LineContextMenuModifier: ViewModifier {
    let isInteractive: Bool
    let hasSection: Bool
    let hasNote: Bool
    let onAddSection: (SectionType) -> Void
    let onRemoveSection: () -> Void
    let onEditNote: () -> Void

    func body(content: Content) -> some View {
        if isInteractive {
            content.contextMenu {
                ForEach(SectionType.allCases, id: \.self) { type in
                    Button(action: { onAddSection(type) }) {
                        Label(type.rawValue, systemImage: "tag")
                    }
                }
                if hasSection {
                    Divider()
                    Button(role: .destructive, action: onRemoveSection) {
                        Label("Remove label", systemImage: "trash")
                    }
                }
                Divider()
                Button(action: onEditNote) {
                    Label(hasNote ? "Edit note" : "Add note", systemImage: "note.text")
                }
            }
        } else {
            content
        }
    }
}

private struct ChordDeleteMenuModifier: ViewModifier {
    let isInteractive: Bool
    let name: String
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        if isInteractive {
            content.contextMenu {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete \(name)", systemImage: "trash")
                }
            }
        } else {
            content
        }
    }
}
