import SwiftUI

struct iOSContentView: View {
    @State private var showAudioPicker: Bool = false
    @State private var statusText: String? = nil
    @State private var tracks: [String] = []
    @StateObject private var sync = iOSSyncManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Custom Tracks (Files)") {
                    Button("Add track from Files") {
                        showAudioPicker = true
                    }
                    if tracks.isEmpty {
                        Text("No custom tracks yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(tracks, id: \.self) { name in
                            Text(name)
                        }
                    }
                }

                Section("Sync Status") {
                    HStack {
                        Text("Paired")
                        Spacer()
                        Text(sync.isPaired ? "Yes" : "No")
                    }
                    HStack {
                        Text("Watch app")
                        Spacer()
                        Text(sync.isWatchAppInstalled ? "Installed" : "Not installed")
                    }
                    HStack {
                        Text("Reachable")
                        Spacer()
                        Text(sync.isReachable ? "Yes" : "No")
                    }
                }

                if !sync.transfers.isEmpty {
                    Section("Transfers") {
                        ForEach(sync.transfers) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(item.fileName)
                                    Spacer()
                                    Text(item.state.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                ProgressView(value: item.progress)
                            }
                        }
                    }
                }

                if let statusText {
                    Section("Status") { Text(statusText) }
                }
            }
            .navigationTitle("Music Colours")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            reloadTracks()
        }
        .sheet(isPresented: $showAudioPicker) {
            AudioDocumentPicker { url in
                addTrack(from: url)
                showAudioPicker = false
            }
        }
    }

    private func addTrack(from url: URL) {
        let dst = TrackStore.uniqueTrackURL(for: url)
        do {
            try FileManager.default.copyItem(at: url, to: dst)
            iOSSyncManager.shared.sendTrack(from: dst)
            statusText = "Track sent to Watch."
            reloadTracks()
        } catch {
            statusText = "Failed to import track."
        }
    }

    private func reloadTracks() {
        tracks = TrackStore.importedTrackNames()
    }
}
