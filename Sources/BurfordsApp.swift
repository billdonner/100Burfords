import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.billdonner.burfords", category: "App")

@main
struct BurfordsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showLaunch = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                if showLaunch {
                    LaunchView(isShowing: $showLaunch)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear { logStartup() }
        }
    }

    private func logStartup() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        logger.info("100 Burfords v\(version) (\(build)) launched")
        print("🗞️ 100 Burfords v\(version) (\(build))")
    }
}
