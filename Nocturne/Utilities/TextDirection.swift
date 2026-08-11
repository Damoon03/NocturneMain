//
//  TextDirection.swift
//  Nocturne
//
//  Detects whether a line of text is dominantly right-to-left (Persian,
//  Arabic, Hebrew, etc.) so word-by-word layouts like FlowLayout can
//  mirror their placement instead of always flowing left-to-right.
//

import Foundation

enum TextDirection {
    /// Returns true if `text`'s strongly-directional characters are
    /// predominantly right-to-left.
    static func isRTL(_ text: String) -> Bool {
        var rtlCount = 0
        var ltrCount = 0
        for scalar in text.unicodeScalars {
            if isRTLScalar(scalar) {
                rtlCount += 1
            } else if isLTRScalar(scalar) {
                ltrCount += 1
            }
        }
        return rtlCount > ltrCount
    }

    /// Right-to-left Unicode blocks: Hebrew, Arabic (covers Persian/Farsi
    /// and Urdu, which reuse the Arabic script), Syriac, Thaana, N'Ko,
    /// Samaritan, Mandaic, and their presentation-form blocks.
    ///
    /// Swift's `Unicode.Scalar.Properties` doesn't expose the Bidi_Class
    /// property directly, so this checks against the known RTL script
    /// ranges instead — sufficient for detecting dominant line direction
    /// without pulling in ICU.
    private static func isRTLScalar(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x0590...0x05FF,   // Hebrew
             0x0600...0x06FF,   // Arabic (incl. Persian)
             0x0700...0x074F,   // Syriac
             0x0750...0x077F,   // Arabic Supplement
             0x0780...0x07BF,   // Thaana
             0x07C0...0x07FF,   // N'Ko
             0x0800...0x083F,   // Samaritan
             0x0840...0x085F,   // Mandaic
             0x08A0...0x08FF,   // Arabic Extended-A
             0xFB1D...0xFB4F,   // Hebrew Presentation Forms
             0xFB50...0xFDFF,   // Arabic Presentation Forms-A
             0xFE70...0xFEFF:   // Arabic Presentation Forms-B
            return true
        default:
            return false
        }
    }

    /// Basic Latin and Latin-1/Extended letters count as a strongly
    /// left-to-right signal.
    private static func isLTRScalar(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x0041...0x005A,   // Latin A-Z
             0x0061...0x007A,   // Latin a-z
             0x00C0...0x024F:   // Latin-1 Supplement + Latin Extended-A/B
            return true
        default:
            return false
        }
    }
}
