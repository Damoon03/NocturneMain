//
//  SwipeBackGesture.swift
//  Nocturne
//
//  ContentView hides the navigation bar entirely (.navigationBarBackButtonHidden
//  + .toolbar(.hidden, for: .navigationBar)) for its own custom back chevron.
//  As a side effect, SwiftUI/UIKit also disables the standard edge-swipe-to-go-back
//  gesture, since that gesture is normally tied to the (now hidden) back button.
//
//  This restores it globally: any UINavigationController — including the one
//  backing LibraryView's NavigationStack — becomes its own interactive pop
//  gesture delegate, so swiping right from ContentView still pops back to
//  LibraryView even with no back button visible.
//

import UIKit

extension UINavigationController: UIGestureRecognizerDelegate {
    open override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
