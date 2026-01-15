import SwiftUI

struct ControlPanelView: View {
    enum Difficulty: String, CaseIterable, Identifiable {
        case easy, medium, hard
        var id: String { rawValue }

        var title: String {
            switch self {
            case .easy: return "Najłatwiejszy"
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
            case .easy: return "tortoise"
            case .medium: return "gauge.medium"
            case .hard: return "flame"
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

                // Zamiast "power" — selektor poziomu trudności
                Menu {
                    ForEach(Difficulty.allCases) { level in
                        Button(action: {
                            difficulty = level
                            failuresLeft = level.maxFailures
                            onDifficultyChanged(level)
                        }) {
                            Label(level.title, systemImage: level.iconName)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "flag.checkered")
                        Text(difficulty.title)
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .frame(height: 44)
                    .padding(.horizontal, 12)
                    .foregroundStyle(.primary)
                }
            }

            // Etykieta statusu z pozostałymi próbami
            Text("Pozostałe próby: \(failuresLeft)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 2, y: 1)
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
