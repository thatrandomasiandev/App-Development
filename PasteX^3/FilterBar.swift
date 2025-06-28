import SwiftUI

struct FilterBar: View {
    @Binding var filter: ClipFilter

    var body: some View {
        HStack(spacing: 12) {
            ForEach(ClipFilter.allCases) { f in
                Button {
                    filter = f
                } label: {
                    Image(systemName: f.icon)
                }
                .buttonStyle(.plain)
                .foregroundStyle(filter == f ? .primary : .secondary)
            }
        }
        .padding(.leading, 8)
    }
}


