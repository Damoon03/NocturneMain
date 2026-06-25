//
//  SongExporter.swift
//  Nocturne
//
//  Created by Damoon saber on 3/31/1405 AP.
//
//  Builds a chord chart (lyrics with chords positioned above their words)
//  from a Song's STRUCTURED data — song.chords (lineIndex, wordIndex,
//  names) and song.sectionLabels — for both plain-text and PDF export.
//
//  This is a fresh, independent implementation, NOT a revival of the old
//  ⌜chord⌝ string-marker system. It only reads structured data and
//  produces an output string/PDF; it never writes back into Song, so it
//  carries none of the risk that caused the earlier alignment bugs.
//

import Foundation
import UIKit

struct SongExporter {

    // MARK: - Plain text export

    /// Builds a classic chord-chart text layout: a chord line (chords
    /// positioned above their word using space-padding, computed fresh
    /// from word character offsets) immediately followed by its lyric
    /// line. Section labels render as bracketed headers, e.g. [Chorus].
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

    /// Builds a single chord line as plain text, with each chord's name
    /// padded to start at the character column where its target word
    /// begins. Computed fresh from the lyric string each time — this
    /// string is never stored or re-parsed, it only exists for the
    /// duration of building export output.
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

    /// Renders the same chord chart as a single- or multi-page PDF, using
    /// UIGraphicsPDFRenderer. Chords render as small bordered capsules
    /// (matching the in-app visual style) positioned above their word
    /// using Core Text-measured string widths — not assumed character
    /// widths — so the PDF's alignment doesn't inherit any of the
    /// measurement fragility that affected on-screen rendering earlier.
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

    /// Draws one chord row above a lyric line, positioning each chord
    /// capsule using REAL measured string widths (NSString sizing) for
    /// every word up to the target — not character counts — so PDF
    /// alignment is accurate regardless of font metrics.
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
