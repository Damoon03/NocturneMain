//
//  FABMenuSheet.swift
//  Nocturne
//

import SwiftUI

struct FABMenuSheet: View {
    let onNewSong: () -> Void
    let onNewFolder: () -> Void
    let onCaptureFragment: () -> Void
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.nocturneSheetBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 36, height: 3)
                    .padding(.top, 12)
                    .padding(.bottom, 28)

                VStack(spacing: 0) {
                    fabOption(icon: "music.note", title: "New Song", subtitle: "Start writing a new song") {
                        isPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onNewSong() }
                    }
                    Rectangle().fill(Color.white.opacity(0.05)).frame(height: 0.5).padding(.horizontal, 20)
                    fabOption(icon: "folder", title: "New Folder", subtitle: "Organise songs into a folder") {
                        isPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onNewFolder() }
                    }
                    Rectangle().fill(Color.white.opacity(0.05)).frame(height: 0.5).padding(.horizontal, 20)
                    fabOption(icon: "lightbulb", title: "Capture Fragment", subtitle: "Save a lyric, riff, or idea") {
                        isPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onCaptureFragment() }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
                )
                .padding(.horizontal, 20)

                Button(action: { isPresented = false }) {
                    Text("Cancel").font(.system(size: 15, weight: .regular)).foregroundStyle(.white.opacity(0.3))
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                }
                .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 8)
            }
        }
        .presentationDetents([.height(290)])
        .presentationBackground(Color.nocturneSheetBackground)
        .presentationDragIndicator(.hidden)
    }

    private func fabOption(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.07)).frame(width: 40, height: 40)
                    Image(systemName: icon).font(.system(size: 15, weight: .light)).foregroundStyle(.white.opacity(0.75))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 14, weight: .medium)).foregroundStyle(.white.opacity(0.9))
                    Text(subtitle).font(.system(size: 11, weight: .light)).foregroundStyle(.white.opacity(0.3))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 11, weight: .light)).foregroundStyle(.white.opacity(0.15))
            }
            .padding(.horizontal, 20).padding(.vertical, 14).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
