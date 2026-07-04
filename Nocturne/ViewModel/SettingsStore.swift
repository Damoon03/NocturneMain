//
//  SettingsStore.swift
//  Nocturne
//
//  Created by Damoon saber on 4/4/1405 AP.
//


import SwiftUI
import Combine

class SettingsStore: ObservableObject {

    // MARK: - Writing
    @Published var fontSize: Double {
        didSet { UserDefaults.standard.set(fontSize, forKey: "nocturne_fontSize") }
    }

    // MARK: - App icon
    @Published var selectedIconName: String? {
        didSet {
            UserDefaults.standard.set(selectedIconName, forKey: "nocturne_appIcon")
            applyIcon()
        }
    }

    // MARK: - Security
    @Published var biometricLockEnabled: Bool {
        didSet { UserDefaults.standard.set(biometricLockEnabled, forKey: "nocturne_biometricLock") }
    }

    // MARK: - Stats tracking
    /// Daily word counts keyed by "yyyy-MM-dd"
    @Published var dailyWordCounts: [String: Int] {
        didSet { saveDailyWordCounts() }
    }

    /// Last known total word count per song id (to compute deltas)
    private var lastWordCounts: [UUID: Int] = [:]

    init() {
        let storedSize = UserDefaults.standard.double(forKey: "nocturne_fontSize")
        fontSize = storedSize < 10 ? 13 : storedSize

        biometricLockEnabled = UserDefaults.standard.bool(forKey: "nocturne_biometricLock")

        if let data = UserDefaults.standard.data(forKey: "nocturne_dailyWordCounts"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            dailyWordCounts = decoded
        } else {
            dailyWordCounts = [:]
        }

        var storedIconName = UserDefaults.standard.string(forKey: "nocturne_appIcon")
        if storedIconName != nil, !Self.supportsAlternateIcons {
            storedIconName = nil
        }
        selectedIconName = storedIconName
    }

    // MARK: - Word count tracking

    /// Call this whenever a song is saved/updated.
    func trackWordCount(for song: Song) {
        let newCount = song.lyrics
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        let oldCount = lastWordCounts[song.id] ?? newCount
        let delta = max(0, newCount - oldCount)
        lastWordCounts[song.id] = newCount

        if delta > 0 {
            let key = todayKey()
            dailyWordCounts[key, default: 0] += delta
        }
    }

    func wordsWritten(forLast days: Int) -> Int {
        let cal = Calendar.current
        return (0..<days).reduce(0) { total, offset in
            guard let date = cal.date(byAdding: .day, value: -offset, to: Date()) else { return total }
            let key = dateKey(date)
            return total + (dailyWordCounts[key] ?? 0)
        }
    }

    func dailyData(forLast days: Int) -> [(label: String, count: Int)] {
        let cal = Calendar.current
        let df = DateFormatter()
        df.dateFormat = "EEE"
        return (0..<days).reversed().compactMap { offset in
            guard let date = cal.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let key = dateKey(date)
            return (label: df.string(from: date), count: dailyWordCounts[key] ?? 0)
        }
    }

    // MARK: - App icons
    static let availableIcons: [(name: String?, label: String)] = [
        (nil, "Default"),
    ]

    static var supportsAlternateIcons: Bool {
        guard UIApplication.shared.supportsAlternateIcons else { return false }
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") != nil
    }

    private func applyIcon() {
        guard Self.supportsAlternateIcons else { return }
        UIApplication.shared.setAlternateIconName(selectedIconName) { _ in }
    }

    // MARK: - Helpers
    private func todayKey() -> String { dateKey(Date()) }

    private func dateKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func saveDailyWordCounts() {
        if let data = try? JSONEncoder().encode(dailyWordCounts) {
            UserDefaults.standard.set(data, forKey: "nocturne_dailyWordCounts")
        }
    }
}
