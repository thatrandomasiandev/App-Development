import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var monitor: PasteboardMonitor
    @State private var searchText = ""
    @State private var filter: ClipFilter = .all
    @State private var selectedClipIndex: Int? = nil
    @FocusState private var isSearchFocused: Bool
    @State private var isSelectionMode = false
    @State private var selectedClips: Set<ClipboardItem> = []
    
    private let columns = [
        GridItem(.adaptive(minimum: 200), spacing: 12)
    ]

    private var filteredClips: [ClipboardItem] {
        monitor.items.filter { clip in
            let matchesSearch = searchText.isEmpty ||
                (clip.text?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (clip.tags.contains { $0.localizedCaseInsensitiveContains(searchText) })

            return filter.matches(clip) && matchesSearch
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // ─── TOP BAR ─────────────────────────────────────
            HStack {
                FilterBar(filter: $filter)
                Spacer()
                
                if isSelectionMode {
                    Button("Select All") {
                        selectedClips = Set(filteredClips)
                    }
                    .buttonStyle(.bordered)
                }
                
                SettingsLink {
                    Image(systemName: "gearshape")
                        .imageScale(.large)
                        .accessibilityLabel("Settings")
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
            }

            // ─── SEARCH FIELD ─────────────────────────────────
            TextField("Search clips…", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .focused($isSearchFocused)
                .onSubmit {
                    if let firstClip = filteredClips.first {
                        monitor.pasteClip(firstClip)
                    }
                }

            // ─── BULK OPERATIONS ──────────────────────────────
            if isSelectionMode {
                BulkOperationsView(
                    selectedClips: $selectedClips,
                    isSelectionMode: $isSelectionMode
                )
            }

            // ─── GRID OF CLIPS ───────────────────────────────
            ScrollView {
                ClipsGridView(
                    filteredClips: filteredClips,
                    selectedClips: $selectedClips,
                    isSelectionMode: $isSelectionMode,
                    selectedClipIndex: $selectedClipIndex,
                    columns: columns
                )
                .environmentObject(monitor)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .padding(8)
        .onAppear {
            // Set focus to search field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFocused = true
            }
        }
        .onKeyPress(.escape) {
            // Close popover on escape
            if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                appDelegate.closePopover()
            }
            return .handled
        }
        .onKeyPress(.upArrow) {
            navigateSelection(direction: .up)
            return .handled
        }
        .onKeyPress(.downArrow) {
            navigateSelection(direction: .down)
            return .handled
        }
        .onKeyPress(.leftArrow) {
            navigateSelection(direction: .left)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            navigateSelection(direction: .right)
            return .handled
        }
        .onKeyPress(.return) {
            if let selectedIndex = selectedClipIndex, selectedIndex < filteredClips.count {
                monitor.pasteClip(filteredClips[selectedIndex])
            }
            return .handled
        }
        .onKeyPress(.space) {
            if let selectedIndex = selectedClipIndex, selectedIndex < filteredClips.count {
                monitor.pasteClip(filteredClips[selectedIndex])
            }
            return .handled
        }
        
    }
    
    private func navigateSelection(direction: NavigationDirection) {
        let clips = filteredClips
        guard !clips.isEmpty else { return }
        
        let currentIndex = selectedClipIndex ?? -1
        let columnsCount = max(1, Int((NSScreen.main?.frame.width ?? 1200) / 220)) // Approximate columns
        
        var newIndex: Int
        
        switch direction {
        case .up:
            newIndex = currentIndex - columnsCount
            if newIndex < 0 {
                newIndex = clips.count - 1
            }
        case .down:
            newIndex = currentIndex + columnsCount
            if newIndex >= clips.count {
                newIndex = 0
            }
        case .left:
            newIndex = currentIndex - 1
            if newIndex < 0 {
                newIndex = clips.count - 1
            }
        case .right:
            newIndex = currentIndex + 1
            if newIndex >= clips.count {
                newIndex = 0
            }
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedClipIndex = newIndex
        }
    }
}

enum NavigationDirection {
    case up, down, left, right
}

struct ClipsGridView: View {
    let filteredClips: [ClipboardItem]
    @Binding var selectedClips: Set<ClipboardItem>
    @Binding var isSelectionMode: Bool
    @Binding var selectedClipIndex: Int?
    let columns: [GridItem]
    @EnvironmentObject var monitor: PasteboardMonitor

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(filteredClips.indices, id: \ .self) { index in
                let clip = filteredClips[index]
                ClipTile(clip: clip)
                    .environmentObject(monitor)
                    .scaleEffect(selectedClipIndex == index ? 1.05 : 1.0)
                    .shadow(radius: selectedClipIndex == index ? 8 : 2)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedClipIndex)
                    .overlay(
                        // Selection checkbox
                        Group {
                            if isSelectionMode {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Image(systemName: selectedClips.contains(clip) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selectedClips.contains(clip) ? .blue : .secondary)
                                            .background(.regularMaterial)
                                            .clipShape(Circle())
                                            .onTapGesture {
                                                if selectedClips.contains(clip) {
                                                    selectedClips.remove(clip)
                                                } else {
                                                    selectedClips.insert(clip)
                                                }
                                            }
                                    }
                                    Spacer()
                                }
                                .padding(8)
                            }
                        }
                    )
                    .contextMenu {
                        Button(clip.isPinned ? "Unpin" : "Pin") {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                monitor.togglePin(clip)
                            }
                        }
                        
                        Button("Copy to Clipboard") {
                            monitor.pasteClip(clip)
                        }
                        
                        if clip.text != nil {
                            Button("Copy as Plain Text") {
                                monitor.pasteClipAsPlainText(clip)
                            }
                        }
                        
                        Divider()
                        
                        Button("Delete", role: .destructive) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                monitor.deleteClip(clip)
                            }
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
        .padding()
    }
}


