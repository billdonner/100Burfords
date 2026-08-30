import XCTest

/// Drives the Re-Caption flow end to end and drops screenshots on disk
/// (RECAPTION_SHOT_DIR env var) so the rig can eyeball the result.
final class RecaptionTests: XCTestCase {

    func testRecaptionFlow() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        sleep(3)

        // Navigate into the first cartoon card
        let buttons = app.buttons
        for i in 0..<min(6, buttons.count) {
            let btn = buttons.element(boundBy: i)
            guard btn.exists, btn.isHittable else { continue }
            let label = btn.label
            if label.contains("Read Like a Book") || label.isEmpty || label.contains("info")
                || label.contains("Fan Club") { continue }
            btn.tap()
            if app.staticTexts["Tap image for full-screen"].waitForExistence(timeout: 3) { break }
            app.navigationBars.buttons.element(boundBy: 0).tap()
            sleep(1)
        }

        // Scroll down to the Re-Caption button and open it
        let recaption = app.buttons["Re-Caption This Panel"]
        var tries = 0
        while !(recaption.exists && recaption.isHittable) && tries < 5 {
            app.swipeUp()
            tries += 1
        }
        XCTAssertTrue(recaption.exists, "Re-Caption button not found")
        recaption.tap()
        sleep(1)
        save("recaption_1_empty")

        // Type a caption (multiline TextField surfaces as a text view)
        var field = app.textViews.firstMatch
        if !field.waitForExistence(timeout: 2) { field = app.textFields.firstMatch }
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText("I told you the Upper West Side had gone to the dogs.")
        save("recaption_2_typed")

        // Pick the Marker style and shoot the styled preview
        let marker = app.buttons["Aa, Marker"]
        if marker.exists { marker.tap() } else { app.swipeUp(); app.buttons["Aa, Marker"].tap() }
        sleep(1)
        save("recaption_3_marker")

        // Open the print/share sheet
        let printShare = app.buttons["Print or Share"]
        if !printShare.isHittable { app.swipeUp() }
        printShare.tap()
        sleep(1)
        save("recaption_4_printsheet")

        // Close both sheets, reopen — the caption and style must persist
        app.buttons["Done"].firstMatch.tap()
        sleep(1)
        app.buttons["Done"].firstMatch.tap()
        sleep(1)
        if !recaption.isHittable { app.swipeUp() }
        recaption.tap()
        sleep(1)
        let restored = app.textViews.firstMatch
        XCTAssertTrue(restored.waitForExistence(timeout: 3))
        XCTAssertTrue((restored.value as? String ?? "").contains("gone to the dogs"),
                      "Caption did not persist across sheet reopen")
        save("recaption_5_persisted")
    }

    private func save(_ name: String) {
        let dir = ProcessInfo.processInfo.environment["RECAPTION_SHOT_DIR"] ?? "/tmp/recaption_shots"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let png = XCUIScreen.main.screenshot().pngRepresentation
        do {
            try png.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        } catch {
            NSLog("RECAPTION save failed: \(error)")
        }
    }
}
