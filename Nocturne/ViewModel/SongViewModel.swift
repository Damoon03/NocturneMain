//
//  SongViewModel.swift
//  Nocturne
//
//  Created by Damoon saber on 3/28/1405 AP.
//
//  CHORDS ARE STRUCTURED DATA, not inline string markers. song.chords is an
//  array of Chord (lineIndex, wordIndex, names), the same pattern already
//  used for song.sectionLabels. This replaces an earlier approach that
//  embedded ⌜chord⌝ markers directly in the lyrics string, which caused
//  three separate alignment bugs all traceable to fragile character-
//  counting assumptions through those Unicode marker symbols. With
//  structured data there is no string math at all: a chord just says
//  "I'm on word 2 of line 5," and the rendering layer looks up that word's
//  real on-screen position directly.
//


import Foundation
import Combine

@MainActor
class SongViewModel: ObservableObject {
    @Published var song: Song
    @Published var isAnnotating = false
    @Published var annotationText = ""
    @Published var pendingAnnotation = ""
    @Published var isPickingWord = false
    @Published var saveState: SaveState = .saved
    @Published var transposeSteps: Int = 0
    @Published var isAddingNote = false         // feature 4
    @Published var pendingNoteLineIndex: Int? = nil

    // MARK: - Rhyme flow
    @Published var isRhymePicking = false
    @Published var isRhymeSheetPresented = false
    @Published var rhymeSourceWord: String = ""
    private var rhymeTargetLineIndex: Int? = nil
    private var rhymeTargetWordIndex: Int? = nil

    enum SaveState { case saved, saving, unsaved }

    var onUpdate: ((Song) async -> Bool)?
    private var cancellables = Set<AnyCancellable>()
    private var undoStack: [String] = []
    private var redoStack: [String] = []
    private let maxUndoSteps = 50
    private var isUndoingOrRedoing = false
    private var cachedLyrics = ""
    private var cachedLines: [String] = []

