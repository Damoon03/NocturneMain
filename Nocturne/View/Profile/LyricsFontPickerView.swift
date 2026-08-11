//
//  LyricsFontPickerView.swift
//  Nocturne
//
//  Horizontally-scrollable font picker for Profile. Each card renders the
//  same lyric sample text live in its own font, so the difference between
//  options is immediately visible — no static preview images.
//

import SwiftUI

struct LyricsFontPickerView: View {
    @Binding var selection: LyricsFontOption

    static let sampleLyric = "Yesterday, all my troubles seemed so far away,\nNow it looks as though they're here to stay,\nOh, I believe in yesterday"

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(LyricsFontOption.displayOrder) { option in
                    LyricsFontCard(
                        option: option,
                        isSelected: selection == option
                    )
                    .onTapGesture {
                        selection = option
                        HapticManager.impact(.medium)
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
    }
}

private struct LyricsFontCard: View {
    let option: LyricsFontOption
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LyricsFontPickerView.sampleLyric)
                .font(option.font(size: 12))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(3)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                .frame(height: 84, alignment: .top)

            HStack(spacing: 6) {
                Text(option.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(isSelected ? 0.85 : 0.4))
                    .lineLimit(1)

                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.9) : Color.clear)
                        .overlay(
                            Circle().stroke(Color.white.opacity(isSelected ? 0 : 0.2), lineWidth: 1)
                        )
                        .frame(width: 16, height: 16)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.black)
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 168, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isSelected ? 0.07 : 0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(isSelected ? 0.5 : 0.08), lineWidth: isSelected ? 1.5 : 0.5)
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}
