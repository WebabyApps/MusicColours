import SwiftUI

enum RobotAvatarStyle {
    case bot
    case cat
    case dog
}

struct RobotAvatarView: View {
    let style: RobotAvatarStyle
    var animated: Bool = true

    @State private var blink: Bool = false
    @State private var wobble: Bool = false

    var body: some View {
        ZStack {
            // Shadow
            Ellipse()
                .fill(Color.black.opacity(0.25))
                .frame(width: 52, height: 10)
                .offset(y: 26)

            // Antenna
            VStack(spacing: 0) {
                Rectangle()
                    .fill(antennaColor)
                    .frame(width: 2, height: 12)
                Circle()
                    .fill(antennaBallColor)
                    .frame(width: 8, height: 8)
            }
            .offset(y: -32)

            // Head + body group with wobble
            VStack(spacing: 1) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(headColor)
                        .frame(width: 52, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(outlineColor.opacity(0.35), lineWidth: 1)
                        )

                    // Ears
                    earLeft
                        .offset(x: -32, y: 0)
                    earRight
                        .offset(x: 32, y: 0)

                    // Eyes + lids
                    HStack(spacing: 10) {
                        eye
                        eye
                    }
                    .offset(y: -2)

                    // Smile
                    MouthShape()
                        .stroke(smileColor, lineWidth: 2)
                        .frame(width: 24, height: 10)
                        .offset(y: 10)
                }

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(outlineColor.opacity(0.35))
                    .frame(width: 20, height: 4)
                    .offset(y: 1)

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(bodyColor)
                    .frame(width: 44, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(outlineColor.opacity(0.35), lineWidth: 1)
                    )
            }
            .rotationEffect(.degrees(animated ? (wobble ? 2.5 : -2.5) : 0))
            .animation(animated ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true) : .default, value: wobble)
        }
        .onAppear {
            guard animated else { return }
            wobble = true
            scheduleBlink()
        }
    }

    private func scheduleBlink() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.12)) { blink = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeInOut(duration: 0.12)) { blink = false }
                scheduleBlink()
            }
        }
    }

    private var eye: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(eyeColor)
                .frame(width: 10, height: 10)
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(headColor)
                .frame(width: 10, height: 10)
                .scaleEffect(x: 1.0, y: blink ? 1.0 : 0.05, anchor: .center)
        }
    }

    @ViewBuilder
    private var earLeft: some View {
        switch style {
        case .cat:
            Triangle()
                .fill(earColor)
                .frame(width: 10, height: 10)
        case .dog:
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(earColor)
                .frame(width: 8, height: 16)
        default:
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(earColor)
                .frame(width: 6, height: 16)
        }
    }

    private var earRight: some View {
        earLeft
    }

    private var headColor: Color {
        switch style {
        case .cat: return Color(hex: 0x8EC5FF)
        case .dog: return Color(hex: 0xA7D7C5)
        default: return Color(hex: 0x9CB3FF)
        }
    }

    private var bodyColor: Color {
        switch style {
        case .cat: return Color(hex: 0x6FA8DC)
        case .dog: return Color(hex: 0x7FB69A)
        default: return Color(hex: 0x7D8DFF)
        }
    }

    private var outlineColor: Color { .black.opacity(0.4) }
    private var eyeColor: Color { .white }
    private var smileColor: Color { Color.black.opacity(0.6) }
    private var earColor: Color { bodyColor }
    private var antennaColor: Color { outlineColor }
    private var antennaBallColor: Color { Color(hex: 0xFFD166) }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

private struct MouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let start = CGPoint(x: rect.minX, y: rect.midY)
        let end = CGPoint(x: rect.maxX, y: rect.midY)
        p.move(to: start)
        p.addCurve(to: end,
                   control1: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.maxY),
                   control2: CGPoint(x: rect.minX + rect.width * 0.75, y: rect.maxY))
        return p
    }
}

private extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b, opacity: alpha)
    }
}

#Preview {
    VStack(spacing: 12) {
        RobotAvatarView(style: .bot)
        RobotAvatarView(style: .cat)
        RobotAvatarView(style: .dog)
    }
    .padding()
    .background(Color.black.opacity(0.8))
}
