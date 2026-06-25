//
//  VideoRecordingView.swift
//  Nocturne
//
//  Created by Damoon saber on 4/6/1405 AP.
//

import SwiftUI
import AVFoundation
import AVKit

// ─────────────────────────────────────────────
// MARK: - Camera preview (UIViewRepresentable)
// ─────────────────────────────────────────────

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        var session: AVCaptureSession? {
            get { previewLayer.session }
            set {
                previewLayer.session = newValue
                previewLayer.videoGravity = .resizeAspectFill
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - VideoRecorderViewModel
// ─────────────────────────────────────────────
import Combine

@MainActor
class VideoRecorderViewModel: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var permissionGranted = false
    @Published var cameraReady = false

    let session = AVCaptureSession()
    private var movieOutput = AVCaptureMovieFileOutput()
    private var timer: Timer?
    private var outputURL: URL?
    private var onFinish: ((URL, TimeInterval) -> Void)?

    static let maxDuration: TimeInterval = 60

    override init() {
        super.init()
        checkPermissions()
    }

    private func checkPermissions() {
        let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)

        if videoStatus == .authorized && audioStatus == .authorized {
            setupSession()
        } else if videoStatus == .notDetermined || audioStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
                AVCaptureDevice.requestAccess(for: .audio) { _ in
                    DispatchQueue.main.async { self?.setupSession() }
                }
            }
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        // Front camera
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(videoInput) else { return }
        session.addInput(videoInput)

        // Microphone
        if let mic = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: mic),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }

        // Output
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
            // Cap at maxDuration automatically
            movieOutput.maxRecordedDuration = CMTime(seconds: Self.maxDuration, preferredTimescale: 600)
        }

        session.commitConfiguration()

        Task.detached { [weak self] in
            self?.session.startRunning()
            await MainActor.run { self?.cameraReady = true; self?.permissionGranted = true }
        }
    }

    func startRecording(songID: UUID, completion: @escaping (URL, TimeInterval) -> Void) {
        let fileName = "\(songID.uuidString)_\(Date().timeIntervalSince1970).mp4"
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        outputURL = url
        onFinish = completion
        movieOutput.startRecording(to: url, recordingDelegate: self)
        isRecording = true
        recordingTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.recordingTime += 0.1
                if self.recordingTime >= Self.maxDuration { self.stopRecording() }
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        movieOutput.stopRecording()
        timer?.invalidate()
        timer = nil
        isRecording = false
    }

    func stopSession() {
        Task.detached { [weak self] in self?.session.stopRunning() }
    }
}

