import SwiftUI

// MARK: - Robot pet icons
struct RobotPetIconView: View {
    enum Kind: Hashable {
        case cat
        case dog
        case rabbit
        case monkey
        case owl
        case mouse
        case fox
        case lion
        case snake
        case elephant
        case wolf
        case bear
        case panda
        case frog
    }

    let kind: Kind
    var background: Color = .clear
    var animated: Bool = true

    @State private var breathe: Bool = false
    @State private var bob: Bool = false
    @State private var earWiggle: Bool = false
    @State private var blink: Bool = false
    @State private var whiskerTwitch: Bool = false

    private let head = Color(red: 0.49, green: 0.72, blue: 0.95)
    private let bodyColor = Color(red: 0.42, green: 0.64, blue: 0.88)
    private let outline = Color.black.opacity(0.10)

    private var headWidthFactor: CGFloat {
        switch kind {
        case .elephant: return 0.74
        case .frog: return 0.72
        case .snake: return 0.76
        case .owl: return 0.64
        default: return 0.68
        }
    }

    private var headHeightFactor: CGFloat {
        switch kind {
        case .snake: return 0.40
        case .frog, .owl: return 0.50
        default: return 0.48
        }
    }

    private var headYOffsetFactor: CGFloat {
        switch kind {
        case .snake: return -0.10
        case .frog: return -0.15
        default: return -0.18
        }
    }

    private var bodyWidthFactor: CGFloat {
        switch kind {
        case .snake: return 0.82
        case .elephant, .bear, .panda: return 0.74
        case .frog: return 0.66
        default: return 0.70
        }
    }

    private var bodyHeightFactor: CGFloat {
        switch kind {
        case .snake: return 0.18
        case .frog: return 0.24
        default: return 0.28
        }
    }

    private var bodyYOffsetFactor: CGFloat {
        switch kind {
        case .snake: return 0.25
        case .frog: return 0.20
        default: return 0.22
        }
    }

    private func earShape() -> AnyShape {
        switch kind {
        case .cat, .fox, .lion, .wolf:
            return AnyShape(CatEars())
        case .dog, .bear, .panda, .elephant:
            return AnyShape(DogEars())
        case .monkey:
            return AnyShape(RoundEars())
        case .rabbit, .snake:
            return AnyShape(BunnyEars())
        case .mouse:
            return AnyShape(RoundEars())
        case .owl:
            return AnyShape(OwlEars())
        case .frog:
            return AnyShape(FrogEyes())
        }
    }

