//
//  ContentView.swift
//  Nocturne
//
//  Created by Damoon saber on 3/28/1405 AP.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: SongViewModel
    @StateObject private var audioVM = AudioViewModel()
    @ObservedObject var fragmentsVM: FragmentsViewModel
    @ObservedObject var settings: SettingsStore

    @State private var isFocused: Bool = false
    @State private var showingRecordings = false
    @State private var showingFragments = false
    @State private var lyricsOpacity: Double = 0
    @State private var wordFrames: [String: CGRect] = [:]
    @State private var chordWidths: [UUID: CGFloat] = [:]

    @State private var editingNoteLineIndex: Int? = nil
    @State private var noteText: String = ""
    @State private var shareItems: [Any]? = nil

    var onSave: ((Song) -> Void)?
    var onDismiss: ((Song) -> Void)?

    @Environment(\.scenePhase) private var scenePhase

    let lineSpacing: CGFloat = 10
    var fontSize: CGFloat { settings.fontSize }

    init(
        song: Song,
        fragmentsVM: FragmentsViewModel,
        settings: SettingsStore,
        onSave: ((Song) -> Void)? = nil,
        onDismiss: ((Song) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: SongViewModel(song: song, onUpdate: onSave))
        self.fragmentsVM = fragmentsVM
        self.settings = settings
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: - Title
                HStack {
                    TextField("untitled", text: $viewModel.song.title)
                        .foregroundStyle(.white.opacity(0.9))
                        .font(.system(size: 16, weight: .light))
                        .kerning(2)
                        .multilineTextAlignment(.center)
                }

                // MARK: - Nav row
                HStack(spacing: 16) {
                    Button(action: {
                        HapticManager.impact(.light)
                        onDismiss?(viewModel.song)
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .accessibilityLabel("Back to library")
                    Spacer()
                    saveStatusLabel
                    Button(action: {
                        HapticManager.impact(.light)
                        if let items = SongShareOptions.linkItems(for: viewModel.song) {
                            shareItems = items
                        }
                    }) {
                        Image(systemName: "link")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Button(action: { showingFragments = true }) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 20)

                // MARK: - Toolbar
                HStack(spacing: 12) {
                    Button(action: { showingRecordings = true }) {
                        HStack(spacing: 5) {
                            ZStack {
                                Circle()
                                    .fill(audioVM.isRecording ? Color.red.opacity(0.9) : Color.white.opacity(0.08))
                                    .frame(width: 16, height: 16)
                                if audioVM.isRecording {
                                    RoundedRectangle(cornerRadius: 2).fill(.white).frame(width: 6, height: 6)
                                } else {
                                    Circle().fill(.red.opacity(0.8)).frame(width: 6, height: 6)
                                }
                            }
                            Text(audioVM.isRecording ? audioVM.formattedTime(audioVM.recordingTime) : "Record")
                                .font(.system(size: 12, weight: .medium,
                                              design: audioVM.isRecording ? .monospaced : .default))
                                .foregroundStyle(audioVM.isRecording ? .red : .white.opacity(0.7))
                        }
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(audioVM.isRecording ? Color.red.opacity(0.12) : Color.white.opacity(0.06))
                                .overlay(Capsule().stroke(
                                    audioVM.isRecording ? Color.red.opacity(0.4) : Color.white.opacity(0.1),
                                    lineWidth: 0.5))
                        )
                    }

                    Spacer()

                    if viewModel.isPickingWord {
                        EmptyView()
                    } else if isFocused {
                        Button("Done") {
                            isFocused = false
                            HapticManager.impact(.light)
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(minWidth: 70).padding(.horizontal, 2).padding(.vertical, 7)
                        .background(
                            Capsule().fill(Color.white.opacity(0.06))
                                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                        )
                    } else {
                        Button(action: {
                            viewModel.startAnnotating()
                            HapticManager.impact(.light)
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "music.note").font(.system(size: 11, weight: .medium))
                                Text("Chord").font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(minWidth: 70).padding(.horizontal, 2).padding(.vertical, 7)
                            .background(
                                Capsule().fill(Color.white.opacity(0.06))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                            )
                        }
                    }
                }
                .padding(.horizontal, 28).padding(.bottom, 10)
                .animation(.easeInOut(duration: 0.2), value: viewModel.hasChords)

                // Picking word prompt
                if viewModel.isPickingWord {
                    HStack {
                        Image(systemName: "hand.tap").font(.system(size: 11)).foregroundStyle(.white.opacity(0.3))
                        Text("Tap a word to place").foregroundStyle(.white.opacity(0.4)).font(.system(size: 12, design: .monospaced))
                        Text("\"\(viewModel.pendingAnnotation)\"").foregroundStyle(.white.opacity(0.7)).font(.system(size: 12, weight: .medium, design: .monospaced))
                        Text("above it").foregroundStyle(.white.opacity(0.4)).font(.system(size: 12, design: .monospaced))
                        Spacer()
                        Button("Cancel", action: viewModel.cancelPickingWord).foregroundStyle(.white.opacity(0.4)).font(.system(size: 12))
                    }
                    .padding(.horizontal, 28).padding(.bottom, 10)
                }

                // Section label strip (edit mode)
                if isFocused && !viewModel.song.sectionLabels.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(viewModel.song.sectionLabels.sorted { $0.lineIndex < $1.lineIndex }) { label in
                                let c = label.type.color
                                let color = Color(red: c.r, green: c.g, blue: c.b)
                                Text(label.type.rawValue.uppercased())
                                    .font(.system(size: 8, weight: .semibold, design: .monospaced)).kerning(1)
                                    .foregroundStyle(color.opacity(0.8))
                                    .padding(.horizontal, 7).padding(.vertical, 3)
                                    .background(Capsule().fill(color.opacity(0.08)).overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 0.5)))
                            }
                        }
                        .padding(.horizontal, 28)
                    }
                    .padding(.bottom, 8)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                }

                // MARK: - Main text area
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.04))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.07), lineWidth: 0.5))

                    if viewModel.isPickingWord {
                        wordPickerView.transition(.opacity)
                    } else {
                        ZStack {
                            LyricsTextView(
                                text: $viewModel.song.lyrics,
                                fontSize: fontSize,
                                lineSpacing: lineSpacing,
                                isFocused: $isFocused
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(isFocused ? 1 : 0)
                            .onChange(of: isFocused) { _, newValue in
                                if !newValue { viewModel.runAutoSectionDetection() }
                            }

                            if !isFocused {
                                lyricsDisplayView
                                    .contentShape(Rectangle())
                                    .onTapGesture { isFocused = true }
                                    .transition(.identity)
                                    .opacity(lyricsOpacity)
                            }
                        }
                        .animation(nil, value: isFocused)
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 16)

                Spacer().frame(height: 0)
            }
        }
        .sheet(isPresented: Binding(
            get: { editingNoteLineIndex != nil },
            set: { if !$0 { editingNoteLineIndex = nil } }
        )) {
            noteEditorSheet
        }
        .sheet(isPresented: $viewModel.isAnnotating) {
            ChordSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingRecordings) {
            RecordingsSheetView(
                audioVM: audioVM,
                song: viewModel.song,
                onSaveRecording: { recording in
                    viewModel.song.recordings.append(recording)
                    HapticManager.success()
                },
                onDeleteRecording: { recording in
                    viewModel.song.recordings.removeAll { $0.id == recording.id }
                }
            )
        }
        .sheet(isPresented: $showingFragments) {
            SongFragmentsSheet(fragmentsVM: fragmentsVM, songID: viewModel.song.id)
        }
        .sheet(isPresented: Binding(
            get: { shareItems != nil },
            set: { if !$0 { shareItems = nil } }
        )) {
            if let items = shareItems { ShareSheet(items: items) }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.9)) { lyricsOpacity = 1 }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background || phase == .inactive {
                onSave?(viewModel.song)
            }
        }
    }

    @ViewBuilder
    private var saveStatusLabel: some View {
        switch viewModel.saveState {
        case .saved:
            EmptyView()
        case .saving:
            Text("Saving…")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.25))
        case .unsaved:
            Text("Unsaved")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.2))
        }
    }

    // MARK: - Note editor sheet
    private var noteEditorSheet: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                HStack {
                    Button("Cancel") { editingNoteLineIndex = nil }
                        .foregroundStyle(.white.opacity(0.4)).font(.system(size: 14))
                    Spacer()
                    Text("Line Note")
                        .foregroundStyle(.white).font(.system(size: 15, weight: .medium))
                    Spacer()
                    Button("Save") {
                        if let lineIndex = editingNoteLineIndex {
                            viewModel.addNote(noteText, atLineIndex: lineIndex)
                            HapticManager.success()
                        }
                        editingNoteLineIndex = nil
                    }
                    .foregroundStyle(.white.opacity(0.85)).font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 20).padding(.top, 24)

                TextField("Add a note for this line…", text: $noteText, axis: .vertical)
                    .font(.system(size: 14).italic())
                    .foregroundStyle(Color(red: 0.486, green: 0.553, blue: 0.651))
                    .tint(.white)
                    .lineLimit(3)
                    .padding()
                    .background(Color(red: 0.486, green: 0.553, blue: 0.651).opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.486, green: 0.553, blue: 0.651).opacity(0.2), lineWidth: 0.5))
                    .padding(.horizontal, 20)

                if let idx = editingNoteLineIndex, viewModel.note(forLineIndex: idx) != nil {
                    Button(role: .destructive) {
                        viewModel.removeNote(atLineIndex: idx)
                        editingNoteLineIndex = nil
                    } label: {
                        Label("Remove note", systemImage: "trash")
                            .font(.system(size: 13)).foregroundStyle(.red.opacity(0.6))
                    }
                }
                Spacer()
            }
        }
        .presentationDetents([.fraction(0.45)])
        .presentationBackground(Color.black)
    }

    // MARK: - Lyrics display (read mode)
    private var lyricsDisplayView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: lineSpacing) {
                ForEach(Array(viewModel.lyricsLines.enumerated()), id: \.offset) { lineIndex, _ in
                    VStack(alignment: .leading, spacing: 2) {

                        if let label = viewModel.sectionLabel(forLineIndex: lineIndex) {
                            SectionLabelView(label: label) { viewModel.removeSection(atLineIndex: lineIndex) }
                                .padding(.bottom, 4)
                        }

                        let lineChords = viewModel.chords(forLineIndex: lineIndex)

                        ZStack(alignment: .topLeading) {
                            FlowLayout(spacing: 0) {
                                ForEach(Array(viewModel.wordsInLine(lineIndex).enumerated()), id: \.offset) { wordIndex, word in
                                    HStack(spacing: 0) {
                                        Text(word)
                                            .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                                            .foregroundStyle(.white)
                                            .background(GeometryReader { geo in
                                                Color.clear.preference(
                                                    key: WordFramePreferenceKey.self,
                                                    value: ["\(lineIndex):\(wordIndex)": geo.frame(in: .named("lyricsCoordSpace"))]
                                                )
                                            })
                                        Text(" ")
                                            .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .padding(.top, lineChords.isEmpty ? 0 : 22)
                            .contextMenu {
                                ForEach(SectionType.allCases, id: \.self) { type in
                                    Button(action: {
                                        viewModel.addSection(type, atLineIndex: lineIndex)
                                        HapticManager.impact(.light)
                                    }) {
                                        Label(type.rawValue, systemImage: "tag")
                                    }
                                }
                                if viewModel.sectionLabel(forLineIndex: lineIndex) != nil {
                                    Divider()
                                    Button(role: .destructive) {
                                        viewModel.removeSection(atLineIndex: lineIndex)
                                    } label: {
                                        Label("Remove label", systemImage: "trash")
                                    }
                                }
                                Divider()
                                Button(action: {
                                    noteText = viewModel.note(forLineIndex: lineIndex)?.text ?? ""
                                    editingNoteLineIndex = lineIndex
                                }) {
                                    Label(
                                        viewModel.note(forLineIndex: lineIndex) != nil ? "Edit note" : "Add note",
                                        systemImage: "note.text"
                                    )
                                }
                            }

                            ForEach(lineChords) { chord in
                                let key = "\(lineIndex):\(chord.wordIndex)"
                                if let frame = wordFrames[key] {
                                    chordCapsuleGroup(for: chord, lineIndex: lineIndex)
                                        .background(GeometryReader { geo in
                                            Color.clear.onAppear { chordWidths[chord.id] = geo.size.width }
                                        })
                                        .offset(x: frame.minX - 14, y: 0)
                                }
                            }
                        }

                        // MARK: - Note row (long press → context menu)
                        if let note = viewModel.note(forLineIndex: lineIndex) {
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
                                Button(action: {
                                    noteText = note.text
                                    editingNoteLineIndex = lineIndex
                                }) {
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
                    }
                }
            }
            .padding(.horizontal, 15).padding(.vertical, 10)
            .coordinateSpace(name: "lyricsCoordSpace")
            .onPreferenceChange(WordFramePreferenceKey.self) { wordFrames = $0 }
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
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.deleteChord(name, atLineIndex: lineIndex, wordIndex: chord.wordIndex)
                            HapticManager.impact(.medium)
                        } label: { Label("Delete \(name)", systemImage: "trash") }
                    }
            }
        }
    }

    // MARK: - Word picker
    private var wordPickerView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: lineSpacing) {
                ForEach(Array(viewModel.lyricsLines.enumerated()), id: \.offset) { lineIndex, _ in
                    VStack(alignment: .leading, spacing: 2) {
                        if let label = viewModel.sectionLabel(forLineIndex: lineIndex) {
                            SectionLabelView(label: label) { viewModel.removeSection(atLineIndex: lineIndex) }
                                .padding(.bottom, 4)
                        }
                        let lineChords = viewModel.chords(forLineIndex: lineIndex)
                        if !lineChords.isEmpty {
                            HStack(spacing: 10) {
                                ForEach(lineChords) { chord in chordCapsuleGroup(for: chord, lineIndex: lineIndex) }
                            }
                            .padding(.bottom, 2)
                        }
                        FlowLayout(spacing: 0) {
                            ForEach(Array(viewModel.wordsInLine(lineIndex).enumerated()), id: \.offset) { wordIndex, word in
                                let globalIndex = globalWordIndex(lineIndex: lineIndex, wordIndex: wordIndex)
                                Button(action: {
                                    viewModel.insertAnnotation(beforeWordAtIndex: globalIndex)
                                    HapticManager.impact(.medium)
                                }) {
                                    Text(word + " ")
                                        .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                                        .foregroundStyle(.white)
                                        .underline(color: .white.opacity(0.25))
                                        .fixedSize()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, lineSpacing / 2)
                    }
                }
            }
            .padding(.horizontal, 15).padding(.vertical, 10)
        }
    }

    private func globalWordIndex(lineIndex: Int, wordIndex: Int) -> Int {
        var count = 0
        for i in 0..<lineIndex { count += viewModel.wordsInLine(i).count }
        return count + wordIndex
    }
}

// MARK: - Word frame measurement
struct WordFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

#Preview {
    ContentView(
        song: Song(title: "Untitled", lyrics: "Hello darkness, my old friend"),
        fragmentsVM: FragmentsViewModel(),
        settings: SettingsStore()
    )
}
