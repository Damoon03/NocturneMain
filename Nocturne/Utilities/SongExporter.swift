//
//  SongExporter.swift
//  Nocturne
//
//  Created by Damoon saber on 3/31/1405 AP.
//
//

import Foundation
import UIKit

struct SongExporter {

    // MARK: - Plain text export

    static func plainText(for song: Song) -> String {
        var output = ""
        if !song.title.trimmingCharacters(in: .whitespaces).isEmpty {
            output += song.title + "\n"
            output += String(repeating: "-", count: song.title.count) + "\n\n"
        }

        let lines = song.lyrics.components(separatedBy: "\n")

        for (lineIndex, lyric) in lines.enumerated() {
            if let label = song.sectionLabels.first(where: { $0.lineIndex == lineIndex }) {
                output += "[\(label.type.rawValue)]\n"
            }

            let lineChords = song.chords
                .filter { $0.lineIndex == lineIndex }
                .sorted { $0.wordIndex < $1.wordIndex }

            if !lineChords.isEmpty {
                output += chordLineText(for: lyric, chords: lineChords) + "\n"
            }

            output += lyric + "\n"
        }

        return output
    }

    private static func chordLineText(for lyric: String, chords: [Chord]) -> String {
        let words = lyric.components(separatedBy: " ").filter { !$0.isEmpty }

        var wordStartColumns: [Int] = []
        var col = 0
        for word in words {
            wordStartColumns.append(col)
            col += word.count + 1
        }

        var line = ""
        for chord in chords {
            guard chord.wordIndex >= 0 && chord.wordIndex < wordStartColumns.count else { continue }
            let targetColumn = wordStartColumns[chord.wordIndex]
            while line.count < targetColumn {
                line += " "
            }
            line += chord.displayText
        }
        return line
    }

    // MARK: - PDF export

    static func pdf(for song: Song) -> Data {
        let pageWidth: CGFloat = 612   // US Letter, 72pt/inch
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2

        let titleFont = UIFont.systemFont(ofSize: 22, weight: .semibold)
        let lyricFont = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        let chordFont = UIFont.monospacedSystemFont(ofSize: 11, weight: .medium)
        let sectionFont = UIFont.systemFont(ofSize: 10, weight: .bold)

        let lineHeight: CGFloat = 20
        let chordRowHeight: CGFloat = 16
        let sectionRowHeight: CGFloat = 22

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let lines = song.lyrics.components(separatedBy: "\n")

        let data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = margin

            if !song.title.trimmingCharacters(in: .whitespaces).isEmpty {
                let titleAttrs: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.black]
                (song.title as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
                y += 34
            }

            for (lineIndex, lyric) in lines.enumerated() {
                // New page if we're about to run off the bottom
                if y > pageHeight - margin - 40 {
                    context.beginPage()
                    y = margin
                }

                if let label = song.sectionLabels.first(where: { $0.lineIndex == lineIndex }) {
                    let text = label.type.rawValue.uppercased()
                    let attrs: [NSAttributedString.Key: Any] = [.font: sectionFont, .foregroundColor: UIColor.darkGray]
                    (text as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: attrs)
                    y += sectionRowHeight
                }

                let lineChords = song.chords
                    .filter { $0.lineIndex == lineIndex }
                    .sorted { $0.wordIndex < $1.wordIndex }

                if !lineChords.isEmpty {
                    drawChordRow(lineChords, lyric: lyric, font: lyricFont, chordFont: chordFont,
                                 origin: CGPoint(x: margin, y: y))
                    y += chordRowHeight
                }

                let lyricAttrs: [NSAttributedString.Key: Any] = [.font: lyricFont, .foregroundColor: UIColor.black]
                let lyricString = lyric.isEmpty ? " " : lyric
                let textRect = CGRect(x: margin, y: y, width: contentWidth, height: lineHeight * 2)
                (lyricString as NSString).draw(in: textRect, withAttributes: lyricAttrs)

                // Account for wrapped lines
                let measuredHeight = (lyricString as NSString).boundingRect(
                    with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin,
                    attributes: lyricAttrs,
                    context: nil
                ).height

                y += max(lineHeight, measuredHeight + 4)
            }
        }

        return data
    }

    // MARK: - Filename helper

    /// Sanitizes a song title into a safe filename component (no path
    /// separators or other characters the filesystem disallows).
    static func sanitizedFileName(for title: String) -> String {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = t.isEmpty ? "Untitled" : t
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return name.components(separatedBy: invalid).joined(separator: "-")
    }

    private static func drawChordRow(_ chords: [Chord], lyric: String, font: UIFont, chordFont: UIFont, origin: CGPoint) {
        let words = lyric.components(separatedBy: " ").filter { !$0.isEmpty }
        let spaceWidth = (" " as NSString).size(withAttributes: [.font: font]).width

        var wordStartX: [Int: CGFloat] = [:]
        var x: CGFloat = origin.x
        for (index, word) in words.enumerated() {
            wordStartX[index] = x
            let wordWidth = (word as NSString).size(withAttributes: [.font: font]).width
            x += wordWidth + spaceWidth
        }

        for chord in chords {
            guard let startX = wordStartX[chord.wordIndex] else { continue }
            let text = chord.displayText
            let attrs: [NSAttributedString.Key: Any] = [.font: chordFont, .foregroundColor: UIColor.black]
            let size = (text as NSString).size(withAttributes: attrs)

            let padding: CGFloat = 4
            let capsuleRect = CGRect(
                x: startX - padding,
                y: origin.y,
                width: size.width + padding * 2,
                height: size.height + 4
            )
            let path = UIBezierPath(roundedRect: capsuleRect, cornerRadius: capsuleRect.height / 2)
            UIColor.black.withAlphaComponent(0.5).setStroke()
            path.lineWidth = 0.75
            path.stroke()

            (text as NSString).draw(at: CGPoint(x: startX, y: origin.y + 2), withAttributes: attrs)
        }
    }
}