    var body: some View {
        GeometryReader { geo in
            let s: CGFloat = min(geo.size.width, geo.size.height)
            let earHeight: CGFloat = (kind == .rabbit ? s * 0.70 : s * 0.50)
            let earYOffset: CGFloat = (kind == .rabbit ? -s * 0.30 : -s * 0.20)
            ZStack {
                RoundedRectangle(cornerRadius: s * 0.18, style: .continuous)
                    .fill(background)

                Capsule()
                    .fill(Color.black.opacity(0.12))
                    .frame(width: s * 0.55, height: s * 0.10)
                    .offset(y: s * 0.28)
                    .blur(radius: s * 0.02)

                // Ears / head features
                earShape()
                .fill(bodyColor)
                .frame(width: s * 0.95, height: earHeight)
                .rotationEffect(.degrees(earWiggle ? -2.0 : 2.0), anchor: .bottom)
                .offset(y: earYOffset)
                .shadow(color: outline, radius: s * 0.02, x: 0, y: s * 0.01)

                // Head
                RoundedRectangle(cornerRadius: s * 0.16, style: .continuous)
                    .fill(head)
                    .frame(width: s * headWidthFactor, height: s * headHeightFactor)
                    .overlay(
                        RoundedRectangle(cornerRadius: s * 0.16, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: s * 0.012)
                    )
                    .offset(y: s * headYOffsetFactor)

                speciesAccent(size: s)

                // Face
                PetFace(kind: kind, blink: blink, whiskerTwitch: whiskerTwitch)
                    .frame(width: s * 0.62, height: s * 0.38)
                    .offset(y: s * (headYOffsetFactor - 0.01))

                // Body
                Capsule(style: .continuous)
                    .fill(bodyColor)
                    .frame(width: s * bodyWidthFactor, height: s * bodyHeightFactor)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: s * 0.012)
                    )
                    .offset(y: s * bodyYOffsetFactor)

                Circle().fill(Color.black.opacity(0.10))
                    .frame(width: s * 0.06, height: s * 0.06)
                    .offset(x: -s * 0.36, y: s * 0.23)
                Circle().fill(Color.black.opacity(0.10))
                    .frame(width: s * 0.06, height: s * 0.06)
                    .offset(x: s * 0.36, y: s * 0.23)
            }
            .scaleEffect(animated ? (breathe ? 1.015 : 1.0) : 1.0)
            .offset(y: animated ? (bob ? -s * 0.012 : 0) : 0)
            .onAppear { startIdleAnimations() }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func startIdleAnimations() {
        guard animated else { return }
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            breathe = true
        }
        withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) {
            bob = true
        }
        withAnimation(.easeInOut(duration: 2.9).repeatForever(autoreverses: true)) {
            earWiggle = true
        }
        if kind == .cat || kind == .rabbit || kind == .mouse || kind == .fox || kind == .wolf || kind == .lion {
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                whiskerTwitch = true
            }
        }
        scheduleBlink()
    }

    private func scheduleBlink() {
        let delay = Double.random(in: 1.8...4.2)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: 0.08)) { blink = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeInOut(duration: 0.10)) { blink = false }
                scheduleBlink()
            }
        }
    }

    @ViewBuilder
    private func speciesAccent(size s: CGFloat) -> some View {
        switch kind {
        case .lion:
            Circle()
                .stroke(Color(red: 0.86, green: 0.66, blue: 0.28), lineWidth: s * 0.08)
                .frame(width: s * 0.72, height: s * 0.58)
                .offset(y: -s * 0.18)
        case .fox:
            FoxCheeks()
                .fill(Color.white.opacity(0.56))
                .frame(width: s * 0.54, height: s * 0.22)
                .offset(y: s * 0.01)
        case .wolf:
            WolfCheeks()
                .fill(Color.white.opacity(0.48))
                .frame(width: s * 0.58, height: s * 0.24)
                .offset(y: -s * 0.01)
        case .monkey:
            HStack(spacing: s * 0.34) {
                Circle()
                    .fill(Color(red: 0.84, green: 0.74, blue: 0.62))
                    .frame(width: s * 0.14, height: s * 0.14)
                Circle()
                    .fill(Color(red: 0.84, green: 0.74, blue: 0.62))
                    .frame(width: s * 0.14, height: s * 0.14)
            }
            .offset(y: -s * 0.18)
        case .elephant:
            RoundedRectangle(cornerRadius: s * 0.08, style: .continuous)
                .fill(bodyColor.opacity(0.95))
                .frame(width: s * 0.12, height: s * 0.28)
                .overlay(
                    RoundedRectangle(cornerRadius: s * 0.08, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: s * 0.01)
                )
                .offset(y: -s * 0.01)
        case .owl:
            HStack(spacing: s * 0.12) {
                Circle()
                    .stroke(Color.white.opacity(0.75), lineWidth: s * 0.025)
                    .frame(width: s * 0.15, height: s * 0.15)
                Circle()
                    .stroke(Color.white.opacity(0.75), lineWidth: s * 0.025)
                    .frame(width: s * 0.15, height: s * 0.15)
            }
            .offset(y: -s * 0.12)
        case .frog:
            HStack(spacing: s * 0.24) {
                Circle()
                    .fill(head)
                    .frame(width: s * 0.16, height: s * 0.16)
                Circle()
                    .fill(head)
                    .frame(width: s * 0.16, height: s * 0.16)
            }
            .offset(y: -s * 0.36)
        case .snake:
            Path { path in
                path.move(to: CGPoint(x: s * 0.50, y: s * 0.39))
                path.addQuadCurve(
                    to: CGPoint(x: s * 0.50, y: s * 0.48),
                    control: CGPoint(x: s * 0.47, y: s * 0.45)
                )
                path.move(to: CGPoint(x: s * 0.50, y: s * 0.48))
                path.addLine(to: CGPoint(x: s * 0.46, y: s * 0.53))
                path.move(to: CGPoint(x: s * 0.50, y: s * 0.48))
                path.addLine(to: CGPoint(x: s * 0.54, y: s * 0.53))
            }
            .stroke(Color.red.opacity(0.7), style: StrokeStyle(lineWidth: s * 0.018, lineCap: .round))
        default:
            EmptyView()
        }
    }
}

