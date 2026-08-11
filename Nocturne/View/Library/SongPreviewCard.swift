//
//  SongPreviewCard.swift
//  Nocturne
//
//  Created by Damoon saber on 4/1/1405 AP.
//

import SwiftUI

struct SongPreviewCard: View {
    let song: Song
    var lyricsFont: LyricsFontOption = .monospaced

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text(song.title)
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(.white)

            Text(previewLyrics)
                .font(lyricsFont.font(size: 13))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(5)

            Divider()
                .overlay(.white.opacity(0.08))

            HStack(spacing: 14) {

                Label("\(song.chords.count)", systemImage: "music.note")
                Label("\(song.recordings.count)", systemImage: "waveform")

                Spacer()
            }
            .font(.system(size: 11))
            .foregroundStyle(.white.opacity(0.4))
        }
        .padding(22)
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.black.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var previewLyrics: String {
        song.lyrics
            .components(separatedBy: "\n")
            .prefix(4)
            .joined(separator: "\n")
    }
}
