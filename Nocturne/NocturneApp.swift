//
//  NocturneApp.swift
//  Nocturne
//
//  Created by Damoon saber on 3/28/1405 AP.
//


import SwiftUI

@main
struct NocturneApp: App {
    @StateObject private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            RootView(settings: settings)
        }
    }
}

private struct RootView: View {
    @ObservedObject var settings: SettingsStore
    @State private var sharedPayload: SharedSongPayload? = nil
    @State private var showingSharedSong = false
    @State private var showingWelcome = !UserDefaults.standard.bool(forKey: "nocturne_hasSeenWelcome")
    @State private var isUnlocked = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if settings.biometricLockEnabled && !isUnlocked {
                BiometricLockView { isUnlocked = true }
            } else {
                LibraryView(settings: settings)
                    .onOpenURL { url in
                        if let payload = NocturneShareLink.decode(url) {
                            sharedPayload = payload
                            showingSharedSong = true
                        }
                    }
                    .sheet(isPresented: $showingSharedSong) {
                        if let payload = sharedPayload {
                            SharedSongView(payload: payload) {
                                showingSharedSong = false
                                sharedPayload = nil
                            }
                        }
                    }
                    .fullScreenCover(isPresented: $showingWelcome) {
                        WelcomeView { showingWelcome = false }
                    }
            }
        }
        .onAppear {
            if !settings.biometricLockEnabled {
                isUnlocked = true
            }
        }
        .onChange(of: settings.biometricLockEnabled) { _, enabled in
            isUnlocked = !enabled
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background, settings.biometricLockEnabled {
                isUnlocked = false
            }
        }
    }
}
