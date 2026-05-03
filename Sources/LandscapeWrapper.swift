import SwiftUI
import UIKit

// Presents any SwiftUI view locked to landscape orientation
struct LandscapeWrapper<Content: View>: UIViewControllerRepresentable {
    let content: Content

    func makeUIViewController(context: Context) -> LandscapeHostingController<Content> {
        LandscapeHostingController(rootView: content)
    }

    func updateUIViewController(_ vc: LandscapeHostingController<Content>, context: Context) {
        vc.rootView = content
    }
}

class LandscapeHostingController<Content: View>: UIHostingController<Content> {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var shouldAutorotate: Bool { true }
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.orientationLock = .landscape
        UIViewController.attemptRotationToDeviceOrientation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AppDelegate.orientationLock = .portrait
        // Snap back to portrait
        if let windowScene = view.window?.windowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        }
        UIViewController.attemptRotationToDeviceOrientation()
    }
}