fileprivate struct PetFace: View {
    let kind: RobotPetIconView.Kind
    let blink: Bool
    let whiskerTwitch: Bool

    var body: some View {
        GeometryReader { geo in
            let s: CGFloat = min(geo.size.width, geo.size.height)
            ZStack {
                HStack(spacing: eyeSpacing(for: s)) {
                    RoundedRectangle(cornerRadius: s * 0.12, style: .continuous)
                        .fill(Color.white.opacity(0.92))
                        .frame(width: eyeWidth(for: s), height: blink ? s * 0.05 : eyeHeight(for: s))
                    RoundedRectangle(cornerRadius: s * 0.12, style: .continuous)
                        .fill(Color.white.opacity(0.92))
                        .frame(width: eyeWidth(for: s), height: blink ? s * 0.05 : eyeHeight(for: s))
                }
                .offset(y: eyeYOffset(for: s))

                if hasMuzzle {
                    RoundedRectangle(cornerRadius: s * 0.18, style: .continuous)
                        .fill(Color.white.opacity(0.35))
                        .frame(width: muzzleWidth(for: s), height: muzzleHeight(for: s))
                        .offset(y: muzzleYOffset(for: s))

                    Circle()
                        .fill(Color.black.opacity(0.35))
                        .frame(width: noseWidth(for: s), height: noseWidth(for: s))
                        .offset(y: noseYOffset(for: s))

                    SmileCurve()
                        .stroke(Color.black.opacity(0.45), style: StrokeStyle(lineWidth: s * 0.05, lineCap: .round))
                        .frame(width: smileWidth(for: s), height: smileHeight(for: s))
                        .offset(y: smileYOffset(for: s))

                    if kind == .owl {
                        Triangle()
                            .fill(Color.orange.opacity(0.82))
                            .frame(width: s * 0.14, height: s * 0.10)
                            .offset(y: s * 0.10)
                    }
                } else {
                    Triangle()
                        .fill(Color.black.opacity(0.28))
                        .frame(width: noseWidth(for: s), height: s * 0.08)
                        .offset(y: noseYOffset(for: s))

                    SmileCurve()
                        .stroke(Color.black.opacity(0.45), style: StrokeStyle(lineWidth: s * 0.05, lineCap: .round))
                        .frame(width: smileWidth(for: s), height: smileHeight(for: s))
                        .offset(y: smileYOffset(for: s))

                    if hasWhiskers {
                        Whiskers()
                            .stroke(Color.black.opacity(0.22), style: StrokeStyle(lineWidth: s * 0.03, lineCap: .round))
                            .frame(width: s * 0.95, height: s * 0.50)
                            .rotationEffect(.degrees(whiskerTwitch ? 1.2 : -1.2), anchor: .center)
                            .offset(y: s * 0.12)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var hasMuzzle: Bool {
        switch kind {
        case .dog, .bear, .panda, .monkey, .frog, .owl, .elephant, .wolf, .lion, .fox:
            return true
        default:
            return false
        }
    }

    private var hasWhiskers: Bool {
        switch kind {
        case .cat, .rabbit, .mouse, .fox, .wolf, .lion:
            return true
        default:
            return false
        }
    }

    private func eyeWidth(for s: CGFloat) -> CGFloat {
        switch kind {
        case .owl, .frog: return s * 0.20
        case .snake: return s * 0.14
        case .fox: return s * 0.15
        case .wolf: return s * 0.16
        default: return s * 0.18
        }
    }

    private func eyeHeight(for s: CGFloat) -> CGFloat {
        switch kind {
        case .owl, .frog: return s * 0.20
        case .snake: return s * 0.10
        case .fox: return s * 0.14
        case .wolf: return s * 0.14
        default: return s * 0.18
        }
    }

    private func eyeSpacing(for s: CGFloat) -> CGFloat {
        switch kind {
        case .elephant: return s * 0.18
        case .owl, .frog: return s * 0.18
        default: return s * 0.22
        }
    }

    private func eyeYOffset(for s: CGFloat) -> CGFloat {
        switch kind {
        case .frog: return -s * 0.22
        case .owl: return -s * 0.14
        case .snake: return -s * 0.04
        default: return -s * 0.10
        }
    }

    private func muzzleWidth(for s: CGFloat) -> CGFloat {
        switch kind {
        case .elephant: return s * 0.40
        case .owl: return s * 0.42
        case .monkey: return s * 0.54
        case .fox: return s * 0.44
        case .wolf: return s * 0.50
        default: return s * 0.58
        }
    }

    private func muzzleHeight(for s: CGFloat) -> CGFloat {
        switch kind {
        case .elephant: return s * 0.34
        case .owl: return s * 0.24
        case .monkey: return s * 0.34
        case .fox: return s * 0.24
        default: return s * 0.30
        }
    }

    private func muzzleYOffset(for s: CGFloat) -> CGFloat {
        switch kind {
        case .owl: return s * 0.14
        case .frog: return s * 0.14
        case .fox: return s * 0.16
        default: return s * 0.18
        }
    }

    private func noseWidth(for s: CGFloat) -> CGFloat {
        switch kind {
        case .elephant: return s * 0.08
        case .owl: return s * 0.12
        case .monkey: return s * 0.11
        case .fox, .wolf: return s * 0.10
        default: return s * 0.10
        }
    }

    private func noseYOffset(for s: CGFloat) -> CGFloat {
        switch kind {
        case .snake: return s * 0.08
        case .owl: return s * 0.11
        default: return s * 0.12
        }
    }

    private func smileWidth(for s: CGFloat) -> CGFloat {
        switch kind {
        case .owl: return s * 0.34
        case .snake: return s * 0.46
        case .fox, .wolf: return s * 0.56
        default: return s * 0.60
        }
    }

    private func smileHeight(for s: CGFloat) -> CGFloat {
        kind == .owl ? s * 0.26 : s * 0.38
    }

    private func smileYOffset(for s: CGFloat) -> CGFloat {
        switch kind {
        case .owl: return s * 0.18
        case .snake: return s * 0.14
        default: return s * 0.18
        }
    }
}

fileprivate struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

fileprivate struct SmileCurve: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.midY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return p
    }
}

fileprivate struct Whiskers: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let y = rect.midY
        p.move(to: CGPoint(x: rect.midX - rect.width * 0.16, y: y))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.06, y: y - rect.height * 0.12))
        p.move(to: CGPoint(x: rect.midX - rect.width * 0.16, y: y))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.06, y: y))
        p.move(to: CGPoint(x: rect.midX - rect.width * 0.16, y: y))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.06, y: y + rect.height * 0.12))
        p.move(to: CGPoint(x: rect.midX + rect.width * 0.16, y: y))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.06, y: y - rect.height * 0.12))
        p.move(to: CGPoint(x: rect.midX + rect.width * 0.16, y: y))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.06, y: y))
        p.move(to: CGPoint(x: rect.midX + rect.width * 0.16, y: y))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.06, y: y + rect.height * 0.12))
        return p
    }
}

