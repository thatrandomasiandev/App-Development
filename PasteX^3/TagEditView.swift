import SwiftUI

struct TagEditView: View {
    @EnvironmentObject var monitor: PasteboardMonitor
    @EnvironmentObject var tagManager: TagManager
    let clip: ClipboardItem
    @Binding var isPresented: Bool
    @State private var newTag = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
            
            if clip.tags.isEmpty {
                Text("No tags")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                    ForEach(clip.tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                                .font(.caption)
                            Button {
                                tagManager.removeTag(tag, from: clip)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.blue.opacity(0.2))
                        )
                        .foregroundStyle(.blue)
                    }
                }
            }
            
            HStack {
                TextField("Add tag...", text: $newTag)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        addTagAndMaybeClose()
                    }
                
                Button("Add") {
                    addTagAndMaybeClose()
                }
                .disabled(newTag.isEmpty)
            }
            
            if !tagManager.allTags.isEmpty {
                Text("Popular tags:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(tagManager.allTags.prefix(10)), id: \.self) { tag in
                            Button(tag) {
                                tagManager.addTag(tag, to: clip)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
                Button("Done") { isPresented = false }
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(width: 300)
        .onExitCommand { isPresented = false } // Escape key closes
    }

    private func addTagAndMaybeClose() {
        if !newTag.isEmpty {
            tagManager.addTag(newTag, to: clip)
            newTag = ""
            // Optionally close after adding:
            // isPresented = false
        }
    }
} 
