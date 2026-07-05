//
//  MotionAware.swift
//  Nocturne
//

import SwiftUI

extension View {
    @ViewBuilder
    func motionAwareAnimation(_ animation: Animation?, value: some Equatable) -> some View {
        modifier(MotionAwareAnimationModifier(animation: animation, value: value))
    }

    @ViewBuilder
    func motionAwareAppearOpacity(_ opacity: Double) -> some View {
        modifier(MotionAwareAppearOpacityModifier(targetOpacity: opacity))
    }
}

private struct MotionAwareAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation?
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

private struct MotionAwareAppearOpacityModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let targetOpacity: Double
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                if reduceMotion {
                    opacity = targetOpacity
                } else {
                    withAnimation(.easeIn(duration: 0.9)) {
                        opacity = targetOpacity
                    }
                }
            }
    }
}
