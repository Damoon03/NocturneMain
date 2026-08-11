//
//  LyricsTextView.swift
//  Nocturne
//
//  Created by Damoon saber on 3/28/1405 AP.
//

import SwiftUI
import UIKit

struct LyricsTextView: UIViewRepresentable {
    @Binding var text: String
    var fontSize: CGFloat
    var lineSpacing: CGFloat
    var lyricsFont: LyricsFontOption = .monospaced
    @Binding var isFocused: Bool

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.font = lyricsFont.uiFont(size: fontSize)
        textView.textColor = .white
        textView.tintColor = .white
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .sentences
        applyParagraphStyle(to: textView, text: text)
        context.coordinator.lastAppliedFont = lyricsFont
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Only reapply attributed text when the change originated OUTSIDE
        // this text view (e.g. loading a different song, undo, transpose,
        // or a lyrics font change from Profile). If the Coordinator itself
        // just wrote this text via typing, skip re-applying it — doing so
        // mid-edit caused the duplicated/ghosted text bug we fixed earlier.
        let fontChanged = context.coordinator.lastAppliedFont != lyricsFont
        if (!context.coordinator.isInternalUpdate && uiView.text != text) || fontChanged {
            let selectedRange = uiView.selectedRange
            applyParagraphStyle(to: uiView, text: text)
            uiView.selectedRange = selectedRange
            context.coordinator.lastAppliedFont = lyricsFont
        }
        context.coordinator.isInternalUpdate = false

        // Sync UIKit's first-responder state with SwiftUI's isFocused binding.
        if isFocused && !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        } else if !isFocused && uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.resignFirstResponder()
            }
        }
    }

    private func applyParagraphStyle(to textView: UITextView, text: String) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        let attributes: [NSAttributedString.Key: Any] = [
            .font: lyricsFont.uiFont(size: fontSize),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]
        textView.attributedText = NSAttributedString(string: text, attributes: attributes)
        textView.typingAttributes = attributes
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: LyricsTextView
        var isInternalUpdate = false
        var lastAppliedFont: LyricsFontOption?

        init(_ parent: LyricsTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            isInternalUpdate = true
            parent.text = textView.text
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            if !parent.isFocused {
                parent.isFocused = true
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if parent.isFocused {
                parent.isFocused = false
            }
        }
    }
}
