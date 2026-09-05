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
            app.launchArguments = ["--skip-launch", "--open-week", "\(week)"]
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
        let shot = XCUIScreen.main.screenshot()
        let att = XCTAttachment(screenshot: shot)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }
}
