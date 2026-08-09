//
//  RhymeService.swift
//  Nocturne
//
//  Rhyme lookup via the Datamuse API. Ported from the Expo/React Native
//  rewrite's `packages/shared/src/text/rhyme.ts` + `apps/mobile/src/services/rhyme.ts`.
//  Pure, stateless — no writes back into Song, same spirit as SongExporter.
//

import Foundation

enum RhymeKind: String {
    case perfect
    case near
}

struct RhymeCandidate: Identifiable, Hashable {
    var id: String { word }
    let word: String
    let score: Int
    let syllables: Int?
    let kind: RhymeKind
}

enum SyllableFilter: Hashable {
    case all
    case count(Int)   // 1, 2, 3, or 4 (meaning "4+")
}

struct RhymeService {

    struct LookupResult {
        let source: String
        let sourceSyllables: Int?
        let rhymes: [RhymeCandidate]
    }

    /// Strips leading/trailing punctuation for lexicon lookups, e.g. "night," -> "night".
    static func cleanWord(_ raw: String) -> String {
        var s = raw
        while let f = s.first, !(f.isLetter || f.isNumber || f == "'") {
            s.removeFirst()
        }
        while let l = s.last, !(l.isLetter || l.isNumber || l == "'") {
            s.removeLast()
        }
        return s
    }

    /// Fetch perfect + near rhymes from Datamuse, ranked for songwriting use.
    /// Requires network.
    static func lookupRhymes(for rawWord: String) async throws -> LookupResult {
        let source = cleanWord(rawWord)
        guard !source.isEmpty else {
            return LookupResult(source: "", sourceSyllables: nil, rhymes: [])
        }

        let q = source.lowercased()
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? source.lowercased()

        async let perfectTask = fetchRows(query: "rel_rhy=\(q)&md=s&max=40")
        async let nearTask = fetchRows(query: "rel_nry=\(q)&md=s&max=24")
        async let metaTask = fetchRows(query: "sp=\(q)&md=s&max=1")

        let perfectRows = try await perfectTask
        let nearRows = try await nearTask
        let metaRows = try await metaTask

        let sourceSyllables = metaRows.first?.numSyllables

        let selfLower = source.lowercased()
        var combined: [RhymeCandidate] = []
        combined.append(contentsOf: mapRows(perfectRows, kind: .perfect))
        combined.append(contentsOf: mapRows(nearRows, kind: .near))
        combined = combined.filter { $0.word.lowercased() != selfLower }

        let ranked = rank(combined, sourceSyllables: sourceSyllables)
        return LookupResult(source: source, sourceSyllables: sourceSyllables, rhymes: ranked)
    }

    /// Rank rhymes for songwriting: perfect first, then same syllable count as
    /// the source, then Datamuse popularity score. Near rhymes sort after perfect.
    private static func rank(_ candidates: [RhymeCandidate], sourceSyllables: Int?) -> [RhymeCandidate] {
        var seen = Set<String>()
        var unique: [RhymeCandidate] = []
        for c in candidates {
            let key = c.word.lowercased()
            if seen.contains(key) { continue }
            seen.insert(key)
            unique.append(c)
        }

        return unique.sorted { a, b in
            let aKind = a.kind == .perfect ? 0 : 1
            let bKind = b.kind == .perfect ? 0 : 1
            if aKind != bKind { return aKind < bKind }

            if let s = sourceSyllables {
                let aMatch = (a.syllables == s) ? 0 : 1
                let bMatch = (b.syllables == s) ? 0 : 1
                if aMatch != bMatch { return aMatch < bMatch }
            }

            return a.score > b.score
        }
    }

    static func filterBySyllables(_ candidates: [RhymeCandidate], filter: SyllableFilter) -> [RhymeCandidate] {
        switch filter {
        case .all:
            return candidates
        case .count(4):
            return candidates.filter { ($0.syllables ?? -1) >= 4 }
        case .count(let n):
            return candidates.filter { $0.syllables == n }
        }
    }

    // MARK: - Datamuse networking

    private struct DatamuseRow: Decodable {
        let word: String?
        let score: Int?
        let numSyllables: Int?
    }

    private static func mapRows(_ rows: [DatamuseRow], kind: RhymeKind) -> [RhymeCandidate] {
        rows.compactMap { row in
            guard let word = row.word?.trimmingCharacters(in: .whitespaces),
                  !word.isEmpty, !word.contains(" ") else { return nil }
            return RhymeCandidate(word: word, score: row.score ?? 0, syllables: row.numSyllables, kind: kind)
        }
    }

    private static func fetchRows(query: String) async throws -> [DatamuseRow] {
        guard let url = URL(string: "https://api.datamuse.com/words?\(query)") else { return [] }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([DatamuseRow].self, from: data)
    }
}
