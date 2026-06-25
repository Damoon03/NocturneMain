//
//  ChordSheetView.swift
//  Nocturne
//

import SwiftUI

struct TransposeView: View {
    @ObservedObject var viewModel: SongViewModel

    var body: some View {
        HStack(spacing: 0) {
            Button(action: { viewModel.transpose(by: -1) }) {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.7))
                    .frame(width: 32, height: 28)
            }
            Divider().frame(height: 14).background(Color.white.opacity(0.1))
            Button(action: viewModel.resetTranspose) {
                HStack(spacing: 3) {
                    Image(systemName: "music.note").font(.system(size: 9, weight: .medium)).foregroundStyle(.white.opacity(0.4))
                    Text(stepLabel)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(viewModel.transposeSteps == 0 ? .white.opacity(0.4) : .white.opacity(0.85))
                        .frame(minWidth: 28)
                }
                .frame(height: 28).padding(.horizontal, 6)
            }
            Divider().frame(height: 14).background(Color.white.opacity(0.1))
            Button(action: { viewModel.transpose(by: 1) }) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.7))
                    .frame(width: 32, height: 28)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        )
    }

    private var stepLabel: String {
        let s = viewModel.transposeSteps
        if s == 0 { return "0" }
        return s > 0 ? "+\(s)" : "\(s)"
    }
}

struct ChordSheetView: View {
    @ObservedObject var viewModel: SongViewModel
    private var hasChords: Bool { viewModel.hasChords }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Add Annotation").foregroundStyle(.white).font(.headline).kerning(1)
                Text("Type a word or phrase to place above a word in your lyrics.")
                    .foregroundStyle(.gray).font(.system(size: 13)).multilineTextAlignment(.center).padding(.horizontal)
                TextField("e.g. [Em]", text: $viewModel.annotationText)
                    .font(.system(size: 15, design: .monospaced)).padding()
                    .background(.white.opacity(0.08)).foregroundStyle(.white).tint(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10)).padding(.horizontal)
                    .onChange(of: viewModel.annotationText) { _, newValue in
                        if newValue.count > 10 {
                            viewModel.annotationText = String(newValue.prefix(10))
                        }
                    }
                Button(action: viewModel.confirmAnnotation) {
                    Text("Choose Word →")
                        .foregroundStyle(.black).font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity).padding()
                        .background(.white).clipShape(RoundedRectangle(cornerRadius: 10)).padding(.horizontal)
                }
                if hasChords {
                    VStack(spacing: 8) {
                        Text("Transpose existing chords").foregroundStyle(.gray).font(.system(size: 12))
                        TransposeView(viewModel: viewModel)
                    }
                    .padding(.top, 4)
                }
                Button("Cancel", action: viewModel.cancelAnnotating).foregroundStyle(.gray).font(.system(size: 13))
            }
            .padding(.top, 40)
        }
        .presentationDetents([.fraction(hasChords ? 0.58 : 0.45)])
        .presentationBackground(Color.black)
    }
}
