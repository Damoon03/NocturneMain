//
//  ProfileView.swift
//  Nocturne
//
//  Created by Damoon saber on 4/4/1405 AP.
//


import SwiftUI

struct ProfileView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var libraryVM: LibraryViewModel
    @ObservedObject var fragmentsVM: FragmentsViewModel
    var onDismiss: () -> Void

    // Local state
    @State private var showIconPicker = false

    // Derived stats
    private var activeSongs: [Song] { libraryVM.songs.filter { !$0.isDeleted } }
    private var totalWords: Int {
        activeSongs.reduce(0) { $0 + $1.lyrics.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count }
    }
    private var totalRecordings: Int { activeSongs.reduce(0) { $0 + $1.recordings.count } }
    private var totalChords: Int { activeSongs.reduce(0) { $0 + $1.chords.count } }
    private var totalFragments: Int { fragmentsVM.fragments.filter { !$0.isDeleted }.count }
    private var wordsLast7: Int { settings.wordsWritten(forLast: 7) }
    private var wordsLast30: Int { settings.wordsWritten(forLast: 30) }
    private var chartData: [(label: String, count: Int)] { settings.dailyData(forLast: 7) }
    private var chartMax: Int { max(chartData.map(\.count).max() ?? 1, 1) }

    var body: some View {
        ZStack {
            Color.nocturneSheetBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // ── Header ─────────────────────────────────────────
                    HStack {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .light))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        Spacer()
                        Text("Profile")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                        Spacer()
                        Image(systemName: "xmark").opacity(0)   // balance
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    .padding(.bottom, 28)

                    // ── 7-day word bar chart ───────────────────────────
                    VStack(alignment: .leading, spacing: 14) {
                        sectionHeader("Words written")

                        // Bar chart
                        HStack(alignment: .bottom, spacing: 6) {
                            ForEach(chartData, id: \.label) { day in
                                VStack(spacing: 4) {
                                    if day.count > 0 {
                                        Text("\(day.count)")
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundStyle(.white.opacity(0.3))
                                    }
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(day.count > 0
                                              ? Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.7)
                                              : Color.white.opacity(0.07))
                                        .frame(
                                            height: day.count == 0
                                                ? 4
                                                : max(4, CGFloat(day.count) / CGFloat(chartMax) * 80)
                                        )
                                    Text(day.label)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.25))
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 100, alignment: .bottom)
                        .padding(.horizontal, 4)

                        // Period totals
                        HStack(spacing: 0) {
                            statPill(value: "\(wordsLast7)", label: "last 7 days")
                            Spacer()
                            statPill(value: "\(wordsLast30)", label: "last 30 days")
                            Spacer()
                            statPill(value: "\(totalWords)", label: "all time")
                        }
                    }
                    .padding(20)
                    .background(cardBG)
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 14)

                    // ── Library stats grid ─────────────────────────────
                    VStack(alignment: .leading, spacing: 14) {
                        sectionHeader("Library")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            statCard(icon: "music.note",   value: "\(activeSongs.count)",    label: "Songs",       color: Color(red: 0.4, green: 0.6, blue: 1.0))
                            statCard(icon: "lightbulb",    value: "\(totalFragments)",        label: "Fragments",   color: Color(red: 1.0, green: 0.85, blue: 0.4))
                            statCard(icon: "waveform",     value: "\(totalRecordings)",       label: "Recordings",  color: Color(red: 0.6, green: 1.0, blue: 0.7))
                            statCard(icon: "guitars",      value: "\(totalChords)",           label: "Chord marks", color: Color(red: 0.8, green: 0.5, blue: 1.0))
                        }
                    }
                    .padding(20)
                    .background(cardBG)
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 14)

                    // ── Writing settings ───────────────────────────────
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("Writing")

                        VStack(spacing: 0) {
                            // Font size
                            HStack {
                                Text("Text size")
                                    .font(.system(size: 14)).foregroundStyle(.white.opacity(0.75))
                                Spacer()
                                Text("\(Int(settings.fontSize)) pt")
                                    .font(.system(size: 12, design: .monospaced)).foregroundStyle(.white.opacity(0.35))
                            }
                            Slider(value: $settings.fontSize, in: 11...20, step: 1)
                                .tint(.white.opacity(0.5))
                                .padding(.top, 6)
                                .onChange(of: settings.fontSize) { _, _ in HapticManager.selection() }
                        }
                    }
                    .padding(20)
                    .background(cardBG)
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 14)

                    // ── Security ───────────────────────────────────────
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("Security")
                        Toggle(isOn: $settings.biometricLockEnabled) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("App lock")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.75))
                                Text("Require Face ID or passcode when opening Nocturne")
                                    .font(.system(size: 11, weight: .light))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                        }
                        .tint(.white.opacity(0.6))
                        .onChange(of: settings.biometricLockEnabled) { _, _ in HapticManager.selection() }
                    }
                    .padding(20)
                    .background(cardBG)
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 14)

                    // ── App icon ───────────────────────────────────────
                    if SettingsStore.supportsAlternateIcons && SettingsStore.availableIcons.count > 1 {
                        VStack(alignment: .leading, spacing: 16) {
                            sectionHeader("App icon")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(SettingsStore.availableIcons, id: \.label) { icon in
                                        iconOption(icon)
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(cardBG)
                        .padding(.horizontal, 20)

                        Spacer().frame(height: 14)
                    }

                    // ── Export settings ────────────────────────────────
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("Export")
                        VStack(spacing: 10) {
                            infoRow(icon: "doc.text",              label: "PDF export",       detail: "Chord chart with lyrics")
                            infoRow(icon: "link",                  label: "Nocturne link",    detail: "Read-only in-app preview")
                            infoRow(icon: "doc.plaintext",         label: "Plain text",       detail: "Via share sheet")
                        }
                    }
                    .padding(20)
                    .background(cardBG)
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 14)

                    // ── About ──────────────────────────────────────────
                    VStack(spacing: 6) {
                        Image(systemName: "moon.stars")
                            .font(.system(size: 18, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.2))
                        Text("Nocturne")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(.white.opacity(0.2))
                            .kerning(3)
                        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                            Text("Version \(version)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.12))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Sub-components

    private var cardBG: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .kerning(1.5)
            .foregroundStyle(.white.opacity(0.3))
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .light, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
            Text(label)
                .font(.system(size: 10, weight: .light))
                .foregroundStyle(.white.opacity(0.3))
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(color.opacity(0.8))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .light, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                Text(label)
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(.white.opacity(0.3))
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.12), lineWidth: 0.5))
        )
    }

    private func infoRow(icon: String, label: String, detail: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 24)
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(detail)
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(.white.opacity(0.3))
        }
    }

    private func iconOption(_ icon: (name: String?, label: String)) -> some View {
        let isSelected = settings.selectedIconName == icon.name
        return Button(action: {
            settings.selectedIconName = icon.name
            HapticManager.impact(.medium)
        }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 56, height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isSelected ? Color.white.opacity(0.6) : Color.white.opacity(0.1),
                                        lineWidth: isSelected ? 1.5 : 0.5)
                        )
                    Image(systemName: "moon.stars")
                        .font(.system(size: 22, weight: .ultraLight))
                        .foregroundStyle(.white.opacity(isSelected ? 0.9 : 0.4))
                }
                Text(icon.label.components(separatedBy: " — ").last ?? icon.label)
                    .font(.system(size: 10, weight: .light))
                    .foregroundStyle(.white.opacity(isSelected ? 0.7 : 0.3))
            }
        }
    }

}