fileprivate struct CatEars: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX - rect.width * 0.34, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX - rect.width * 0.22, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX - rect.width * 0.10, y: rect.maxY))
        p.closeSubpath()
        p.move(to: CGPoint(x: rect.midX + rect.width * 0.10, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX + rect.width * 0.22, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX + rect.width * 0.34, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

fileprivate struct DogEars: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let l = CGRect(x: rect.minX, y: rect.minY + rect.height * 0.18, width: rect.width * 0.22, height: rect.height * 0.64)
        p.addRoundedRect(in: l, cornerSize: CGSize(width: l.width * 0.6, height: l.width * 0.6))
        let r = CGRect(x: rect.maxX - rect.width * 0.22, y: rect.minY + rect.height * 0.18, width: rect.width * 0.22, height: rect.height * 0.64)
        p.addRoundedRect(in: r, cornerSize: CGSize(width: r.width * 0.6, height: r.width * 0.6))
        return p
    }
}

fileprivate struct BunnyEars: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let earW = rect.width * 0.18
        let earH = rect.height * 0.80
        let left = CGRect(x: rect.midX - rect.width * 0.26, y: rect.minY, width: earW, height: earH)
        let right = CGRect(x: rect.midX + rect.width * 0.08, y: rect.minY, width: earW, height: earH)
        p.addRoundedRect(in: left, cornerSize: CGSize(width: earW * 0.6, height: earW * 0.6))
        p.addRoundedRect(in: right, cornerSize: CGSize(width: earW * 0.6, height: earW * 0.6))
        return p
    }
}