    init(song: Song, onUpdate: ((Song) async -> Bool)? = nil) {
        self.song = song
        self.onUpdate = onUpdate
        undoStack.append(song.lyrics)

        $song
            .map { $0.lyrics }
            .removeDuplicates()
            .sink { [weak self] newLyrics in
                guard let self, !self.isUndoingOrRedoing else { return }
                self.redoStack.removeAll()
                self.undoStack.append(newLyrics)
                if self.undoStack.count > self.maxUndoSteps { self.undoStack.removeFirst() }
                self.saveState = .unsaved
            }
            .store(in: &cancellables)

        $song
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] updatedSong in
                guard let self else { return }
                Task { @MainActor in
                    self.saveState = .saving
                    let ok = await self.onUpdate?(updatedSong) ?? true
                    self.saveState = ok ? .saved : .unsaved
                }
            }
            .store(in: &cancellables)
    }

    var lyricsLines: [String] {
        if song.lyrics != cachedLyrics {
            cachedLyrics = song.lyrics
            cachedLines = song.lyrics.components(separatedBy: "\n")
        }
        return cachedLines
    }

    var lyricLineItems: [LyricLineItem] {
        lyricsLines.enumerated().map { index, line in
            LyricLineItem(id: "\(index)-\(line.hashValue)", index: index)
        }
    }

    func wordItems(inLine lineIndex: Int) -> [LyricWordItem] {
        wordsInLine(lineIndex).enumerated().map { wordIndex, word in
            LyricWordItem(id: "\(lineIndex)-\(wordIndex)-\(word)", index: wordIndex, word: word)
        }
    }

    func chordWordIndices(forLine lineIndex: Int) -> Set<Int> {
        Set(chords(forLineIndex: lineIndex).map(\.wordIndex))
    }

    var words: [String] {
        song.lyrics.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    }

    func wordsInLine(_ lineIndex: Int) -> [String] {
        guard lineIndex >= 0 && lineIndex < lyricsLines.count else { return [] }
        return lyricsLines[lineIndex].components(separatedBy: " ").filter { !$0.isEmpty }
    }

    // MARK: - Undo / Redo
    var canUndo: Bool { undoStack.count > 1 }
    var canRedo: Bool { !redoStack.isEmpty }

    func undo() {
        guard undoStack.count > 1 else { return }
        isUndoingOrRedoing = true
        redoStack.append(undoStack.removeLast())
        song.lyrics = undoStack.last ?? song.lyrics
        isUndoingOrRedoing = false
    }

    func redo() {
        guard !redoStack.isEmpty else { return }
        isUndoingOrRedoing = true
        let next = redoStack.removeLast()
        undoStack.append(next)
        song.lyrics = next
        isUndoingOrRedoing = false
    }

    // MARK: - Chord annotation flow
    func startAnnotating() {
        if isRhymePicking { cancelRhymePicking() }
        if isPickingLineForSection { cancelPickingLineForSection() }
        if isPickingLineForNote { cancelPickingLineForNote() }
        isAnnotating = true
    }
    func cancelAnnotating() { annotationText = ""; isAnnotating = false }

    /// Skips typing entirely — used by the "recent chords" quick-pick strip
    /// in ChordSheetView to go straight into word-picking mode.
    func quickPlaceChord(_ name: String) {
        let trimmed = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(10))
        guard !trimmed.isEmpty else { return }
        if isRhymePicking { cancelRhymePicking() }
        if isPickingLineForSection { cancelPickingLineForSection() }
        if isPickingLineForNote { cancelPickingLineForNote() }
        pendingAnnotation = trimmed
        annotationText = ""
        isAnnotating = false
        isPickingWord = true
    }

    func confirmAnnotation() {
        let trimmed = annotationText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        pendingAnnotation = String(trimmed.prefix(10))
        annotationText = ""
        isAnnotating = false
        isPickingWord = true
    }

    func cancelPickingWord() { pendingAnnotation = ""; isPickingWord = false }

    func insertAnnotation(beforeWordAtIndex globalIndex: Int) {
        var count = 0
        for (lineIndex, line) in lyricsLines.enumerated() {
            let words = line.components(separatedBy: " ").filter { !$0.isEmpty }
            if globalIndex >= count && globalIndex < count + words.count {
                addChord(pendingAnnotation, atLineIndex: lineIndex, wordIndex: globalIndex - count)
                break
            }
            count += words.count
        }
        pendingAnnotation = ""
        isPickingWord = false
    }

    func addChord(_ name: String, atLineIndex lineIndex: Int, wordIndex: Int) {
        if let existingIndex = song.chords.firstIndex(where: {
            $0.lineIndex == lineIndex && $0.wordIndex == wordIndex
        }) {
            if !song.chords[existingIndex].names.contains(name) {
                song.chords[existingIndex].names.append(name)
            }
        } else {
            song.chords.append(Chord(lineIndex: lineIndex, wordIndex: wordIndex, names: [name]))
        }
    }

    func deleteChord(_ name: String, atLineIndex lineIndex: Int, wordIndex: Int) {
        guard let index = song.chords.firstIndex(where: {
            $0.lineIndex == lineIndex && $0.wordIndex == wordIndex
        }) else { return }
        song.chords[index].names.removeAll { $0 == name }
        if song.chords[index].names.isEmpty { song.chords.remove(at: index) }
    }

    func chord(atLineIndex lineIndex: Int, wordIndex: Int) -> Chord? {
        song.chords.first { $0.lineIndex == lineIndex && $0.wordIndex == wordIndex }
    }

    func chords(forLineIndex lineIndex: Int) -> [Chord] {
        song.chords.filter { $0.lineIndex == lineIndex }
    }

    var hasChords: Bool { !song.chords.isEmpty }

    /// Distinct chord names already used in THIS song, most recently placed
    /// first (scanning song.chords back-to-front, and each chord's merged
    /// names back-to-front). Scoped per-song rather than a global MRU list,
    /// since the chords relevant to what you're playing right now are the
    /// ones already in this song.
    var recentChordsInSong: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for chord in song.chords.reversed() {
            for name in chord.names.reversed() {
                let key = name.lowercased()
                if seen.contains(key) { continue }
                seen.insert(key)
                result.append(name)
                if result.count >= 8 { return result }
            }
        }
        return result
    }

    // MARK: - Rhyme flow

    /// Enters rhyme word-picking mode (tap a lyric word to look up rhymes for it).
    func startRhymePicking() {
        if isPickingWord { cancelPickingWord() }
        if isAnnotating { cancelAnnotating() }
        if isPickingLineForSection { cancelPickingLineForSection() }
        if isPickingLineForNote { cancelPickingLineForNote() }
        isRhymePicking = true
    }

    func cancelRhymePicking() { isRhymePicking = false }

    /// Called when a word is tapped in rhyme-picking mode. Cleans the word,
    /// stores the target position, and opens the rhyme sheet.
    func selectRhymeTarget(lineIndex: Int, wordIndex: Int) {
        let words = wordsInLine(lineIndex)
        guard wordIndex >= 0 && wordIndex < words.count else { return }
        let word = RhymeService.cleanWord(words[wordIndex])
        guard !word.isEmpty else { return }

        rhymeTargetLineIndex = lineIndex
        rhymeTargetWordIndex = wordIndex
        rhymeSourceWord = word
        isRhymePicking = false
        isRhymeSheetPresented = true
    }

    /// Replaces the target word in place, preserving surrounding punctuation
    /// and capitalization (e.g. "Night," -> "Light,").
    func replaceRhymeTarget(with newWord: String) {
        guard let lineIndex = rhymeTargetLineIndex, let wordIndex = rhymeTargetWordIndex,
              lineIndex >= 0 && lineIndex < lyricsLines.count else { return }

        var lines = lyricsLines
        let rawTokens = lines[lineIndex].components(separatedBy: " ")
        var nonEmptyPositions: [Int] = []
        for (i, token) in rawTokens.enumerated() where !token.isEmpty {
            nonEmptyPositions.append(i)
        }
        guard wordIndex < nonEmptyPositions.count else { return }

        let targetPosition = nonEmptyPositions[wordIndex]
        var tokens = rawTokens
        tokens[targetPosition] = preservingPunctuation(original: tokens[targetPosition], replacement: newWord)
        lines[lineIndex] = tokens.joined(separator: " ")

        song.lyrics = lines.joined(separator: "\n")
        closeRhymeFlow()
    }

    /// Inserts `newWord` as a brand-new line right after the target line —
    /// shifting any section labels / chords / notes on later lines down by
    /// one, the same bookkeeping used by auto section detection.
    func insertRhymeAsNewLine(_ newWord: String) {
        guard let lineIndex = rhymeTargetLineIndex else { return }

        var lines = lyricsLines
        let insertAt = max(0, min(lineIndex + 1, lines.count))
        lines.insert(newWord, at: insertAt)

        shiftSectionLabels(fromIndex: insertAt, by: 1)
        shiftChords(fromIndex: insertAt, by: 1)
        shiftNotes(fromIndex: insertAt, by: 1)

        song.lyrics = lines.joined(separator: "\n")
        closeRhymeFlow()
    }

    func cancelRhymeSheet() { closeRhymeFlow() }

    private func closeRhymeFlow() {
        isRhymeSheetPresented = false
        rhymeTargetLineIndex = nil
        rhymeTargetWordIndex = nil
        rhymeSourceWord = ""
    }

    /// Keeps the replacement's prefix/suffix punctuation and leading
    /// capitalization from the original token, e.g. "(Night)" -> "(Light)".
    private func preservingPunctuation(original: String, replacement: String) -> String {
        let core = RhymeService.cleanWord(original)
        guard !core.isEmpty, let range = original.range(of: core, options: .caseInsensitive) else {
            return replacement
        }
        let prefix = String(original[original.startIndex..<range.lowerBound])
        let suffix = String(original[range.upperBound...])
        var body = replacement
        if let firstChar = core.first, firstChar.isUppercase {
            body = body.prefix(1).uppercased() + body.dropFirst()
        }
        return prefix + body + suffix
    }

    // MARK: - Feature 4: Notes
    func note(forLineIndex lineIndex: Int) -> SongNote? {
        song.notes.first { $0.lineIndex == lineIndex }
    }

    func addNote(_ text: String, atLineIndex lineIndex: Int) {
        song.notes.removeAll { $0.lineIndex == lineIndex }
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            song.notes.append(SongNote(lineIndex: lineIndex, text: text))
        }
    }

    func removeNote(atLineIndex lineIndex: Int) {
        song.notes.removeAll { $0.lineIndex == lineIndex }
    }

    // MARK: - Feature 6: Main recordings
    func isMainRecording(_ recording: Recording) -> Bool {
        song.mainRecordingIDs.contains(recording.id)
    }

    func toggleMainRecording(_ recording: Recording) {
        if song.mainRecordingIDs.contains(recording.id) {
            song.mainRecordingIDs.removeAll { $0 == recording.id }
        } else {
            song.mainRecordingIDs.append(recording.id)
        }
    }

    // MARK: - Line index shifting
    private func shiftSectionLabels(fromIndex index: Int, by delta: Int) {
        for i in 0..<song.sectionLabels.count {
            if song.sectionLabels[i].lineIndex >= index { song.sectionLabels[i].lineIndex += delta }
        }
    }

    private func shiftChords(fromIndex index: Int, by delta: Int) {
        for i in 0..<song.chords.count {
            if song.chords[i].lineIndex >= index { song.chords[i].lineIndex += delta }
        }
    }

    private func shiftNotes(fromIndex index: Int, by delta: Int) {
        for i in 0..<song.notes.count {
            if song.notes[i].lineIndex >= index { song.notes[i].lineIndex += delta }
        }
    }

    // MARK: - Transpose
    func transpose(by delta: Int) {
        for i in 0..<song.chords.count {
            song.chords[i].names = song.chords[i].names.map { ChordTransposer.transpose($0, by: delta) }
        }
        transposeSteps += delta
    }

    func resetTranspose() {
        guard transposeSteps != 0 else { return }
        transpose(by: -transposeSteps)
        transposeSteps = 0
    }

    // MARK: - Section labels
    func addSection(_ type: SectionType, atLineIndex lineIndex: Int) {
        song.sectionLabels.removeAll { $0.lineIndex == lineIndex }
        song.sectionLabels.append(SectionLabel(lineIndex: lineIndex, type: type))
        song.sectionLabels.sort { $0.lineIndex < $1.lineIndex }
    }

    func removeSection(atLineIndex lineIndex: Int) {
        song.sectionLabels.removeAll { $0.lineIndex == lineIndex }
    }

    func sectionLabel(forLineIndex lineIndex: Int) -> SectionLabel? {
        song.sectionLabels.first { $0.lineIndex == lineIndex }
    }

    // MARK: - Section / note picking flow (top-strip "+Section" button)
    @Published var isPickingLineForSection = false
    @Published var pendingSectionType: SectionType? = nil
    @Published var isPickingLineForNote = false

    /// Called once a section type is chosen from the sheet — enters
    /// line-picking mode (tap any line to attach the label there).
    func startPickingLineForSection(_ type: SectionType) {
        if isPickingWord { cancelPickingWord() }
        if isRhymePicking { cancelRhymePicking() }
        if isAnnotating { cancelAnnotating() }
        if isPickingLineForNote { cancelPickingLineForNote() }
        pendingSectionType = type
        isPickingLineForSection = true
    }

    func cancelPickingLineForSection() {
        pendingSectionType = nil
        isPickingLineForSection = false
    }

    /// Called when "Add a Note" is chosen from the section sheet — enters
    /// line-picking mode (tap any line to attach a note to it).
    func startPickingNote() {
        if isPickingWord { cancelPickingWord() }
        if isRhymePicking { cancelRhymePicking() }
        if isAnnotating { cancelAnnotating() }
        if isPickingLineForSection { cancelPickingLineForSection() }
        isPickingLineForNote = true
    }

    func cancelPickingLineForNote() {
        isPickingLineForNote = false
    }

    /// Called when a line is tapped in line-picking mode.
    func placePendingSection(atLineIndex lineIndex: Int) {
        guard let type = pendingSectionType else { return }
        addSection(type, atLineIndex: lineIndex)
        pendingSectionType = nil
        isPickingLineForSection = false
    }

    // MARK: - Auto section detection
    private static let sectionKeywordMap: [String: SectionType] = [
        "verse": .verse, "chorus": .chorus, "bridge": .bridge,
        "intro": .intro, "outro": .outro, "hook": .hook,
        "pre-chorus": .chorus, "prechorus": .chorus
    ]

    private func matchedSectionType(for line: String) -> SectionType? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        var candidate = trimmed.lowercased()
        if candidate.hasSuffix(":") { candidate = String(candidate.dropLast()) }
        let parts = candidate.split(separator: " ")
        let base = parts.first.map(String.init) ?? candidate
        let baseJoined = parts.count > 1 ? parts.dropLast().joined(separator: " ") : candidate
        return Self.sectionKeywordMap[candidate]
            ?? Self.sectionKeywordMap[base]
            ?? Self.sectionKeywordMap[baseJoined]
    }

    func runAutoSectionDetection() {
        let lines = lyricsLines
        var result: [String] = []
        var removedCountSoFar = 0
        var pendingSectionType: SectionType? = nil

        for (originalIndex, line) in lines.enumerated() {
            if let type = matchedSectionType(for: line) {
                pendingSectionType = type
                removedCountSoFar += 1
                let shiftPoint = originalIndex - removedCountSoFar + 1
                shiftSectionLabels(fromIndex: shiftPoint, by: -1)
                shiftChords(fromIndex: shiftPoint, by: -1)
                shiftNotes(fromIndex: shiftPoint, by: -1)
                continue
            }
            result.append(line)
            if let type = pendingSectionType {
                addSection(type, atLineIndex: result.count - 1)
                pendingSectionType = nil
            }
        }
        song.lyrics = result.joined(separator: "\n")
    }
}
