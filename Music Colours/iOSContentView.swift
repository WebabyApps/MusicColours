import SwiftUI

struct iOSContentView: View {
    private enum RootTab { case game, library }

    @State private var selectedTab: RootTab = .game
    @State private var showTabBar: Bool = true

    var body: some View {
        TabView(selection: $selectedTab) {
            PhoneGameView(showTabBar: $showTabBar)
                .tabItem {
                    Image(systemName: "gamecontroller.fill")
                    Text("Game")
                }
                .tag(RootTab.game)

            LibraryView()
                .tabItem {
                    Image(systemName: "tray.full.fill")
                    Text("Library")
                }
                .tag(RootTab.library)
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == .library {
                showTabBar = true
            }
        }
    }
}

private struct PhoneGameView: View {
    @Binding var showTabBar: Bool

    var body: some View {
        GeometryReader { proxy in
            ContentView(onTabBarVisibilityChange: { visible in
                showTabBar = visible
            })
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(Color.black)
        }
        .ignoresSafeArea()
        .toolbar(showTabBar ? .visible : .hidden, for: .tabBar)
    }
}

private struct LibraryView: View {
    @State private var showAudioPicker: Bool = false
    @State private var statusText: String? = nil
    @State private var tracks: [String] = []
    @AppStorage("premiumUnlocked") private var premiumUnlocked: Bool = false
    @StateObject private var sync = iOSSyncManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Custom Tracks (Files)") {
                    Button("Add track from Files") {
                        showAudioPicker = true
                    }
                    .disabled(!premiumUnlocked)
                    if !premiumUnlocked {
                        Text("Unlock Premium on iPhone or Apple Watch to add tracks.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
