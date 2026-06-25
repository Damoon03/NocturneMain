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

struct SectionPickerView: View {
    let onSelect: (SectionType) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Add Section Label").foregroundStyle(.white).font(.headline).kerning(1).padding(.top, 32)
                VStack(spacing: 10) {
                    ForEach(SectionType.allCases, id: \.self) { type in
                        let c = type.color
                        let color = Color(red: c.r, green: c.g, blue: c.b)
                        Button(action: { onSelect(type) }) {
                            HStack {
                                Text(type.rawValue).font(.system(size: 15, weight: .regular)).foregroundStyle(.white.opacity(0.85))
                                Spacer()
                                Text(type.shortName)
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced)).kerning(1)
                                    .foregroundStyle(color.opacity(0.9))
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Capsule().fill(color.opacity(0.08)).overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 0.5)))
                            }
                            .padding(.horizontal, 24).padding(.vertical, 12)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                        }
                    }
                }
                Button("Cancel", action: onDismiss).foregroundStyle(.gray).font(.system(size: 13)).padding(.bottom)
                Spacer()
            }
        }
        .presentationDetents([.fraction(0.6)])
        .presentationBackground(Color.black)
    }
}
