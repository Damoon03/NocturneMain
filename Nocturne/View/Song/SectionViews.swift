//
//  SectionViews.swift
//  Nocturne
//

import SwiftUI

struct SectionLabelView: View {
    let label: SectionLabel
    let onDelete: () -> Void

    var body: some View {
        let c = label.type.color
        let color = Color(red: c.r, green: c.g, blue: c.b)
        Text(label.type.rawValue.uppercased())
            .font(.system(size: 8, weight: .semibold, design: .monospaced)).kerning(1.5)
            .foregroundStyle(color.opacity(0.9))
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.08)).overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 0.5)))
            .contextMenu {
                Button(role: .destructive, action: onDelete) { Label("Remove label", systemImage: "trash") }
            }
    }
}

struct SectionTypeChooserSheet: View {
    let onSelect: (SectionType) -> Void
    let onAddNote: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.nocturneSheetBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Title area
                VStack(spacing: 8) {
                    Text("Add a Section")
                        .foregroundStyle(.white)
                        .font(.headline)
                        .kerning(1)

                    Text("Choose a label, then tap the line to attach it to.")
                        .foregroundStyle(.gray)
                        .font(.system(size: 13))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 28)
                .padding(.bottom, 20)

                // Section list
                VStack(spacing: 10) {
                    ForEach(SectionType.allCases, id: \.self) { type in
                        let c = type.color
                        let color = Color(red: c.r, green: c.g, blue: c.b)
                        Button(action: { onSelect(type) }) {
                            HStack {
                                Text(type.rawValue)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.85))
                                Spacer()
                                Text(type.shortName)
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .kerning(1)
                                    .foregroundStyle(color.opacity(0.9))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(color.opacity(0.08))
                                            .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 0.5))
                                    )
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                        }
                    }
                }

                // Add a Note button
                Button(action: onAddNote) {
                    HStack(spacing: 6) {
                        Image(systemName: "note.text")
                            .font(.system(size: 14))
                        Text("Add a Note")
                            .font(.system(size: 15, weight: .regular))
                    }
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                Spacer(minLength: 12)

                // Cancel
                Button("Cancel", action: onCancel)
                    .foregroundStyle(.gray)
                    .font(.system(size: 13))
                    .padding(.bottom, 20)
            }
        }
        .presentationDetents([.height(520), .large])   // fixed height works much better on iPad
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.nocturneSheetBackground)
    }
}
