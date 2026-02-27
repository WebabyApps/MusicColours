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

    private func earShape() -> AnyShape {
        switch kind {
        case .cat, .fox:
            return AnyShape(CatEars())
        case .dog, .bear, .panda, .monkey:
            return AnyShape(DogEars())
        case .rabbit:
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
                    .frame(width: s * 0.68, height: s * 0.48)
                    .overlay(
                        RoundedRectangle(cornerRadius: s * 0.16, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: s * 0.012)
                    )
                    .offset(y: -s * 0.18)

                // Face
                PetFace(kind: kind, blink: blink, whiskerTwitch: whiskerTwitch)
                    .frame(width: s * 0.62, height: s * 0.38)
                    .offset(y: -s * 0.19)

                // Body
                Capsule(style: .continuous)
                    .fill(bodyColor)
                    .frame(width: s * 0.70, height: s * 0.28)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: s * 0.012)
                    )
                    .offset(y: s * 0.22)

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
        if kind == .cat || kind == .rabbit || kind == .mouse || kind == .fox {
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
}

fileprivate struct PetFace: View {
    let kind: RobotPetIconView.Kind
    let blink: Bool
    let whiskerTwitch: Bool

    var body: some View {
        GeometryReader { geo in
            let s: CGFloat = min(geo.size.width, geo.size.height)
            ZStack {
                HStack(spacing: s * 0.22) {
                    RoundedRectangle(cornerRadius: s * 0.12, style: .continuous)
                        .fill(Color.white.opacity(0.92))
                        .frame(width: s * 0.18, height: blink ? s * 0.05 : s * 0.18)
                    RoundedRectangle(cornerRadius: s * 0.12, style: .continuous)
                        .fill(Color.white.opacity(0.92))
                        .frame(width: s * 0.18, height: blink ? s * 0.05 : s * 0.18)
                }
                .offset(y: -s * 0.10)

                if kind == .dog || kind == .bear || kind == .panda || kind == .monkey || kind == .frog || kind == .owl {
                    RoundedRectangle(cornerRadius: s * 0.18, style: .continuous)
                        .fill(Color.white.opacity(0.35))
                        .frame(width: s * 0.58, height: s * 0.30)
                        .offset(y: s * 0.18)

                    Circle()
                        .fill(Color.black.opacity(0.35))
                        .frame(width: s * 0.10, height: s * 0.10)
                        .offset(y: s * 0.12)

                    SmileCurve()
                        .stroke(Color.black.opacity(0.45), style: StrokeStyle(lineWidth: s * 0.05, lineCap: .round))
                        .frame(width: s * 0.65, height: s * 0.40)
                        .offset(y: s * 0.18)
                } else {
                    Triangle()
                        .fill(Color.black.opacity(0.28))
                        .frame(width: s * 0.10, height: s * 0.08)
                        .offset(y: s * 0.12)

                    SmileCurve()
                        .stroke(Color.black.opacity(0.45), style: StrokeStyle(lineWidth: s * 0.05, lineCap: .round))
                        .frame(width: s * 0.60, height: s * 0.38)
                        .offset(y: s * 0.18)

                    Whiskers()
                        .stroke(Color.black.opacity(0.22), style: StrokeStyle(lineWidth: s * 0.03, lineCap: .round))
                        .frame(width: s * 0.95, height: s * 0.50)
                        .rotationEffect(.degrees(whiskerTwitch ? 1.2 : -1.2), anchor: .center)
                        .offset(y: s * 0.12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

fileprivate struct AnyShape: Shape {
    private let pathBuilder: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        pathBuilder = { rect in shape.path(in: rect) }
    }

    func path(in rect: CGRect) -> Path {
        pathBuilder(rect)
    }
}
