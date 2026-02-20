import Foundation

@MainActor @Observable
final class HelperInstaller {
    var isInstalled = false
    var isInstalling = false
    var installError: String?

    private let helperID = "com.batterymanager.helper"
    private let helperDest = "/Library/PrivilegedHelperTools/com.batterymanager.helper"
    private let plistDest = "/Library/LaunchDaemons/com.batterymanager.helper.plist"

    func checkIfInstalled() {
        let connection = NSXPCConnection(machServiceName: helperID, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: SMCHelperProtocol.self)
        connection.resume()

        guard let proxy = connection.remoteObjectProxyWithErrorHandler({ _ in
            DispatchQueue.main.async { [weak self] in
                self?.isInstalled = false
            }
            connection.invalidate()
        }) as? SMCHelperProtocol else {
            isInstalled = false
            connection.invalidate()
            return
        }

        proxy.ping { [weak self] success in
            DispatchQueue.main.async {
                self?.isInstalled = success
            }
            connection.invalidate()
        }

        // Timeout: if no response in 3 seconds, assume not installed
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self = self else { return }
            if !self.isInstalled && !self.isInstalling {
                connection.invalidate()
            }
        }
    }

    func install() {
        guard !isInstalling else { return }
        isInstalling = true
        installError = nil

        guard let helperSource = helperSourcePath(),
              let plistSource = plistSourcePath() else {
            installError = "Could not find helper files in app bundle."
            isInstalling = false
            return
        }

        // Build the shell commands to run with admin privileges
        let commands = [
            "mkdir -p /Library/PrivilegedHelperTools",
            "cp \"\(helperSource)\" \"\(helperDest)\"",
            "chown root:wheel \"\(helperDest)\"",
            "chmod 544 \"\(helperDest)\"",
            "cp \"\(plistSource)\" \"\(plistDest)\"",
            "chown root:wheel \"\(plistDest)\"",
            "chmod 644 \"\(plistDest)\"",
            "launchctl bootout system/\(helperID) 2>/dev/null; true",
            "launchctl bootstrap system \"\(plistDest)\""
        ].joined(separator: " && ")

        let script = "do shell script \"\(commands.replacingOccurrences(of: "\"", with: "\\\""))\" with administrator privileges"

        Task.detached { [weak self] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]

            let pipe = Pipe()
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()

                let status = process.terminationStatus
                let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.isInstalling = false
                    if status == 0 {
                        self.isInstalled = true
                    } else {
                        if errorOutput.contains("User canceled") || errorOutput.contains("-128") {
                            self.installError = "Installation was cancelled."
                        } else {
                            self.installError = "Installation failed: \(errorOutput)"
                        }
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.isInstalling = false
                    self?.installError = "Failed to launch installer: \(error.localizedDescription)"
                }
            }
        }
    }

    private func helperSourcePath() -> String? {
        let bundlePath = Bundle.main.bundlePath
        let helperPath = (bundlePath as NSString).appendingPathComponent("Contents/Helpers/com.batterymanager.helper")
        return FileManager.default.fileExists(atPath: helperPath) ? helperPath : nil
    }

    private func plistSourcePath() -> String? {
        return Bundle.main.path(forResource: "com.batterymanager.helper", ofType: "plist")
    }
}
