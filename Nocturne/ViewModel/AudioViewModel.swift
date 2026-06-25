//
//  AudioViewModel.swift
//  Nocturne
//
//  Created by Damoon saber on 3/28/1405 AP.
//

import Foundation
import AVFoundation
import Combine

class AudioViewModel: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var permissionGranted = false
    @Published var recordings: [Recording] = []
    @Published var activeRecording: Recording? = nil
    @Published var recordingTime: TimeInterval = 0

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var recordingTimer: Timer?

    override init() {
        super.init()
        setupSession()
        checkPermission()
    }

    // MARK: - Setup

    private func setupSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try? session.setActive(true)
    }

    private func checkPermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            permissionGranted = true
        case .denied:
            permissionGranted = false
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async { self?.permissionGranted = granted }
            }
        @unknown default:
            break
        }
    }

    // MARK: - Recording

    func startRecording(for song: Song) {
        guard permissionGranted else {
            checkPermission()
            return
        }

        let fileName = "\(song.id.uuidString)_\(Date().timeIntervalSince1970).m4a"
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
            recordingTime = 0

            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.recordingTime = self?.audioRecorder?.currentTime ?? 0
            }
        } catch {
            print("Recording failed: \(error)")
        }
    }

    func stopRecording(for song: Song, completion: @escaping (Recording) -> Void) {
        guard let recorder = audioRecorder, isRecording else { return }

        let duration = recorder.currentTime
        let url = recorder.url
        let fileName = url.lastPathComponent

        recorder.stop()
        audioRecorder = nil
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingTime = 0

        let recording = Recording(
            fileName: fileName,
            createdAt: Date(),
            duration: duration
        )
        completion(recording)
    }

    // MARK: - Playback

    func play(_ recording: Recording) {
        guard recording.fileURL.isReachable else { return }

        stopPlayback()

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            activeRecording = recording
            duration = audioPlayer?.duration ?? 0
            isPlaying = true

            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.currentTime = self?.audioPlayer?.currentTime ?? 0
            }
        } catch {
            print("Playback failed: \(error)")
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        activeRecording = nil
        timer?.invalidate()
        timer = nil
    }

    func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
        timer?.invalidate()
    }

    func resumePlayback() {
        audioPlayer?.play()
        isPlaying = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.currentTime = self?.audioPlayer?.currentTime ?? 0
        }
    }

    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }

    func delete(_ recording: Recording) {
        if activeRecording?.id == recording.id { stopPlayback() }
        try? FileManager.default.removeItem(at: recording.fileURL)
    }

    // MARK: - Helpers

    func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time * 10).truncatingRemainder(dividingBy: 10))
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }
}

extension AudioViewModel: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag { isRecording = false }
    }
}

extension AudioViewModel: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentTime = 0
            self.activeRecording = nil
            self.timer?.invalidate()
        }
    }
}