fileprivate struct RoundEars: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = rect.width * 0.18
        let left = CGRect(x: rect.minX + rect.width * 0.05, y: rect.minY + rect.height * 0.08, width: r * 2, height: r * 2)
        let right = CGRect(x: rect.maxX - rect.width * 0.05 - r * 2, y: rect.minY + rect.height * 0.08, width: r * 2, height: r * 2)
        p.addEllipse(in: left)
        p.addEllipse(in: right)
        return p
    }
}

fileprivate struct OwlEars: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX - rect.width * 0.28, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX - rect.width * 0.06, y: rect.maxY))
        p.closeSubpath()
        p.move(to: CGPoint(x: rect.midX + rect.width * 0.06, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX + rect.width * 0.18, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX + rect.width * 0.28, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

fileprivate struct FrogEyes: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = rect.width * 0.16
        let left = CGRect(x: rect.midX - rect.width * 0.30, y: rect.minY + rect.height * 0.05, width: r * 2, height: r * 2)
        let right = CGRect(x: rect.midX + rect.width * 0.10, y: rect.minY + rect.height * 0.05, width: r * 2, height: r * 2)
        p.addEllipse(in: left)
        p.addEllipse(in: right)
        return p
    }
}

fileprivate struct WolfCheeks: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.midY))
        p.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.maxY + rect.height * 0.10)
        )
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.midY),
            control: CGPoint(x: rect.midX + rect.width * 0.18, y: rect.maxY + rect.height * 0.10)
        )
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.10)
        )
        return p
    }
}

fileprivate struct FoxCheeks: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.midY))
        p.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.12),
            control: CGPoint(x: rect.midX - rect.width * 0.16, y: rect.minY)
        )
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.midY),
            control: CGPoint(x: rect.midX + rect.width * 0.16, y: rect.minY)
        )
        p.closeSubpath()
        return p
    }
}

fileprivate struct AnyShape: Shape {
    private let pathBuilder: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        pathBuilder = { rect in shape.path(in: rect) }
    }

    func path(in rect: CGRect) -> Path {
        pathBuilder(rect)
    }
}
