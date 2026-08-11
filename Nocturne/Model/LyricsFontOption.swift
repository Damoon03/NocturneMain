//
//  LyricsFontOption.swift
//  Nocturne
//
//  The set of fonts a user can choose for lyrics display + editing,
//  picked in Profile and applied everywhere lyrics are rendered.
//

import SwiftUI
import UIKit

enum LyricsFontOption: String, CaseIterable, Identifiable, Codable {
    case monospaced
    case cormorantGaramond
    case baskervville
    case alegreya

    var id: String { rawValue }

    /// Order shown in the picker: Monospaced → Cormorant Garamond → Baskervville → Alegreya.
    static var displayOrder: [LyricsFontOption] {
        [.monospaced, .cormorantGaramond, .baskervville, .alegreya]
    }

    var displayName: String {
        switch self {
        case .monospaced: return "Monospaced"
        case .cormorantGaramond: return "Cormorant Garamond"
        case .baskervville: return "Baskervville"
        case .alegreya: return "Alegreya"
        }
    }

    /// The exact PostScript name the font file must be registered under
    /// for `Font.custom` / `UIFont(name:)` to find it. These match each
    /// family's standard regular-weight release. `monospaced` has no
    /// PostScript name since it always uses the system monospaced font.
    var postScriptName: String? {
        switch self {
        case .monospaced: return nil
        case .cormorantGaramond: return "CormorantGaramond-Regular"
        case .baskervville: return "Baskervville-Regular"
        case .alegreya: return "Alegreya-Regular"
        }
    }

    /// True once the actual font file has been added to the app bundle
    /// and registered. Nocturne falls back gracefully until then, so
    /// picking an option that isn't bundled yet never looks broken.
    /// Always true for `monospaced`, since it's a system font.
    var isInstalled: Bool {
        guard let postScriptName else { return true }
        return UIFont(name: postScriptName, size: 12) != nil
    }

    /// SwiftUI font for lyrics, at the given point size.
    func font(size: CGFloat) -> Font {
        if let postScriptName, isInstalled {
            return .custom(postScriptName, size: size)
        }
        return .system(size: size, weight: .regular, design: .monospaced)
    }

    /// UIKit font, used by the lyrics UITextView so typing matches the
    /// read-mode display exactly.
    func uiFont(size: CGFloat) -> UIFont {
        guard let postScriptName, let font = UIFont(name: postScriptName, size: size) else {
            return UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
        }
        return font
    }
}
