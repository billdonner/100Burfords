import SwiftUI

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
        }
    }
}
