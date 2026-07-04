//
//  DataPersistence.swift
//  Nocturne
//

import Foundation

enum DataPersistence {
    private static let libraryFolderName = "Nocturne"

    static var libraryDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let url = base.appendingPathComponent(libraryFolderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    static func save<T: Encodable>(_ value: T, to filename: String) throws {
        let url = libraryDirectory.appendingPathComponent(filename)
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: .atomic)
    }

    static func load<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
        let url = libraryDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    /// Loads from Application Support if present; otherwise migrates from UserDefaults once.
    static func loadOrMigrate<T: Codable>(userDefaultsKey: String, filename: String) -> T? {
        if let stored: T = load(T.self, from: filename) { return stored }

        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }

        try? save(decoded, to: filename)
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        return decoded
    }
}
