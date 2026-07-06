//
//  WordFrameMeasurement.swift
//  Nocturne
//

import SwiftUI

struct WordFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    @ViewBuilder
    func wordFrameMeasurement(lineIndex: Int, wordIndex: Int, coordinateSpace: String, enabled: Bool) -> some View {
        if enabled {
            background {
                GeometryReader { geo in
                    Color.clear.preference(
                        key: WordFramePreferenceKey.self,
                        value: ["\(lineIndex):\(wordIndex)": geo.frame(in: .named(coordinateSpace))]
                    )
                }
            }
        } else {
            self
        }
    }
}
