//
//  ContentView.swift
//  NewColours Watch App
//
//  Created by Tomasz Szornel on 1/14/26.
//

import SwiftUI
import AVFoundation
import Combine
import WatchKit
import Accelerate

private enum AppLanguage: String, CaseIterable, Identifiable { case pl, en; var id: String { rawValue } }

struct ContentView: View {
    @State private var gameState: GameState = .menu
    @State private var score: Int = 0
    @State private var level: Int = 1
    @State private var currentTarget: GameColor = .red
    @State private var availableColors: [GameColor] = GameColor.basic
    @State private var beatTimer: Timer? = nil
    @State private var beatInterval: TimeInterval = 1.0
    @State private var timeRemaining: TimeInterval = 1.0
    @State private var lastBeatDate: Date = .init()
    @State private var backgroundPhase: CGFloat = 0
    @State private var isAnimatingBG: Bool = true
    @State private var audioPlayer: AVAudioPlayer?
    @State private var bpm: Double = 100 // beats per minute for sync with audio
    @State private var availableTracks: [String] = [] // filenames without extension
    @State private var selectedTrack: String = "track" // default
    @State private var isEstimatingBPM: Bool = false
    @AppStorage("appLanguage") private var appLanguageRaw: String = "pl"

    private var titleKey: LocalizedStringKey { "music_colours_title" }
    private var subtitleKey: LocalizedStringKey { "subtitle" }
    private var startKey: LocalizedStringKey { "start" }
    private var scoreKey: LocalizedStringKey { "score" }
    private var levelKey: LocalizedStringKey { "level" }
    private var gameOverKey: LocalizedStringKey { "game_over" }
    private var playAgainKey: LocalizedStringKey { "play_again" }
    private var languageKey: LocalizedStringKey { "language" }

    var body: some View {
        ZStack {
            AnimatedDepthBackground(phase: backgroundPhase, colors: availableColors.map { $0.color })
                .ignoresSafeArea()
                .saturation(gameState == .gameOver ? 0.2 : 1.0)
                .blur(radius: gameState == .gameOver ? 2 : 0)
                .animation(.easeInOut(duration: 0.35), value: gameState)

            switch gameState {
            case .menu:
                MenuView(
                    appLanguage: $appLanguageRaw,
                    selectedTrack: $selectedTrack,
                    availableTracks: availableTracks,
                    bpm: bpm,
                    isEstimatingBPM: isEstimatingBPM,
                    startAction: startGame,
                    titleKey: titleKey,
                    subtitleKey: subtitleKey,
                    languageKey: languageKey,
                    startKey: startKey
                )
            case .playing:
                GamePlayView(
                    score: score,
                    level: level,
                    target: currentTarget,
                    colors: availableColors,
                    timeRemaining: timeRemaining,
                    onTapColor: handleTap(color:),
                    scoreKey: scoreKey,
                    levelKey: levelKey
                )
                .transition(.scale.combined(with: .opacity))
            case .gameOver:
                GameOverView(
                    score: score,
                    level: level,
                    restartAction: restart,
                    gameOverKey: gameOverKey,
                    playAgainKey: playAgainKey,
                    scoreKey: scoreKey,
                    levelKey: levelKey
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            setupAudioSession()
            loadAvailableTracks()
        }
        .onChange(of: gameState) { _, newValue in
            if newValue == .playing {
                updateBeatInterval(syncedToBPM: audioPlayer != nil)
                startBeatLoop()
            } else {
                stopBeatLoop()
            }
        }
        .onReceive(Timer.publish(every: 1/30, on: .main, in: .common).autoconnect()) { _ in
            // Background animation phase
            if isAnimatingBG { backgroundPhase += 0.01 }
            // Countdown update while playing
            guard gameState == .playing else { return }
            let elapsed = Date().timeIntervalSince(lastBeatDate)
            timeRemaining = max(0, beatInterval - elapsed)
            if timeRemaining == 0 { endGame() }
        }
    }

    func loadAvailableTracks() {
        let exts = ["m4a", "mp3"]
        var names: Set<String> = []
        for ext in exts {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                for u in urls { names.insert(u.deletingPathExtension().lastPathComponent) }
            }
        }
        availableTracks = Array(names).sorted()
        if availableTracks.isEmpty { availableTracks = ["track"] }
        if !availableTracks.contains(selectedTrack) { selectedTrack = availableTracks.first ?? "track" }
    }
}

// MARK: - Views
private struct MenuView: View {
    @Binding var appLanguage: String
    @Binding var selectedTrack: String
    let availableTracks: [String]
    let bpm: Double
    let isEstimatingBPM: Bool
    var startAction: () -> Void
    let titleKey: LocalizedStringKey
    let subtitleKey: LocalizedStringKey
    let languageKey: LocalizedStringKey
    let startKey: LocalizedStringKey

