//
//  SectionLabel.swift
//  Nocturne
//
//  Created by Damoon saber on 3/28/1405 AP.
//

import Foundation

enum SectionType: String, Codable, CaseIterable, Hashable {
    case intro = "Intro"
    case verse = "Verse"
    case bridge = "Bridge"
    case chorus = "Chorus"
    case hook = "Hook"
    case outro = "Outro"

    var shortName: String {
        switch self {
        case .verse: return "V"
        case .chorus: return "C"
        case .bridge: return "B"
        case .intro: return "I"
        case .outro: return "O"
        case .hook: return "H"
        }
    }

    var color: (r: Double, g: Double, b: Double) {
        switch self {
        case .verse:   return (0.4, 0.6, 1.0)
        case .chorus:  return (1.0, 0.5, 0.4)
        case .bridge:  return (0.6, 1.0, 0.7)
        case .intro:   return (1.0, 0.85, 0.4)
        case .outro:   return (0.8, 0.5, 1.0)
        case .hook: return (0.2, 0.85, 0.8)
        }
    }
}

struct SectionLabel: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var lineIndex: Int
    var type: SectionType
}
