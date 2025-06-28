import SwiftUI
import SwiftData
import LaunchAtLogin

struct PreferencesView: View {
    enum Pane: String, CaseIterable, Identifiable {
        case general      = "General"
        case shortcuts    = "Shortcuts"
        case pasteCards   = "Paste Cards"
        case aboutUs      = "About Us"
        case support      = "Support Us"
        case help         = "Help"

        var id: Self { self }
        var icon: String {
            switch self {
            case .general:    return "gearshape"
            case .shortcuts:  return "command"
            case .pasteCards: return "rectangle.grid.2x2"
            case .aboutUs:    return "info.circle"
            case .support:    return "heart.fill"
            case .help:       return "questionmark.circle"
            }
        }
    }

    @State private var selection: Pane? = .general

    var body: some View {
        NavigationSplitView {
            List(Pane.allCases, selection: $selection) { pane in
                Label(pane.rawValue, systemImage: pane.icon)
                    .padding(.vertical, 4)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 150)
        } detail: {
            HStack {
                Spacer()
                detailView
                    .frame(maxWidth: 500, alignment: .topLeading)
                Spacer()
            }
            .padding(20)
        }
        .frame(minWidth: 650, minHeight: 450)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .general:    GeneralPane()
        case .shortcuts:  ShortcutsPane()
        case .pasteCards: PasteCardsPane()
        case .aboutUs:    AboutUsPane()
        case .support:    SupportUsPane()
        case .help:       HelpPane()
        default:          Text("Select a pane")
        }
    }
}

// MARK: – GeneralPane

struct GeneralPane: View {
    @AppStorage("openAtLogin")     var openAtLogin     = false
    @AppStorage("runInBackground") var runInBackground = true
    @AppStorage("icloudSync")      var icloudSync      = false
    @AppStorage("showInMenuBar")   var showInMenuBar   = true
    @AppStorage("soundEffects")    var soundEffects    = true
    @AppStorage("plainText")       var plainTextPaste  = false
    @AppStorage("historyDuration") var historyDuration = 7.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    LaunchAtLogin.Toggle("Open at login")

                    Toggle("Run in background", isOn: $runInBackground)
                        .onChange(of: runInBackground) {
                            NotificationCenter.default.post(
                                name: .runInBackgroundChanged,
                                object: nil
                            )
                        }

                    Toggle("iCloud sync", isOn: $icloudSync)

                    Toggle("Show in menu bar", isOn: $showInMenuBar)
                        .onChange(of: showInMenuBar) { 
                            NotificationCenter.default.post(
                                name: .showInMenuBarChanged,
                                object: nil
                            )
                        }

                    Toggle("Sound effects", isOn: $soundEffects)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Paste Items").font(.headline)
                    Picker("", selection: $plainTextPaste) {
                        Text("To active app").tag(false)
                        Text("To clipboard").tag(true)
                    }
                    .pickerStyle(.radioGroup)
                    Toggle("Always paste as Plain Text", isOn: $plainTextPaste)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Keep History").font(.headline)
                    HStack {
                        Text("Day")
                        Slider(value: $historyDuration, in: 1...365, step: 1)
                        Text("Forever")
                    }
                    Button("Erase History…") {
                        NotificationCenter.default.post(
                            name: .eraseHistory,
                            object: nil
                        )
                    }
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(8)
            }
        }
    }
}

// MARK: – ShortcutsPane

struct ShortcutsPane: View {
    @State private var pasteShortcut = "⌘⇧V"
    @State private var stackShortcut = "⌃⌘C"
    @State private var nextShortcut  = "⌘→"
    @State private var prevShortcut  = "⌘←"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Group {
                    Text("General Shortcuts").font(.headline)
                    ShortcutRow(name: "Activate Paste", shortcut: $pasteShortcut)
                    ShortcutRow(name: "Activate Paste Stack", shortcut: $stackShortcut)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(8)

                Group {
                    Text("Navigation").font(.headline)
                    ShortcutRow(name: "Next Clip", shortcut: $nextShortcut)
                    ShortcutRow(name: "Previous Clip", shortcut: $prevShortcut)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(8)

                Button("Reset shortcuts to default…") { }
                    .padding(.top, 20)
            }
        }
    }
}

private struct ShortcutRow: View {
    let name: String
    @Binding var shortcut: String

    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.secondary.opacity(0.2))
                )
            Button { shortcut = "" } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: – PasteCardsPane

struct PasteCardsPane: View {
    @Query(sort: [SortDescriptor<ClipboardItem>(\.date, order: .reverse)])
    var clips: [ClipboardItem]

    private let columns = [ GridItem(.adaptive(minimum: 200), spacing: 12) ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(clips) { clip in
                    ClipCardView(clip: clip)
                        .frame(minHeight: 120)
                }
            }
            .padding()
        }
    }
}

// MARK: – AboutUsPane

struct AboutUsPane: View {
    var body: some View {
        Text("""
        PasteX is an app that allows you to manage your clipboard effortlessly and seamlessly. Did you forget where you copied something from? Don’t worry! PasteX shows where you copied any section of text from any application. Didn’t your mom tell you to never settle for less? Well that’s what I thought when I added the functionality to also copy images! Don’t like the default shortcuts, suit yourself. You can make your own. We’ll deal with it. Also are you one of those people that is enslaved to a iCloud subscription? We can help you make the most out of that by adding the ability to sync your clipboard to iCloud. Scared your intrusive wife might find out about your browsing history(wink-wink)? You can also erase your clipboard history.
        
        """)
        .padding()
    }
}

// MARK: – SupportUsPane

struct SupportUsPane: View {
    var body: some View {
        Text("""
        PasteX will always remain free. But, if you like what we are doing, a donation would be greatly appreciated. But, if you don’t want to donate, no hard feelings. We understand. Just don’t tell anyone we said that! But, even telling people about us would help us out a lot. Also, with any amount donated, 5% will go to the Epilepsy Foundation. Thanks!
        """)
        .padding()
    }
}

// MARK: – HelpPane

struct HelpPane: View {
    var body: some View {
        Text("If you need somebody to assist with your mid-life crisis, do not feel free to reach out to us @team.pastex@gmail.com")
            .padding()
    }
}

