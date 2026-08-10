//
//  ContentView.swift
//  Nocturne
//
//  Created by Damoon saber on 3/28/1405 AP.
//
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

    @State private var editingNote: NoteEditContext? = nil
    @State private var noteText: String = ""
    @State private var sharePayload: SharePayload? = nil
    @State private var showingSectionChooser = false          // ← added

    var onSave: ((Song) async -> Bool)?
    var onDismiss: ((Song) async -> Void)?

    @Environment(\.scenePhase) private var scenePhase

    let lineSpacing: CGFloat = 10
    var fontSize: CGFloat { settings.fontSize }

    init(
        song: Song,
        fragmentsVM: FragmentsViewModel,
        settings: SettingsStore,
        onSave: ((Song) async -> Bool)? = nil,
        onDismiss: ((Song) async -> Void)? = nil
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
                Spacer()
                
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
                        Task { await onDismiss?(viewModel.song) }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .accessibilityLabel("Back to library")
                    Spacer()
                    saveStatusLabel
                    Button("Share song link", systemImage: "link") {
                        HapticManager.impact(.light)
                        if let items = SongShareOptions.linkItems(for: viewModel.song) {
                            sharePayload = SharePayload(items: items)
                        }
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.white.opacity(0.4))
                    Button("Song fragments", systemImage: "lightbulb") { showingFragments = true }
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 20)

                // MARK: - Toolbar
                HStack(spacing: 12) {
                    if isFocused {
                        Button(action: {
                            isFocused = false
                            viewModel.startRhymePicking()
                            HapticManager.impact(.light)
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "quote.bubble").font(.system(size: 11, weight: .medium))
                                Text("Rhyme").font(.system(size: 12, weight: .medium)).lineLimit(1)
                            }
                            .fixedSize()
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(
                                Capsule().fill(Color.white.opacity(0.06))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                            )
                        }
                        .accessibilityLabel("Find rhymes")
                    } else {
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
                        .accessibilityLabel(audioVM.isRecording ? "Stop recording" : "Open recordings")
                    }

                    Spacer()

                    if viewModel.isPickingWord || viewModel.isRhymePicking || viewModel.isPickingLineForSection || viewModel.isPickingLineForNote {
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

                // Picking word prompt (chord placement)
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

                // Picking word prompt (rhyme lookup)
                if viewModel.isRhymePicking {
                    HStack {
                        Image(systemName: "hand.tap").font(.system(size: 11)).foregroundStyle(.white.opacity(0.3))
                        Text("Tap a word for rhymes").foregroundStyle(.white.opacity(0.4)).font(.system(size: 12, design: .monospaced))
                        Spacer()
                        Button("Cancel", action: viewModel.cancelRhymePicking).foregroundStyle(.white.opacity(0.4)).font(.system(size: 12))
                    }
                    .padding(.horizontal, 28).padding(.bottom, 10)
                }

                // Picking line prompt (section placement)
                if viewModel.isPickingLineForSection {
                    HStack {
                        Image(systemName: "hand.tap").font(.system(size: 11)).foregroundStyle(.white.opacity(0.3))
                        Text("Tap a line for").foregroundStyle(.white.opacity(0.4)).font(.system(size: 12, design: .monospaced))
                        Text(viewModel.pendingSectionType?.rawValue ?? "").foregroundStyle(.white.opacity(0.7)).font(.system(size: 12, weight: .medium, design: .monospaced))
                        Spacer()
                        Button("Cancel", action: viewModel.cancelPickingLineForSection).foregroundStyle(.white.opacity(0.4)).font(.system(size: 12))
                    }
                    .padding(.horizontal, 28).padding(.bottom, 10)
                }

                // Picking line prompt (note placement)          ← NEW
                if viewModel.isPickingLineForNote {
                    HStack {
                        Image(systemName: "hand.tap").font(.system(size: 11)).foregroundStyle(.white.opacity(0.3))
                        Text("Choose a line to attach your note")
                            .foregroundStyle(.white.opacity(0.4))
                            .font(.system(size: 12, design: .monospaced))
                            .lineLimit(1)                    // ← forces single line
                            .minimumScaleFactor(0.85)        // ← shrinks slightly if needed
                        Spacer()
                        Button("Cancel", action: viewModel.cancelPickingLineForNote)
                            .foregroundStyle(.white.opacity(0.4))
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 28).padding(.bottom, 10)
                }

                // Section label strip (edit mode)
                if isFocused {
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
                            Button(action: {
                                showingSectionChooser = true
                                HapticManager.impact(.light)
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "plus").font(.system(size: 8, weight: .semibold))
                                }
                                .foregroundStyle(.white.opacity(0.4))
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(Capsule().fill(Color.white.opacity(0.05)).overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5)))
                            }
                            .frame(width: 40, height: 40)
                            .padding(.leading, -5)
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, -10)
                    }
                    .transition(.opacity)
                    .motionAwareAnimation(.easeInOut(duration: 0.2), value: isFocused)
                }

                // MARK: - Main text area
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.04))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.07), lineWidth: 0.5))

                    Group {
                        if viewModel.isPickingWord {
                            wordPickerView
                        } else if viewModel.isRhymePicking {
                            rhymePickerView
                        } else if viewModel.isPickingLineForSection {
                            sectionLinePickerView
                        } else if viewModel.isPickingLineForNote {          // ← NEW
                            noteLinePickerView
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
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .contentShape(Rectangle())
                                        .onTapGesture { isFocused = true }
                                        .transition(.identity)
                                        .opacity(lyricsOpacity)
                                }
                            }
                            .animation(nil, value: isFocused)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .sheet(item: $editingNote) { context in
            NoteEditorSheet(
                lineIndex: context.lineIndex,
                noteText: $noteText,
                viewModel: viewModel,
                onDismiss: { editingNote = nil }
            )
        }
        .sheet(isPresented: $viewModel.isAnnotating) {
            ChordSheetView(viewModel: viewModel, settings: settings)
        }
        .sheet(isPresented: $viewModel.isRhymeSheetPresented) {
            RhymeSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingSectionChooser) {
            SectionTypeChooserSheet(
                onSelect: { type in
                    viewModel.startPickingLineForSection(type)   // ← adjust name if different in your ViewModel
                    showingSectionChooser = false
                },
                onAddNote: {
                    showingSectionChooser = false
                    viewModel.startPickingNote()
                },
                onCancel: {
                    showingSectionChooser = false
                }
            )
        }
        .sheet(isPresented: $showingRecordings) {
            RecordingsSheetView(
                audioVM: audioVM,
                viewModel: viewModel,
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
        .sheet(item: $sharePayload) { payload in
            ShareSheet(items: payload.items)
        }
        .onAppear {
            if UIAccessibility.isReduceMotionEnabled {
                lyricsOpacity = 1
            } else {
                withAnimation(.easeIn(duration: 0.9)) { lyricsOpacity = 1 }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background || phase == .inactive {
                Task { _ = await onSave?(viewModel.song) }
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
    struct NoteEditorSheet: View {
        let lineIndex: Int
        @Binding var noteText: String
        let viewModel: SongViewModel
        let onDismiss: () -> Void

        @FocusState private var isNoteFocused: Bool

        var body: some View {
            ZStack {
                Color.nocturneSheetBackground.ignoresSafeArea()
                VStack(spacing: 20) {
                    HStack {
                        Button("Cancel") {
                            isNoteFocused = false
                            onDismiss()
                        }
                        .foregroundStyle(.white.opacity(0.4))
                        .font(.system(size: 14))

                        Spacer()

                        Text("Line Note")
                            .foregroundStyle(.white)
                            .font(.system(size: 15, weight: .medium))

                        Spacer()

                        Button("Save") {
                            isNoteFocused = false
                            viewModel.addNote(noteText, atLineIndex: lineIndex)
                            HapticManager.success()
                            onDismiss()
                        }
                        .foregroundStyle(.white.opacity(0.85))
                        .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    TextField("Add a note for this line…", text: $noteText, axis: .vertical)
                        .font(.system(size: 14).italic())
                        .foregroundStyle(Color(red: 0.486, green: 0.553, blue: 0.651))
                        .tint(.white)
                        .lineLimit(3)
                        .padding()
                        .background(Color(red: 0.486, green: 0.553, blue: 0.651).opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.486, green: 0.553, blue: 0.651).opacity(0.2), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 20)
                        .focused($isNoteFocused)

                    if viewModel.note(forLineIndex: lineIndex) != nil {
                        Button(role: .destructive) {
                            isNoteFocused = false
                            viewModel.removeNote(atLineIndex: lineIndex)
                            onDismiss()
                        } label: {
                            Label("Remove note", systemImage: "trash")
                                .font(.system(size: 13))
                                .foregroundStyle(.red.opacity(0.6))
                        }
                    }

                    Spacer()
                }
            }
            .presentationDetents([.fraction(0.45)])
            .presentationBackground(Color.nocturneSheetBackground)
            .onAppear {
                // Force keyboard to stay closed
                isNoteFocused = false
                DispatchQueue.main.async {
                    isNoteFocused = false
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
            }
        }
    }
    // MARK: - Lyrics display (read mode)
    private var lyricsDisplayView: some View {
        LyricsWithChordsView(
            viewModel: viewModel,
            fontSize: fontSize,
            lineSpacing: lineSpacing,
            coordinateSpaceName: "lyricsCoordSpace",
            wordFrames: $wordFrames,
            isInteractive: true,
            onEditNote: { lineIndex in
                noteText = viewModel.note(forLineIndex: lineIndex)?.text ?? ""
                editingNote = NoteEditContext(lineIndex: lineIndex)
            }
        )
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
                ForEach(viewModel.lyricLineItems) { lineItem in
                    let lineIndex = lineItem.index
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
                            ForEach(viewModel.wordItems(inLine: lineIndex)) { wordItem in
                                let globalIndex = globalWordIndex(lineIndex: lineIndex, wordIndex: wordItem.index)
                                Button(action: {
                                    viewModel.insertAnnotation(beforeWordAtIndex: globalIndex)
                                    HapticManager.impact(.medium)
                                }) {
                                    Text(wordItem.word + " ")
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
            .padding(.horizontal, 15).padding(.vertical, 10).padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Word picker (rhyme lookup)
    private var rhymePickerView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: lineSpacing) {
                ForEach(viewModel.lyricLineItems) { lineItem in
                    let lineIndex = lineItem.index
                    VStack(alignment: .leading, spacing: 2) {
                        if let label = viewModel.sectionLabel(forLineIndex: lineIndex) {
                            SectionLabelView(label: label) { viewModel.removeSection(atLineIndex: lineIndex) }
                                .padding(.bottom, 4)
                        }
                        FlowLayout(spacing: 0) {
                            ForEach(viewModel.wordItems(inLine: lineIndex)) { wordItem in
                                Button(action: {
                                    viewModel.selectRhymeTarget(lineIndex: lineIndex, wordIndex: wordItem.index)
                                    HapticManager.impact(.medium)
                                }) {
                                    Text(wordItem.word + " ")
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
            .padding(.horizontal, 15).padding(.vertical, 10).padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Line picker (section placement)
    private var sectionLinePickerView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: lineSpacing) {
                ForEach(viewModel.lyricLineItems) { lineItem in
                    let lineIndex = lineItem.index
                    let lineText = viewModel.lyricsLines[lineIndex]
                    let isBlank = lineText.trimmingCharacters(in: .whitespaces).isEmpty

                    Button(action: {
                        viewModel.placePendingSection(atLineIndex: lineIndex)
                        HapticManager.impact(.medium)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                if let label = viewModel.sectionLabel(forLineIndex: lineIndex) {
                                    let c = label.type.color
                                    let color = Color(red: c.r, green: c.g, blue: c.b)
                                    Text(label.type.rawValue.uppercased())
                                        .font(.system(size: 8, weight: .semibold, design: .monospaced)).kerning(1)
                                        .foregroundStyle(color.opacity(0.8))
                                        .padding(.horizontal, 7).padding(.vertical, 3)
                                        .background(Capsule().fill(color.opacity(0.08)).overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 0.5)))
                                }
                                Text(isBlank ? "(empty line)" : lineText)
                                    .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                                    .foregroundStyle(isBlank ? .white.opacity(0.2) : .white)
                                    .italic(isBlank)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 15).padding(.vertical, 10).padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Line picker (note placement)          ← NEW
    private var noteLinePickerView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: lineSpacing) {
                ForEach(viewModel.lyricLineItems) { lineItem in
                    let lineIndex = lineItem.index
                    let lineText = viewModel.lyricsLines[lineIndex]
                    let isBlank = lineText.trimmingCharacters(in: .whitespaces).isEmpty

                    Button(action: {
                        noteText = viewModel.note(forLineIndex: lineIndex)?.text ?? ""
                        editingNote = NoteEditContext(lineIndex: lineIndex)
                        
                        // Dismiss lyrics keyboard + exit picking mode
                        isFocused = false
                        viewModel.cancelPickingLineForNote()
                        
                        HapticManager.impact(.medium)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                if let label = viewModel.sectionLabel(forLineIndex: lineIndex) {
                                    let c = label.type.color
                                    let color = Color(red: c.r, green: c.g, blue: c.b)
                                    Text(label.type.rawValue.uppercased())
                                        .font(.system(size: 8, weight: .semibold, design: .monospaced)).kerning(1)
                                        .foregroundStyle(color.opacity(0.8))
                                        .padding(.horizontal, 7).padding(.vertical, 3)
                                        .background(Capsule().fill(color.opacity(0.08)).overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 0.5)))
                                }
                                Text(isBlank ? "(empty line)" : lineText)
                                    .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                                    .foregroundStyle(isBlank ? .white.opacity(0.2) : .white)
                                    .italic(isBlank)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 15).padding(.vertical, 10).padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func globalWordIndex(lineIndex: Int, wordIndex: Int) -> Int {
        var count = 0
        for i in 0..<lineIndex { count += viewModel.wordsInLine(i).count }
        return count + wordIndex
    }
}

#Preview {
    ContentView(
        song: Song(title: "Untitled", lyrics: "Hello darkness, my old friend"),
        fragmentsVM: FragmentsViewModel(),
        settings: SettingsStore()
    )
}
