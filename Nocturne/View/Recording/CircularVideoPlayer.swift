//
//  CircularVideoPlayer.swift
//  Nocturne
//

import SwiftUI
import AVFoundation

struct CircularVideoPlayer: UIViewRepresentable {
    let url: URL
    @Binding var isPlaying: Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> PlayerUIView {
        PlayerUIView(url: url)
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        guard context.coordinator.isPlaying != isPlaying else { return }
        context.coordinator.isPlaying = isPlaying
        if isPlaying {
            uiView.player?.play()
        } else {
            uiView.player?.pause()
        }
    }

    final class Coordinator {
        var isPlaying = false
    }

    final class PlayerUIView: UIView {
        var player: AVPlayer?
        private var playerLayer: AVPlayerLayer?
        private var loopObserver: NSObjectProtocol?

        init(url: URL) {
            super.init(frame: .zero)
            backgroundColor = .clear
            setup(url: url)
        }

        required init?(coder: NSCoder) { fatalError() }

        private func setup(url: URL) {
            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            player.isMuted = false
            self.player = player

            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspectFill
            self.layer.addSublayer(layer)
            playerLayer = layer

            loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak player] _ in
                player?.seek(to: .zero)
                player?.play()
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer?.frame = bounds
        }

        deinit {
            if let obs = loopObserver { NotificationCenter.default.removeObserver(obs) }
            player?.pause()
        }
    }
}
