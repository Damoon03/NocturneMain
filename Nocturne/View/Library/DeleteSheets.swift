//
//  DeleteSheets.swift
//  Nocturne
//

import SwiftUI

struct DeleteConfirmSheet: View {
    let title: String
    var heading: String = "Move to Trash"
    var subtitle: String? = nil
    let onDelete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.nocturneSheetBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    Circle().fill(Color.red.opacity(0.1)).frame(width: 56, height: 56)
                    Image(systemName: "trash").font(.system(size: 22, weight: .light)).foregroundStyle(.red.opacity(0.8))
                }
                .padding(.bottom, 18)
                Text(heading)
                    .font(.system(size: 17, weight: .medium)).foregroundStyle(.white.opacity(0.9)).padding(.bottom, 8)
                Text(subtitle ?? "\"\(title)\" will be moved to Recently Deleted.")
                    .font(.system(size: 13, weight: .light)).foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center).padding(.horizontal, 40)
                Spacer()
                VStack(spacing: 10) {
                    Button(action: onDelete) {
                        Text("Delete")
                            .font(.system(size: 15, weight: .medium)).foregroundStyle(.red.opacity(0.9))
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.red.opacity(0.1))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.25), lineWidth: 0.5)))
                    }
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .regular)).foregroundStyle(.white.opacity(0.5))
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 0.5)))
                    }
                }
                .padding(.horizontal, 24).padding(.bottom, 36)
            }
        }
        .presentationDetents([.fraction(0.38)])
        .presentationBackground(Color.nocturneSheetBackground)
        .presentationDragIndicator(.hidden)
    }
}

struct PermanentDeleteSheet: View {
    let title: String
    let subtitle: String
    let confirmLabel: String
    let onDelete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.nocturneSheetBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    Circle().fill(Color.red.opacity(0.1)).frame(width: 56, height: 56)
                    Image(systemName: "trash.fill").font(.system(size: 20, weight: .light)).foregroundStyle(.red.opacity(0.8))
                }
                .padding(.bottom, 18)
                Text(title)
                    .font(.system(size: 17, weight: .medium)).foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center).padding(.horizontal, 32).padding(.bottom, 8)
                Text(subtitle)
                    .font(.system(size: 13, weight: .light)).foregroundStyle(.white.opacity(0.35))
                    .multilineTextAlignment(.center).padding(.horizontal, 40)
                Spacer()
                VStack(spacing: 10) {
                    Button(action: onDelete) {
                        Text(confirmLabel)
                            .font(.system(size: 15, weight: .medium)).foregroundStyle(.red.opacity(0.9))
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.red.opacity(0.1))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.25), lineWidth: 0.5)))
                    }
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .regular)).foregroundStyle(.white.opacity(0.5))
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 0.5)))
                    }
                }
                .padding(.horizontal, 24).padding(.bottom, 36)
            }
        }
        .presentationDetents([.fraction(0.38)])
        .presentationBackground(Color.nocturneSheetBackground)
        .presentationDragIndicator(.hidden)
    }
}
