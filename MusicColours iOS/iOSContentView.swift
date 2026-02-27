import SwiftUI
import PhotosUI

struct iOSContentView: View {
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedAvatar: UIImage? = nil
    @State private var showAudioPicker: Bool = false
    @State private var statusText: String? = nil
    @State private var tracks: [String] = []
    @StateObject private var sync = iOSSyncManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Custom Avatar") {
                    HStack(spacing: 12) {
                        Group {
                            if let selectedAvatar {
                                Image(uiImage: selectedAvatar)
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                Image(systemName: "person.crop.square")
                                    .font(.system(size: 28, weight: .bold))
                            }
                        }
                        .frame(width: 64, height: 64)
                        .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("64x64 required (auto-scaled)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Text("Choose avatar")
                            }
                        }
                    }
                }

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
        .onAppear {
            reloadTracks()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let resized = resizedTo64(image) {
                    selectedAvatar = resized
                    if let data = resized.pngData() {
                        AvatarStore.saveCustomImageData(data)
                    }
                    iOSSyncManager.shared.sendAvatar(image: resized)
                    statusText = "Avatar sent to Watch."
                } else {
                    statusText = "Failed to load image."
                }
            }
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

    private func resizedTo64(_ image: UIImage) -> UIImage? {
        let target = CGSize(width: 64, height: 64)
        if image.size == target { return image }
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
