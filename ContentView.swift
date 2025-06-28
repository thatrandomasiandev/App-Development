import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var monitor: PasteboardMonitor
    @State private var searchText = ""
    @State private var filter: ClipFilter = .all

    private let columns = [
        GridItem(.adaptive(minimum: 200), spacing: 12)
    ]

    private var filteredClips: [ClipboardItem] {
        monitor.items.filter { clip in
            let matchesSearch = searchText.isEmpty ||
                (clip.text?.localizedCaseInsensitiveContains(searchText) ?? false)

            switch filter {
            case .all:
                return matchesSearch
            case .text:
                return matchesSearch && clip.imageData == nil
            case .images:
                return matchesSearch && clip.imageData != nil
            case .snippets:
                return matchesSearch && clip.isPinned
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // ─── TOP BAR ─────────────────────────────────────
            HStack {
                FilterBar(filter: $filter)
                Spacer()
                SettingsLink {
                    Image(systemName: "gearshape")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
            }

            // ─── SEARCH FIELD ─────────────────────────────────
            TextField("Search clips…", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            // ─── GRID OF CLIPS ───────────────────────────────
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filteredClips, id: \.id) { clip in
                        ClipTile(clip: clip)
                            .environmentObject(monitor)
                            .contextMenu {
                                Button(clip.isPinned ? "Unpin" : "Pin") {
                                    withAnimation {
                                        monitor.togglePin(clip)
                                    }
                                }
                                Button("Delete", role: .destructive) {
                                    withAnimation {
                                        monitor.deleteClip(clip)
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                .padding()
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .padding(8)
    }
}

