//
//  BiometricLockView.swift
//  Nocturne
//
//  Created by Damoon saber on 4/4/1405 AP.
//


import SwiftUI
import LocalAuthentication

struct BiometricLockView: View {
    var onUnlock: () -> Void

    @State private var failed = false
    @State private var biometricType: LABiometryType = .none

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image(systemName: iconName)
                    .font(.system(size: 52, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.7))

                VStack(spacing: 8) {
                    Text("Nocturne is locked")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(.white.opacity(0.9))

                    Text(failed ? "Authentication failed. Try again." : subtitle)
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(failed ? .red.opacity(0.7) : .white.opacity(0.35))
                }

                Spacer()

                Button(action: authenticate) {
                    HStack(spacing: 8) {
                        Image(systemName: iconName)
                            .font(.system(size: 14, weight: .light))
                        Text(buttonLabel)
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(.white))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            detectBiometricType()
            authenticate()
        }
    }

    private var iconName: String {
        switch biometricType {
        case .faceID:  return "faceid"
        case .touchID: return "touchid"
        default:       return "lock"
        }
    }

    private var subtitle: String {
        switch biometricType {
        case .faceID:  return "Use Face ID to open Nocturne"
        case .touchID: return "Use Touch ID to open Nocturne"
        default:       return "Authenticate to open Nocturne"
        }
    }

    private var buttonLabel: String {
        switch biometricType {
        case .faceID:  return "Unlock with Face ID"
        case .touchID: return "Unlock with Touch ID"
        default:       return "Unlock"
        }
    }

    private func detectBiometricType() {
        let ctx = LAContext()
        var error: NSError?
        if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = ctx.biometryType
        }
    }

    private func authenticate() {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            onUnlock()   // no biometrics available — let them in
            return
        }
        ctx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock Nocturne") { success, _ in
            DispatchQueue.main.async {
                if success {
                    failed = false
                    onUnlock()
                } else {
                    failed = true
                    HapticManager.error()
                }
            }
        }
    }
}
