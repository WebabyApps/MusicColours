import Foundation
import WatchConnectivity
import UIKit

@MainActor
final class iOSSyncManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = iOSSyncManager()

    struct TransferItem: Identifiable, Equatable {
        enum Kind: String { case avatar, track }
        enum State: String { case pending, inProgress, finished, failed }

        let id: UUID
        let fileName: String
        let kind: Kind
        var progress: Double
        var state: State
    }

    @Published var isPaired: Bool = false
    @Published var isWatchAppInstalled: Bool = false
    @Published var isReachable: Bool = false
    @Published var activationState: WCSessionActivationState = .notActivated
    @Published var transfers: [TransferItem] = []
    @Published var lastError: String? = nil

    private var observations: [ObjectIdentifier: NSKeyValueObservation] = [:]
    private var transferIds: [ObjectIdentifier: UUID] = [:]

    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            refreshStatus(session)
        }
    }

    func sendAvatar(image: UIImage) {
        guard WCSession.isSupported(), WCSession.default.isPaired, WCSession.default.isWatchAppInstalled else {
            lastError = "Watch not available."
            return
        }
        guard let data = image.pngData() else { return }
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("custom_avatar.png")
        try? data.write(to: tmp, options: .atomic)
        let transfer = WCSession.default.transferFile(tmp, metadata: ["type": "avatar"])
        registerTransfer(transfer, fileName: "custom_avatar.png", kind: .avatar)
    }

    func sendTrack(from url: URL) {
        guard WCSession.isSupported(), WCSession.default.isPaired, WCSession.default.isWatchAppInstalled else {
            lastError = "Watch not available."
            return
        }
        let ext = url.pathExtension.isEmpty ? "m4a" : url.pathExtension
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent(url.deletingPathExtension().lastPathComponent)
            .appendingPathExtension(ext)
        try? FileManager.default.copyItem(at: url, to: temp)
        let transfer = WCSession.default.transferFile(
            temp,
            metadata: ["type": "track", "name": url.deletingPathExtension().lastPathComponent]
        )
        registerTransfer(transfer, fileName: temp.lastPathComponent, kind: .track)
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        refreshStatus(session)
        if let error { lastError = error.localizedDescription }
    }

    func sessionDidBecomeInactive(_ session: WCSession) { }

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        refreshStatus(session)
    }

    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        let key = ObjectIdentifier(fileTransfer)
        guard let id = transferIds[key],
              let idx = transfers.firstIndex(where: { $0.id == id }) else { return }
        if let error {
            transfers[idx].state = .failed
            transfers[idx].progress = 0
            lastError = error.localizedDescription
        } else {
            transfers[idx].state = .finished
            transfers[idx].progress = 1
        }
        observations[key] = nil
        transferIds[key] = nil
    }

    // MARK: - Helpers
    private func refreshStatus(_ session: WCSession = .default) {
        isPaired = session.isPaired
        isWatchAppInstalled = session.isWatchAppInstalled
        isReachable = session.isReachable
        activationState = session.activationState
    }

    private func registerTransfer(_ transfer: WCSessionFileTransfer, fileName: String, kind: TransferItem.Kind) {
        let id = UUID()
        let item = TransferItem(id: id, fileName: fileName, kind: kind, progress: 0, state: .pending)
        transfers.insert(item, at: 0)

        let key = ObjectIdentifier(transfer)
        transferIds[key] = id
        let obs = transfer.progress.observe(\.fractionCompleted, options: [.new]) { [weak self] progress, _ in
            Task { @MainActor in
                guard let self else { return }
                guard let idx = self.transfers.firstIndex(where: { $0.id == id }) else { return }
                self.transfers[idx].progress = progress.fractionCompleted
                self.transfers[idx].state = progress.fractionCompleted >= 1 ? .finished : .inProgress
            }
        }
        observations[key] = obs
    }
}
