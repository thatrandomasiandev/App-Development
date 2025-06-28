import SwiftUI
import LaunchAtLogin

struct SettingsView: View {
    @AppStorage("runInBackground") var runInBackground = true
    @AppStorage("icloudSync")      var icloudSync      = false
    @AppStorage("showInMenuBar")   var showInMenuBar   = true
    @AppStorage("soundEffects")    var soundEffects    = true
    @AppStorage("historyDuration") var historyDuration = 7.0
    @AppStorage("globalShortcut")  var globalShortcut  = "⌘⇧V"

    var body: some View {
        Form {
            Section("General") {
                LaunchAtLogin.Toggle("Open at Login")

                Toggle("Run in Background", isOn: $runInBackground)
                    .onChange(of: runInBackground) {
                        NotificationCenter.default.post(
                            name: .runInBackgroundChanged, object: nil
                        )
                    }

                Toggle("Sync to iCloud", isOn: $icloudSync)

                Toggle("Show in Menu Bar", isOn: $showInMenuBar)
                    .onChange(of: showInMenuBar) { 
                        NotificationCenter.default.post(
                            name: .showInMenuBarChanged, object: nil
                        )
                    }

                Toggle("Sound Effects", isOn: $soundEffects)

                HStack {
                    Text("Keep History")
                    Slider(value: $historyDuration, in: 1...365, step: 1) {
                        Text("History Duration")
                    }
                    Text(historyLabel)
                        .frame(width: 80, alignment: .trailing)
                }

                Button("Erase History…") {
                    NotificationCenter.default.post(
                        name: .eraseHistory, object: nil
                    )
                }
            }

            Section("Shortcuts") {
                HStack {
                    Text("Global Shortcut")
                    Spacer()
                    Button(globalShortcut) { }
                        .buttonStyle(.bordered)
                }
                Text("Current: \(globalShortcut)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("About PasteX") {
                Text("""
                PasteX lets you manage your clipboard effortlessly. \
                Customize shortcuts and sync via iCloud.
                """)
                Link("Support: team.pastex@gmail.com",
                     destination: URL(string: "mailto:team.pastex@gmail.com")!)
            }
        }
        .padding()
        .frame(width: 420)
    }

    private var historyLabel: String {
        switch Int(historyDuration) {
        case 1: return "1 day"
        case 2...6: return "\(Int(historyDuration)) days"
        case 7..<30: return "\(Int(historyDuration)) days"
        case 30: return "1 month"
        case 31..<365 where Int(historyDuration) % 30 == 0:
            return "\(Int(historyDuration)/30) months"
        case 365: return "Forever"
        default: return "\(Int(historyDuration)) days"
        }
    }
}

