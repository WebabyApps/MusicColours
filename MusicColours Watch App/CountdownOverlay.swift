import SwiftUI
import WatchKit

public struct CountdownOverlay: View {
    @Binding private var isPresented: Bool
    private let onCompleted: () -> Void

    @State private var current: Int = 3
    @State private var showGo: Bool = false
    @State private var tickTask: Task<Void, Never>? = nil

    public init(isPresented: Binding<Bool>, onCompleted: @escaping () -> Void) {
        self._isPresented = isPresented
        self.onCompleted = onCompleted
    }

    public var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .transition(.opacity)

                Group {
                    if showGo {
                        Text("GO!")
                            .font(.system(size: 64, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                            .id("go")
                    } else {
                        Text("\(current)")
                            .font(.system(size: 64, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                            .id(current)
                    }
                }
                .padding()
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isPresented)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showGo)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: current)
        .onChange(of: isPresented) { newValue in
            if newValue {
                startCountdown()
            } else {
                cancelCountdown()
            }
        }
        .onDisappear { cancelCountdown() }
    }

    private func startCountdown() {
        cancelCountdown()
        current = 3
        showGo = false

        tickTask = Task {
            // 3, 2, 1
            for n in stride(from: 3, through: 1, by: -1) {
                if Task.isCancelled { return }
                await MainActor.run {
                    current = n
                    WKInterfaceDevice.current().play(.click)
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }

            if Task.isCancelled { return }
            await MainActor.run {
                showGo = true
                WKInterfaceDevice.current().play(.start)
            }

            // short pause for "GO!"
            try? await Task.sleep(nanoseconds: 400_000_000)

            if Task.isCancelled { return }
            await MainActor.run {
                // Close overlay and call completion
                isPresented = false
                onCompleted()
                // Reset for future uses
                current = 3
                showGo = false
            }
        }
    }

    private func cancelCountdown() {
        tickTask?.cancel()
        tickTask = nil
        current = 3
        showGo = false
    }
}

// MARK: - Preview
#Preview("Countdown demo") {
    CountdownDemoPreview()
}

private struct CountdownDemoPreview: View {
    @State private var show = false
    @State private var message = ""

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Text(message.isEmpty ? "Press Start" : message)
                    .font(.headline)
                Button("Start") { show = true }
                    .buttonStyle(.borderedProminent)
            }

            CountdownOverlay(isPresented: $show) {
                message = "Game started!"
            }
        }
    }
}
