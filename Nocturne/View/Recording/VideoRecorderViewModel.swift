//
//  VideoRecorderViewModel.swift
//  Nocturne
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class VideoRecorderViewModel: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var permissionGranted = false
    @Published var cameraReady = false

    let session = AVCaptureSession()
    private var movieOutput = AVCaptureMovieFileOutput()
    private var timer: Timer?
    private var onFinish: ((URL, TimeInterval) -> Void)?

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
                    Task { @MainActor in self?.setupSession() }
                }
            }
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(videoInput) else { return }
        session.addInput(videoInput)

        if let mic = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: mic),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }

        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
            movieOutput.maxRecordedDuration = .invalid
        }

        session.commitConfiguration()

        Task.detached { [weak self] in
            self?.session.startRunning()
            await MainActor.run {
                self?.cameraReady = true
                self?.permissionGranted = true
            }
        }
    }

    func startRecording(songID: UUID, completion: @escaping (URL, TimeInterval) -> Void) {
        let fileName = "\(songID.uuidString)_\(Date().timeIntervalSince1970).mp4"
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        onFinish = completion
        movieOutput.startRecording(to: url, recordingDelegate: self)
        isRecording = true
        recordingTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.recordingTime += 0.1 }
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
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        guard error == nil else { return }
        let duration = output.recordedDuration.seconds
        Task { @MainActor [weak self] in
            self?.onFinish?(outputFileURL, duration)
        }
    }
}
