import Foundation

struct TrackStore {
    static let folderName = "ImportedTracks"

    static func tracksDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent(folderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func importedTrackURLs() -> [URL] {
        let dir = tracksDirectory()
        let urls = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        let exts = Set(["m4a", "mp3"])
        return urls.filter { exts.contains($0.pathExtension.lowercased()) }
    }

    static func importedTrackNames() -> [String] {
        importedTrackURLs().map { $0.deletingPathExtension().lastPathComponent }.sorted()
    }

    static func uniqueTrackURL(for originalURL: URL) -> URL {
        let dir = tracksDirectory()
        let base = originalURL.deletingPathExtension().lastPathComponent
        let ext = originalURL.pathExtension
        var candidate = dir.appendingPathComponent("\(base).\(ext)")
        var counter = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = dir.appendingPathComponent("\(base)_\(counter).\(ext)")
            counter += 1
        }
        return candidate
    }
}