extension VideoRecorderViewModel: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        guard error == nil else { return }
        let duration = output.recordedDuration.seconds
        Task { @MainActor [weak self] in
            self?.onFinish?(outputFileURL, duration)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - VideoRecorderView (the sheet)
// ─────────────────────────────────────────────

struct VideoRecorderView: View {
    let songID: UUID
    let onSave: (Recording) -> Void
    @Binding var isPresented: Bool

    @StateObject private var vm = VideoRecorderViewModel()
    @State private var progressValue: Double = 0
    @State private var progressTimer: Timer? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Title
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Spacer()
                    Text("Video Note")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                        .kerning(1)
                    Spacer()
                    // Balance the X button
                    Color.clear.frame(width: 24, height: 24)
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 28)

                // Circular camera preview
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.04))
                        .frame(width: 260, height: 260)
                        .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))

                    if vm.cameraReady {
                        CameraPreviewView(session: vm.session)
                            .frame(width: 256, height: 256)
                            .clipShape(Circle())
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "video")
                                .font(.system(size: 28, weight: .ultraLight))
                                .foregroundStyle(.white.opacity(0.2))
                            Text("Preparing camera…")
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(.white.opacity(0.2))
                        }
                    }

                    // Recording progress ring
                    if vm.isRecording {
                        Circle()
                            .trim(from: 0, to: progressValue)
                            .stroke(Color.red.opacity(0.8), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 264, height: 264)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.1), value: progressValue)
                    }
                }
                .padding(.bottom, 36)

                // Timer
                Text(vm.isRecording ? formattedTime(vm.recordingTime) : "Max 60s")
                    .font(.system(size: 13, weight: .light, design: .monospaced))
                    .foregroundStyle(vm.isRecording ? .red.opacity(0.8) : .white.opacity(0.2))
                    .padding(.bottom, 36)

                // Record button
                Button(action: {
                    if vm.isRecording {
                        vm.stopRecording()
                        stopProgressTimer()
                    } else {
                        vm.startRecording(songID: songID) { url, duration in
                            let fileName = url.lastPathComponent
                            let recording = Recording(
                                fileName: fileName,
                                createdAt: Date(),
                                duration: duration,
                                kind: .video
                            )
                            onSave(recording)
                            isPresented = false
                        }
                        startProgressTimer()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(vm.isRecording ? Color.red.opacity(0.15) : Color.white.opacity(0.08))
                            .frame(width: 72, height: 72)
                            .overlay(Circle().stroke(
                                vm.isRecording ? Color.red.opacity(0.4) : Color.white.opacity(0.15),
                                lineWidth: 1
                            ))

                        if vm.isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.red.opacity(0.9))
                                .frame(width: 22, height: 22)
                        } else {
                            Circle()
                                .fill(Color.red.opacity(0.85))
                                .frame(width: 28, height: 28)
                        }
                    }
                }
                .disabled(!vm.cameraReady)

                Spacer()
            }
        }
        .presentationDetents([.fraction(0.88)])
        .presentationBackground(Color.black)
        .presentationDragIndicator(.hidden)
        .onDisappear {
            vm.stopRecording()
            vm.stopSession()
            stopProgressTimer()
        }
    }

    private func startProgressTimer() {
        progressValue = 0
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                progressValue = min(vm.recordingTime / VideoRecorderViewModel.maxDuration, 1.0)
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
        progressValue = 0
    }

    private func formattedTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        let tenth = Int((t * 10).truncatingRemainder(dividingBy: 10))
        return String(format: "%d:%02d.%d", m, s, tenth)
    }
}

// ─────────────────────────────────────────────
// MARK: - Circular video player
// ─────────────────────────────────────────────

struct CircularVideoPlayer: UIViewRepresentable {
    let url: URL
    @Binding var isPlaying: Bool

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView(url: url)
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        if isPlaying {
            uiView.player?.play()
        } else {
            uiView.player?.pause()
        }
    }

    class PlayerUIView: UIView {
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
            let p = AVPlayer(playerItem: item)
            p.isMuted = false
            player = p

            let layer = AVPlayerLayer(player: p)
            layer.videoGravity = .resizeAspectFill
            self.layer.addSublayer(layer)
            playerLayer = layer

            // Loop
            loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak p] _ in
                p?.seek(to: .zero)
                p?.play()
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

// ─────────────────────────────────────────────
// MARK: - VideoNoteSheet (full-screen player)
// ─────────────────────────────────────────────

struct VideoNoteSheet: View {
    let recording: Recording
    let onDelete: () -> Void
    @Binding var isPresented: Bool

    @State private var isPlaying = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Spacer()
                    Text(formatDate(recording.createdAt))
                        .font(.system(size: 12, weight: .light, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                    Spacer()
                    Button(action: {
                        isPresented = false
                        onDelete()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(.red.opacity(0.5))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 36)

                // Circular player
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.03))
                        .frame(width: 280, height: 280)

                    if recording.fileURL.isReachable {
                        CircularVideoPlayer(url: recording.fileURL, isPlaying: $isPlaying)
                            .frame(width: 276, height: 276)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "video.slash")
                                .font(.system(size: 28, weight: .ultraLight))
                                .foregroundStyle(.white.opacity(0.2))
                            Text("File not found")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.2))
                        }
                    }

                    // Tap to pause/play
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 276, height: 276)
                        .contentShape(Circle())
                        .onTapGesture { isPlaying.toggle() }

                    // Pause indicator
                    if !isPlaying {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.4))
                                .frame(width: 56, height: 56)
                            Image(systemName: "play.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
                .padding(.bottom, 32)

                Text(formattedDuration(recording.duration))
                    .font(.system(size: 12, weight: .light, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.25))

                Spacer()
            }
        }
        .presentationDetents([.fraction(0.75)])
        .presentationBackground(Color.black)
        .presentationDragIndicator(.hidden)
        .onDisappear { isPlaying = false }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mm a"
        return f.string(from: date)
    }

    private func formattedDuration(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}
