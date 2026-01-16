import SwiftUI

struct ControlPanelView: View {
    enum Difficulty: String, CaseIterable, Identifiable {
        case easy, medium, hard
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .easy: return "Łatwy"
            case .medium: return "Średni"
            case .hard: return "Trudny"
            }
        }
        
        var maxFailures: Int {
            switch self {
            case .easy: return 20
            case .medium: return 10
            case .hard: return 3
            }
        }
        
        var iconName: String {
            switch self {
            case .easy: return "tortoise.fill"
            case .medium: return "speedometer"
            case .hard: return "flame.fill"
            }
        }
        
        var next: Difficulty {
            switch self {
            case .easy: return .medium
            case .medium: return .hard
            case .hard: return .easy
            }
        }
        
        var timeLimitSeconds: Int? {
            switch self {
            case .easy: return 240
            case .medium: return 120
            case .hard: return nil
            }
        }
        
        var cyclesToWin: Int? {
            switch self {
            case .easy, .medium: return nil
            case .hard: return 4
            }
        }
    }

    @State private var difficulty: Difficulty
    @State private var failuresLeft: Int

    let onMinus: () -> Void
    let onPlus: () -> Void
    let onDifficultyChanged: (Difficulty) -> Void

    init(
        initialDifficulty: Difficulty = .hard,
        onMinus: @escaping () -> Void = {},
        onPlus: @escaping () -> Void = {},
        onDifficultyChanged: @escaping (Difficulty) -> Void = { _ in }
    ) {
        self._difficulty = State(initialValue: initialDifficulty)
        self._failuresLeft = State(initialValue: initialDifficulty.maxFailures)
        self.onMinus = onMinus
        self.onPlus = onPlus
        self.onDifficultyChanged = onDifficultyChanged
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Przycisk 1 (np. minus) — bez własnego tła
                Button(action: {
                    onMinus()
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(.primary)
                }

                // Przycisk z plusem — większy, wyróżniony
                Button(action: {
                    onPlus()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .frame(width: 64, height: 64)
                        .foregroundStyle(.primary)
                }

                // Przycisk zmiany poziomu (tap-cykl)
                Button(action: {
                    difficulty = difficulty.next
                    failuresLeft = difficulty.maxFailures
                    onDifficultyChanged(difficulty)
                }) {
                    Image(systemName: difficulty.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .frame(width: 52, height: 52)
                        .foregroundStyle(.primary)
                        .background(.thinMaterial, in: Circle())
                }
            }

            VStack(spacing: 4) {
                Text("Pozostałe próby: \(failuresLeft)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let seconds = difficulty.timeLimitSeconds {
                    Text("Limit czasu: \(seconds / 60) min")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if let cycles = difficulty.cyclesToWin {
                    Text("Warunek: \(cycles) cykle koloru")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 2, x: 0, y: 1)
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.blue.opacity(0.25), .purple.opacity(0.25)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        ControlPanelView(initialDifficulty: .hard) {
            // minus action
        } onPlus: {
            // plus action
        } onDifficultyChanged: { level in
            // handle difficulty change
            _ = level.maxFailures
        }
        .padding()
    }
}
