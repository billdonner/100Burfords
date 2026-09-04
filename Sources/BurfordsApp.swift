import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.billdonner.burfords", category: "App")

@main
struct BurfordsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showLaunch = true
    @State private var store = CartoonStore()

    init() {
        // Re-Caption was removed in 1.2; drop any captions saved by earlier builds.
        UserDefaults.standard.removeObject(forKey: "recaptions.v1")
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(store: store)
                if showLaunch {
                    LaunchView(isShowing: $showLaunch, weeksRunning: store.latestWeek)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                logStartup()
                PrintExport.runIfRequested(store: store)
            }
        }
    }

    private func logStartup() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        logger.info("100 Burfords v\(version) (\(build)) launched")
        print("🗞️ 100 Burfords v\(version) (\(build))")
    }
}
