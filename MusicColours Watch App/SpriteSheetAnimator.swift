import SwiftUI
import Combine
#if os(watchOS) || os(iOS)
import UIKit
#endif

struct SpriteSheetAnimationView: View {
    let sheetName: String
    let jsonName: String
    let subdirectory: String

    @State private var meta: SpriteSheetMeta? = nil
    @State private var sheetImage: UIImage? = nil
    @State private var sheetCG: CGImage? = nil
    @State private var frames: [SpriteFrame] = []
    @State private var frameIndex: Int = 0
    @State private var frameCache: [Int: CGImage] = [:]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                if let meta, let sheetImage {
                    let total = max(1, frames.count)
                    let frame = frames.isEmpty ? SpriteFrame(x: 0, y: 0, w: meta.frameSize.w, h: meta.frameSize.h) : frames[frameIndex % total]
                    let frameW = CGFloat(frame.w)
                    let frameH = CGFloat(frame.h)

                    if let cg = croppedFrame(index: frameIndex, frame: frame) {
                        Image(decorative: cg, scale: 1.0, orientation: .up)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: frameW, height: frameH)
                            .scaleEffect(size / max(frameW, frameH))
                    } else {
                        Image(uiImage: sheetImage)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: frameW, height: frameH)
                            .scaleEffect(size / max(frameW, frameH))
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear { loadAssetsIfNeeded() }
        .onReceive(timer) { _ in
            guard let meta else { return }
            let total = max(1, frames.count)
            if total > 1 {
                frameIndex = (frameIndex + 1) % total
            } else {
                frameIndex = 0
            }
        }
        .animation(nil, value: frameIndex)
    }

    private var timer: Publishers.Autoconnect<Timer.TimerPublisher> {
        let fps = Double(meta?.fps ?? 8)
        return Timer.publish(every: 1.0 / max(1.0, fps), on: .main, in: .common).autoconnect()
    }

    private func croppedFrame(index: Int, frame: SpriteFrame) -> CGImage? {
        if let cached = frameCache[index] { return cached }
        guard let cg = sheetCG else { return nil }
        let rect = CGRect(x: frame.x, y: frame.y, width: frame.w, height: frame.h)
        guard let crop = cg.cropping(to: rect) else { return nil }
        frameCache[index] = crop
        return crop
    }

    private func loadAssetsIfNeeded() {
        if meta != nil, sheetImage != nil, sheetCG != nil { return }
        if meta == nil, let url = resourceURL(name: jsonName, ext: "json") {
            if let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode(SpriteSheetFile.self, from: data) {
                meta = decoded.meta
                frames = decoded.frames.sortedFrameList()
            }
        }
        if sheetImage == nil {
            if let asset = UIImage(named: sheetName) {
                sheetImage = asset
                sheetCG = asset.cgImage
            } else if let imageURL = resourceURL(name: sheetName, ext: "png") {
                let img = UIImage(contentsOfFile: imageURL.path)
                sheetImage = img
                sheetCG = img?.cgImage
            }
        }
        if sheetCG == nil {
            sheetCG = sheetImage?.cgImage
        }
        if !frames.isEmpty, frameCache.isEmpty {
            frameCache = [:]
        }
    }

    private func resourceURL(name: String, ext: String) -> URL? {
        // Try declared subdirectory first.
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
            return url
        }
        // Try flattened resource path.
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return url
        }
        // Try treating subdirectory as part of the resource name.
        let combined = "\(subdirectory)/\(name)"
        return Bundle.main.url(forResource: combined, withExtension: ext)
    }
}

struct SpriteSheetFile: Decodable {
    let meta: SpriteSheetMeta
    let frames: [String: SpriteSheetFrameEntry]
}

struct SpriteSheetMeta: Decodable {
    let rows: Int
    let columns: Int
    let fps: Int
    let frameCount: Int
    let frameSize: SpriteSheetSize
    let size: SpriteSheetSize
}

struct SpriteSheetSize: Decodable {
    let w: Int
    let h: Int
}

struct SpriteSheetFrameEntry: Decodable {
    let frame: SpriteFrame
}

struct SpriteFrame: Decodable {
    let x: Int
    let y: Int
    let w: Int
    let h: Int
}

private extension Dictionary where Key == String, Value == SpriteSheetFrameEntry {
    func sortedFrameList() -> [SpriteFrame] {
        let sortedKeys = keys.sorted { a, b in
            let na = Int(a.split(separator: "_").last ?? "") ?? 0
            let nb = Int(b.split(separator: "_").last ?? "") ?? 0
            if na != nb { return na < nb }
            return a < b
        }
        return sortedKeys.compactMap { self[$0]?.frame }
    }
}
