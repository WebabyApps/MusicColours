import Foundation
import WatchConnectivity

final class WatchSyncManager: NSObject, WCSessionDelegate {
    static let shared = WatchSyncManager()

    private override init() {
        super.init()
    }

    func start() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }

#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
#endif

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let meta = file.metadata ?? [:]
        let type = (meta["type"] as? String) ?? ""
        if type == "track" {
            let name = (meta["name"] as? String) ?? file.fileURL.deletingPathExtension().lastPathComponent
            let ext = file.fileURL.pathExtension
            let target = TrackStore.uniqueTrackURL(for: file.fileURL.deletingPathExtension().appendingPathExtension(ext))
            do {
                if FileManager.default.fileExists(atPath: target.path) {
                    try FileManager.default.removeItem(at: target)
                }
                try FileManager.default.copyItem(at: file.fileURL, to: target)
                NotificationCenter.default.post(name: .tracksUpdated, object: nil)
            } catch {
                print("[WatchSync] Failed to save track:", error.localizedDescription)
            }
        }
    }
}

extension Notification.Name {
    static let tracksUpdated = Notification.Name("tracksUpdated")
}