    var body: some View {
        VStack(spacing: 8) {
            Text(titleKey)
                .font(.title2).bold()
            Text(subtitleKey)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .opacity(0.8)
            HStack(spacing: 6) {
                Text(languageKey).font(.caption2)
                Spacer()
                Picker("", selection: $appLanguage) {
                    Text("Polski").tag("pl")
                    Text("English").tag("en")
                }
                .labelsHidden()
            }
            HStack(spacing: 6) {
                Text("Track").font(.caption2)
                Spacer()
                Picker("", selection: $selectedTrack) {
                    ForEach(availableTracks, id: \.self) { t in
                        Text(t).tag(t)
                    }
                }
                .labelsHidden()
            }
            HStack(spacing: 6) {
                Text("BPM").font(.caption2)
                Spacer()
                if isEstimatingBPM { ProgressView().scaleEffect(0.8) }
                Text(String(Int(bpm)))
                    .font(.caption2).monospacedDigit()
            }
            Button(action: startAction) {
                Text(startKey)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

private struct GamePlayView: View {
    let score: Int
    let level: Int
    let target: GameColor
    let colors: [GameColor]
    let timeRemaining: TimeInterval
    let onTapColor: (GameColor) -> Void
    let scoreKey: LocalizedStringKey
    let levelKey: LocalizedStringKey

    private func nameKey(for color: GameColor) -> LocalizedStringKey {
        switch color {
        case .red: return "color_red"
        case .green: return "color_green"
        case .blue: return "color_blue"
        case .yellow: return "color_yellow"
        case .purple: return "color_purple"
        case .orange: return "color_orange"
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(scoreKey): \(score)").font(.caption2)
                Spacer()
                Text("\(levelKey): \(level)").font(.caption2)
            }
            .padding(.horizontal, 6)

            // Target indicator with ring countdown
            ZStack {
                Circle()
                    .fill(target.color.gradient)
                    .frame(width: 70, height: 70)
                    .shadow(color: target.color.opacity(0.5), radius: 6, x: 0, y: 2)
                Circle()
                    .trim(from: 0, to: max(0.01, CGFloat(timeRemaining)))
                    .stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 76, height: 76)
                    .opacity(0.9)
                Text(nameKey(for: target))
                    .font(.caption2).bold()
                    .foregroundStyle(.black.opacity(0.8))
            }
            .padding(.vertical, 4)

            // Color grid for taps (watch-friendly big buttons)
            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                GridRow {
                    ForEach(colors.prefix(2)) { c in
                        ColorButton(color: c, action: { onTapColor(c) })
                    }
                }
                GridRow {
                    ForEach(colors.suffix(from: min(2, colors.count))) { c in
                        ColorButton(color: c, action: { onTapColor(c) })
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 4)
    }
}

private struct ColorButton: View {
    let color: GameColor
    var action: () -> Void
    @State private var pressed: Bool = false

    var body: some View {
        Button {
            pressed = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { pressed = false }
        } label: {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.color)
                .overlay(
                    RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .scaleEffect(pressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pressed)
    }
}

private struct GameOverView: View {
    let score: Int
    let level: Int
    var restartAction: () -> Void
    let gameOverKey: LocalizedStringKey
    let playAgainKey: LocalizedStringKey
    let scoreKey: LocalizedStringKey
    let levelKey: LocalizedStringKey

    var body: some View {
        VStack(spacing: 8) {
            Text(gameOverKey)
                .font(.title3).bold()
            Text("\(scoreKey): \(score) • \(levelKey): \(level)")
                .font(.footnote)
                .opacity(0.8)
            Button(action: restartAction) {
                Text(playAgainKey)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Background
private struct AnimatedDepthBackground: View {
    var phase: CGFloat
    var colors: [Color]

    var body: some View {
        ZStack {
            // Soft radial gradient base
            RadialGradient(colors: [colors.randomElement() ?? .blue, .black], center: .center, startRadius: 5, endRadius: 250)
                .opacity(0.5)
            // Moving layered blobs to suggest 3D depth
            ForEach(0..<4, id: \.self) { i in
                let t = phase + CGFloat(i) * 0.7
                Circle()
                    .fill(colors[safe: i % max(1, colors.count)] ?? .blue)
                    .frame(width: 180, height: 180)
                    .blur(radius: 40)
                    .opacity(0.35)
                    .offset(x: sin(t) * 50, y: cos(t * 0.8) * 40)
                    .blendMode(.plusLighter)
            }
            LinearGradient(colors: [.white.opacity(0.06), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Logic
private extension ContentView {
    enum GameState { case menu, playing, gameOver }

    func startGame() {
        score = 0
        level = 1
        availableColors = GameColor.basic
        estimateBPMIfNeededAndThenStart()
        nextBeat(newLevel: true)
        gameState = .playing
        playTick()
    }

    func restart() {
        gameState = .menu
        stopAudio()
    }

    func startBeatLoop() {
        updateBeatInterval(syncedToBPM: true)
        lastBeatDate = Date()
        timeRemaining = beatInterval
        beatTimer?.invalidate()
        beatTimer = Timer.scheduledTimer(withTimeInterval: beatInterval, repeats: true) { _ in
            nextBeat()
            playTick()
        }
    }

    func stopBeatLoop() { beatTimer?.invalidate(); beatTimer = nil }

    func nextBeat(newLevel: Bool = false) {
        currentTarget = availableColors.randomElement() ?? .red
        lastBeatDate = Date()
        timeRemaining = beatInterval
        if !newLevel { // if called by timer, missing tap ends game
            // No-op here; miss detection is handled by countdown reaching 0 in onReceive
        }
    }

    func handleTap(color: GameColor) {
        guard gameState == .playing else { return }
        if color == currentTarget {
            score += 1
            advanceDifficultyIfNeeded()
            nextBeat()
            playSuccess()
        } else {
            endGame()
            playFail()
        }
    }

    func advanceDifficultyIfNeeded() {
        // Increase level every 5 points, add colors and speed up
        let newLevel = score / 5 + 1
        if newLevel > level {
            level = newLevel
            if availableColors.count < GameColor.all.count {
                availableColors = Array(GameColor.all.prefix(min(GameColor.all.count, 2 + level)))
            }
            updateBeatInterval()
            // Restart timer at new speed
            if gameState == .playing { startBeatLoop() }
        }
    }

    func updateBeatInterval(syncedToBPM: Bool = false) {
        if syncedToBPM {
            // Sync interval to BPM from audio track
            let levelFactor = max(0.75, 1.0 - Double(level - 1) * 0.05)
            beatInterval = max(0.25, (60.0 / bpm) * levelFactor)
        } else {
            // Fallback tempo when no audio or not syncing
            let base: TimeInterval = 1.0
            let speedFactor = max(0.35, 1.0 - Double(level - 1) * 0.1)
            beatInterval = base * speedFactor
        }
    }

    func endGame() {
        gameState = .gameOver
    }
}

// MARK: - Audio (simple ticks)
private extension ContentView {
    func startAudioIfAvailable() {
        // Try to load an audio file named selectedTrack from bundle (m4a or mp3)
        if let url = Bundle.main.url(forResource: selectedTrack, withExtension: "m4a") ?? Bundle.main.url(forResource: selectedTrack, withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                // Optionally derive BPM if known; keep manual bpm otherwise
            } catch {
                audioPlayer = nil
            }
        } else {
            audioPlayer = nil
        }
    }

    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        } catch { }
    }

    func playTick() {
        WKInterfaceDevice.current().play(.click)
        #if canImport(AudioToolbox) && !os(watchOS)
        AudioServicesPlaySystemSound(1104)
        #endif
    }

    func playSuccess() {
        WKInterfaceDevice.current().play(.success)
        #if canImport(AudioToolbox) && !os(watchOS)
        AudioServicesPlaySystemSound(1110)
        #endif
    }

    func playFail() {
        WKInterfaceDevice.current().play(.failure)
        #if canImport(AudioToolbox) && !os(watchOS)
        AudioServicesPlaySystemSound(1107)
        #endif
    }

    func estimateBPMIfNeededAndThenStart() {
        isEstimatingBPM = true
        Task {
            if let url = Bundle.main.url(forResource: selectedTrack, withExtension: "m4a") ?? Bundle.main.url(forResource: selectedTrack, withExtension: "mp3") {
                if let estimated = try? estimateBPM(from: url) {
                    await MainActor.run { self.bpm = estimated }
                }
            }
            await MainActor.run {
                isEstimatingBPM = false
                startAudioIfAvailable()
                if gameState == .playing { updateBeatInterval(syncedToBPM: true); startBeatLoop() }
            }
        }
    }

    func estimateBPM(from url: URL) throws -> Double {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let frameCount = UInt32(min(44100 * 20, Int(file.length))) // analyze up to ~20s
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return bpm }
        try file.read(into: buffer, frameCount: frameCount)
        guard let channelData = buffer.floatChannelData?.pointee else { return bpm }
        let sampleRate = format.sampleRate
        let totalFrames = Int(buffer.frameLength)
        let hop = Int(sampleRate / 200) // 5ms hop ~200Hz
        var envelope: [Float] = []
        envelope.reserveCapacity(totalFrames / hop)
        var i = 0
        while i < totalFrames {
            let end = min(totalFrames, i + hop)
            var sum: Float = 0
            vDSP_meamgv(channelData.advanced(by: i), 1, &sum, vDSP_Length(end - i))
            envelope.append(sum)
            i += hop
        }
        // High-pass like diff to emphasize onsets
        var diff: [Float] = Array(repeating: 0, count: envelope.count)
        vDSP_vsub(Array(envelope.dropFirst()), 1, envelope, 1, &diff[1], 1, vDSP_Length(envelope.count - 1))
        // Peak picking
        let threshold = (diff.max() ?? 0) * 0.6
        var peaks: [Int] = []
        for (idx, v) in diff.enumerated() where v > threshold { peaks.append(idx) }
        if peaks.count < 2 { return bpm }
        // Convert index distances to seconds and compute median interval
        let secondsPerHop = Double(hop) / sampleRate
        var intervals: [Double] = []
        for j in 1..<peaks.count { intervals.append(Double(peaks[j] - peaks[j-1]) * secondsPerHop) }
        intervals.sort()
        let median = intervals[intervals.count/2]
        var estimated = 60.0 / median
        // Normalize to common BPM range 80-160
        while estimated < 80 { estimated *= 2 }
        while estimated > 180 { estimated /= 2 }
        return estimated
    }
}

// MARK: - GameColor
private enum GameColor: String, CaseIterable, Identifiable, Equatable {
    case red, green, blue, yellow, purple, orange

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .red: return .red
        case .green: return .green
        case .blue: return .blue
        case .yellow: return .yellow
        case .purple: return .purple
        case .orange: return .orange
        }
    }

    static var basic: [GameColor] { [.red, .green, .blue, .yellow] }
    static var all: [GameColor] { GameColor.allCases }
}

// MARK: - Safe index helper
private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ContentView()
}

