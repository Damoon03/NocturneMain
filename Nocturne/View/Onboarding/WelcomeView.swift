//
//  WelcomeView.swift
//  Nocturne
//
//  Created by Damoon saber on 4/4/1405 AP.
//
//  Shown exactly once — on first launch after install.
//  Stored in UserDefaults under "nocturne_hasSeenWelcome".
//

import SwiftUI

// MARK: - Feature card model

private struct Feature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}

private let features: [Feature] = [
    Feature(
        icon: "music.note",
        title: "Write freely",
        description: "A distraction-free canvas for lyrics, with chords placed exactly above the words they belong to.",
        color: Color(red: 0.4, green: 0.6, blue: 1.0)
    ),
    Feature(
        icon: "lightbulb",
        title: "Capture fragments",
        description: "Catch a lyric line, riff, title idea, or mood the moment it surfaces — before it disappears.",
        color: Color(red: 1.0, green: 0.85, blue: 0.4)
    ),
    Feature(
        icon: "waveform",
        title: "Record as you write",
        description: "Lay down voice memos and melodies right inside the song. Star your best takes as the main recording.",
        color: Color(red: 0.6, green: 1.0, blue: 0.7)
    ),
    Feature(
        icon: "folder",
        title: "Stay organised",
        description: "Group songs into folders — finished work, demos, experiments — and find anything instantly by chord or lyric.",
        color: Color(red: 0.8, green: 0.5, blue: 1.0)
    ),
    Feature(
        icon: "link",
        title: "Share your work",
        description: "Export a chord-chart PDF or send a Nocturne link so collaborators can read the song in the app.",
        color: Color(red: 1.0, green: 0.5, blue: 0.4)
    ),
]

// MARK: - WelcomeView

struct WelcomeView: View {
    var onDismiss: () -> Void

    @State private var currentPage = 0
    @State private var headerOpacity: Double = 0
    @State private var cardOpacity: Double = 0
    @State private var cardOffset: CGFloat = 24

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Logo header ───────────────────────────────────────
                VStack(spacing: 10) {
                    Image(systemName: "moon.stars")
                        .font(.system(size: 36, weight: .ultraLight))
                        .foregroundStyle(.white.opacity(0.9))

                    Text("Nocturne")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(.white)
                        .kerning(6)

                    Text("A songwriter's sketchbook")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(.white.opacity(0.35))
                        .kerning(0.5)
                }
                .padding(.top, 64)
                .padding(.bottom, 48)
                .opacity(headerOpacity)

                // ── Feature cards (paged) ─────────────────────────────
                TabView(selection: $currentPage) {
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        featureCard(feature)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 280)
                .opacity(cardOpacity)
                .offset(y: cardOffset)

                // ── Page dots ─────────────────────────────────────────
                HStack(spacing: 6) {
                    ForEach(0..<features.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage
                                  ? features[currentPage].color
                                  : Color.white.opacity(0.15))
                            .frame(width: i == currentPage ? 18 : 5, height: 5)
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.top, 24)
                .opacity(cardOpacity)

                Spacer()

                // ── Action button ─────────────────────────────────────
                VStack(spacing: 14) {
                    if currentPage < features.count - 1 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        }) {
                            Text("Next")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.white)
                                )
                        }

                        Button(action: dismiss) {
                            Text("Skip")
                                .font(.system(size: 13, weight: .light))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    } else {
                        Button(action: dismiss) {
                            Text("Start writing")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.white)
                                )
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .opacity(cardOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                headerOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                cardOpacity = 1
                cardOffset = 0
            }
        }
    }

    // MARK: - Feature card
    private func featureCard(_ feature: Feature) -> some View {
        VStack(spacing: 0) {
            // Icon
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.1))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle().stroke(feature.color.opacity(0.2), lineWidth: 0.75)
                    )
                Image(systemName: feature.icon)
                    .font(.system(size: 26, weight: .ultraLight))
                    .foregroundStyle(feature.color.opacity(0.9))
            }
            .padding(.bottom, 24)

            // Title
            Text(feature.title)
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(.white)
                .kerning(0.3)
                .padding(.bottom, 12)

            // Description
            Text(feature.description)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 36)
        }
        .padding(.horizontal, 24)
    }

    private func dismiss() {
        UserDefaults.standard.set(true, forKey: "nocturne_hasSeenWelcome")
        onDismiss()
    }
}

// MARK: - Preview
#Preview {
    WelcomeView(onDismiss: {})
}
