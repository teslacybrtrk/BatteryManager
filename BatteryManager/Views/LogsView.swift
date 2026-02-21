import SwiftUI

struct LogsView: View {
    @State private var logText = ""
    @State private var copied = false

    var body: some View {
        VStack(spacing: 6) {
            SectionHeader(title: "Debug Logs")

            ScrollView {
                Text(logText.isEmpty ? "No logs yet." : logText)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(height: 150)
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )

            HStack(spacing: 8) {
                Button {
                    logText = AppLogger.shared.allText()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .font(.system(size: 10))
                }
                .buttonStyle(.bordered)

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(logText, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Copied!" : "Copy All")
                    }
                    .font(.system(size: 10))
                }
                .buttonStyle(.bordered)

                Spacer()

                Button {
                    AppLogger.shared.clear()
                    logText = ""
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Clear")
                    }
                    .font(.system(size: 10))
                }
                .buttonStyle(.bordered)
            }
        }
        .onAppear {
            logText = AppLogger.shared.allText()
        }
    }
}
