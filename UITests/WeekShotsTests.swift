import XCTest

/// Marketing capture for specific weeks. Set WEEKS="1,5,52,66" in the test
/// environment; for each week it shoots the detail view in portrait and the
/// full-screen viewer in landscape. Attachments are named
/// week_NNN_portrait / week_NNN_landscape.
final class WeekShotsTests: XCTestCase {

    func testCaptureWeeks() throws {

        let weeks = (ProcessInfo.processInfo.environment["WEEKS"] ?? "1")
            .split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }

        // SHOT=portrait|landscape shoots only that half and never rotates —
        // used on iPad, where the simulator ignores XCUIDevice orientation
        // and the harness rotates Simulator.app itself between passes.
        let only = ProcessInfo.processInfo.environment["SHOT"]

        for week in weeks {
            let app = XCUIApplication()
            var args = ["--skip-launch", "--open-week", "\(week)"]
            // HIDE_CHROME=1 opens the full-screen viewer bare, for store slides
            // that carry a composed caption instead of the app's title bar.
            if ProcessInfo.processInfo.environment["HIDE_CHROME"] == "1" {
                args.append("--hide-chrome")
            }
            app.launchArguments = args
            app.launch()
            if only == nil { rotate(app, landscape: false) }

            let hint = app.staticTexts["Tap image for full-screen"]
            XCTAssertTrue(hint.waitForExistence(timeout: 8), "detail for week \(week) did not appear")
            sleep(1)
            if only != "landscape" {
                snapshot("week_\(String(format: "%03d", week))_portrait", app: app)
            }

            if only != "portrait" {
                // Full-screen viewer forces landscape on iPhone.
                app.images.firstMatch.tap()
                sleep(2)
                if only == nil { rotate(app, landscape: true) }
                snapshot("week_\(String(format: "%03d", week))_landscape", app: app)
            }

            app.terminate()
        }
    }

    /// The simulator sometimes ignores a single orientation request (it keeps
    /// whatever it was left in), so toggle until the window aspect agrees.
    private func rotate(_ app: XCUIApplication, landscape: Bool) {
        let want: UIDeviceOrientation = landscape ? .landscapeLeft : .portrait
        let nudge: UIDeviceOrientation = landscape ? .portrait : .landscapeRight
        for _ in 0..<4 {
            XCUIDevice.shared.orientation = want
            sleep(1)
            let f = app.windows.firstMatch.frame
            if (f.width > f.height) == landscape { return }
            XCUIDevice.shared.orientation = nudge
            sleep(1)
        }
        XCTFail("could not rotate to \(landscape ? "landscape" : "portrait")")
    }

    private func snapshot(_ name: String, app: XCUIApplication) {
        // `XCUIScreen.main.screenshot()` hands back the device's native PORTRAIT
        // raster plus an `imageOrientation`; attaching that directly exports a
        // landscape shot lying on its side. Preview honors the EXIF tag and looks
        // fine — App Store Connect does not, and publishes it sideways. Redraw
        // through a renderer so the rotation is in the pixels.
        let image = XCUIScreen.main.screenshot().image
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true
        let upright = UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        let att = XCTAttachment(image: upright)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }
}
