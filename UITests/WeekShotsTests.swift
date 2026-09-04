import XCTest

/// Marketing capture for specific weeks. Set WEEKS="1,5,52,66" in the test
/// environment; for each week it shoots the detail view in portrait and the
/// full-screen viewer in landscape. Attachments are named
/// week_NNN_portrait / week_NNN_landscape.
final class WeekShotsTests: XCTestCase {

    func testCaptureWeeks() throws {
        let weeks = (ProcessInfo.processInfo.environment["WEEKS"] ?? "1")
            .split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }

        for week in weeks {
            let app = XCUIApplication()
            app.launchArguments = ["--skip-launch", "--open-week", "\(week)"]
            XCUIDevice.shared.orientation = .portrait
            app.launch()

            let hint = app.staticTexts["Tap image for full-screen"]
            XCTAssertTrue(hint.waitForExistence(timeout: 8), "detail for week \(week) did not appear")
            sleep(1)
            snapshot("week_\(String(format: "%03d", week))_portrait", app: app)

            // Full-screen viewer forces landscape; rotate the device to match.
            app.images.firstMatch.tap()
            XCUIDevice.shared.orientation = .landscapeLeft
            sleep(2)
            snapshot("week_\(String(format: "%03d", week))_landscape", app: app)

            app.terminate()
        }
    }

    private func snapshot(_ name: String, app: XCUIApplication) {
        let shot = XCUIScreen.main.screenshot()
        let att = XCTAttachment(screenshot: shot)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }
}
