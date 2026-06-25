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
    @State private var sharedPayload: SharedSongPayload? = nil
    @State private var showingSharedSong = false
    @State private var showingWelcome = !UserDefaults.standard.bool(forKey: "nocturne_hasSeenWelcome")

    var body: some Scene {
        WindowGroup {
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
}
