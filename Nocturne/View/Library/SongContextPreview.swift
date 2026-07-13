//
//  SongContextPreview.swift
//  Nocturne
//

import SwiftUI

struct SongContextPreview: View {
    let song: Song

    private var previewLines: [String] {
        song.lyrics.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .prefix(8)
            .map { $0 }
    }

    var body: some View {
        ZStack {
            Color.black
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.07)).frame(width: 32, height: 32)
                        Image(systemName: "music.note").font(.system(size: 12, weight: .light)).foregroundStyle(.white.opacity(0.4))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.title.isEmpty ? "Untitled" : song.title)
                            .font(.system(size: 14, weight: .medium)).foregroundStyle(.white.opacity(0.9))
                        Text("\(song.lyrics.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count) words")
                            .font(.system(size: 10, weight: .regular, design: .monospaced)).foregroundStyle(.white.opacity(0.25))
                    }
                    Spacer()
                }
                .padding(.horizontal, 18).padding(.top, 18).padding(.bottom, 14)
                Divider().background(Color.white.opacity(0.07))
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(previewLines.enumerated()), id: \.element) { idx, line in
                        Text(line)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .foregroundStyle(.white.opacity(idx == 0 ? 0.75 : max(0.1, 0.35 - Double(idx) * 0.03)))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 18).padding(.vertical, 14)
            }
        }
        .frame(width: 300)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
    }
}
