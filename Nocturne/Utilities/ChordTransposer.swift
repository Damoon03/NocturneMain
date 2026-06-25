//
//  ChordTransposer.swift
//  Nocturne
//
//  Created by Damoon saber on 3/28/1405 AP.
//

import Foundation

struct ChordTransposer {

    private static let sharpNotes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    private static let flatNotes  = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]

    // Prefer flats for these root notes
    private static let preferFlats: Set<String> = ["F", "Bb", "Eb", "Ab", "Db", "Gb"]

    static func transpose(_ chord: String, by semitones: Int) -> String {
        guard semitones != 0 else { return chord }

        let (root, suffix, bass) = parseChord(chord)
        guard !root.isEmpty else { return chord }

        let transposedRoot = transposeNote(root, by: semitones)
        let transposedBass = bass.map { transposeNote($0, by: semitones) }

        var result = transposedRoot + suffix
        if let b = transposedBass {
            result += "/" + b
        }
        return result
    }

    private static func transposeNote(_ note: String, by semitones: Int) -> String {
        if let index = sharpNotes.firstIndex(of: note) {
            let newIndex = ((index + semitones) % 12 + 12) % 12
            let newNote = sharpNotes[newIndex]
            if newNote.contains("#"), let flatIndex = sharpNotes.firstIndex(of: newNote) {
                let flatNote = flatNotes[flatIndex]
                return preferFlats.contains(flatNote) ? flatNote : newNote
            }
            return newNote
        }
        if let index = flatNotes.firstIndex(of: note) {
            let newIndex = ((index + semitones) % 12 + 12) % 12
            return flatNotes[newIndex]
        }
        return note
    }

    private static func parseChord(_ chord: String) -> (root: String, suffix: String, bass: String?) {
        var s = chord

        var bass: String? = nil
        if let slashIndex = s.lastIndex(of: "/") {
            let bassNote = String(s[s.index(after: slashIndex)...])
            if isValidNote(bassNote) {
                bass = bassNote
                s = String(s[..<slashIndex])
            }
        }

        guard !s.isEmpty else { return ("", "", nil) }

        var root = ""
        var suffix = ""

        if s.count >= 2 {
            let twoChar = String(s.prefix(2))
            if sharpNotes.contains(twoChar) || flatNotes.contains(twoChar) {
                root = twoChar
                suffix = String(s.dropFirst(2))
            } else {
                let oneChar = String(s.prefix(1))
                if sharpNotes.contains(oneChar) {
                    root = oneChar
                    suffix = String(s.dropFirst(1))
                }
            }
        } else {
            let oneChar = String(s.prefix(1))
            if sharpNotes.contains(oneChar) {
                root = oneChar
            }
        }

        return (root, suffix, bass)
    }

    private static func isValidNote(_ s: String) -> Bool {
        sharpNotes.contains(s) || flatNotes.contains(s)
    }
}
