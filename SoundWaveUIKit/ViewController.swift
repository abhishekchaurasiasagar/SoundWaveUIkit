//
//  ViewController.swift
//  SoundWaveUIKit
//
//  Created by Abhishek on 23/12/23.
//

import UIKit
import AVFoundation

class MusicVC: UIViewController {
    let audioSession = AVAudioSession.sharedInstance()
    var audioEngine: AVAudioEngine!
    var audioPlayer: AVPlayer!
    var displayLink: CADisplayLink?

    var audioBuffer = [Float]()
    var visualizerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupAudioSession()
        setupAudioEngine()
        setupVisualizer()
        setupAudioPlayer()
    }

    func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Audio session setup error: \(error.localizedDescription)")
        }
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { }
    }

    func setupAudioEngine() {
        configureAudioSession()
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode

        let outputFormat = inputNode.inputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: outputFormat) { buffer, _ in
            let bufferPointer = buffer.floatChannelData?[0]
            let bufferLength = Int(buffer.frameLength)

            self.audioBuffer = Array(UnsafeBufferPointer(start: bufferPointer, count: bufferLength))
        }

        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start error: \(error.localizedDescription)")
        }
    }

    func setupVisualizer() {
        visualizerView = UIView(frame: CGRect(x: 0, y: 200, width: self.view.frame.width, height: 200))
        visualizerView.backgroundColor = UIColor.clear
        view.addSubview(visualizerView)
    }

    func setupAudioPlayer() {
        guard let audioURL = Bundle.main.url(forResource: "Song5", withExtension: "mp3") else {
            fatalError("Audio file not found")
        }

        audioPlayer = AVPlayer(url: audioURL)
        audioPlayer.play()

        displayLink = CADisplayLink(target: self, selector: #selector(updateVisualizer))
        displayLink?.add(to: .current, forMode: .common)
    }

    @objc func updateVisualizer() {
        guard let playerItem = audioPlayer.currentItem else { return }

        let currentTime = CMTimeGetSeconds(playerItem.currentTime())
        let duration = CMTimeGetSeconds(playerItem.duration)

        if currentTime >= duration {
            displayLink?.invalidate()
            return
        }

        let width = visualizerView.bounds.width
        let height = visualizerView.bounds.height
        let rectCount = 9
        let spaceBetweenRects: CGFloat = 10.0

        // Calculate the total width available for rectangles, considering the space between them
        let totalWidth = width - CGFloat(rectCount - 1) * spaceBetweenRects

        // Calculate the width of each rectangle
        let rectWidth = totalWidth / CGFloat(rectCount)

        // Ensure audio buffer is not empty
        guard !audioBuffer.isEmpty else { return }

        // Clear the previous drawings
        visualizerView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        for i in 0..<rectCount {
            let bufferIndex = i % audioBuffer.count
            let normalizedValue = CGFloat(audioBuffer[bufferIndex])

            // Scale the normalizedValue to be between 20 and 100
            let rectHeight = max(min(normalizedValue * 80 + 20, 100), 20)

            // Calculate the position of each rectangle, considering the space between them
            let x = CGFloat(i) * (rectWidth + spaceBetweenRects)
            let y = (height - rectHeight) / 2.0

            let rectLayer = CALayer()
            rectLayer.frame = CGRect(x: x, y: y, width: rectWidth, height: rectHeight)
            rectLayer.backgroundColor = UIColor.green.cgColor

            visualizerView.layer.addSublayer(rectLayer)
        }
    }
}


