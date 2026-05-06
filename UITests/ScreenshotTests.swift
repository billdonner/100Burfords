import XCTest

final class ScreenshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testCaptureAllScreenshots() throws {
        // 1. Capture launch screen during fade-in
        sleep(UInt32(1))
        snapshot("01_LaunchScreen")

        // 2. Wait for launch animation, capture main grid
        sleep(UInt32(2))
        snapshot("02_MainGrid")

        // 3. Tap the first card — it's a NavigationLink button in the grid
        // Find buttons with actual artwork text in them
        let buttons = app.buttons
        // The first NavigationLink card should be a button containing the week text
        // Try finding by accessibility
        var navigated = false
        for i in 0..<min(5, buttons.count) {
            let btn = buttons.element(boundBy: i)
            if btn.exists && btn.isHittable {
                let label = btn.label
                // Skip Read Like a Book and info buttons
                if label.contains("Read Like a Book") || label == "" || label.contains("info") {
                    continue
                }
                btn.tap()
                sleep(UInt32(1))
                // Check we navigated to detail (look for "Tap image for full-screen" hint)
                let hint = app.staticTexts["Tap image for full-screen"]
                if hint.waitForExistence(timeout: 2) {
                    navigated = true
                    snapshot("03_CartoonDetail")
                    break
                }
                // Not a cartoon card, go back
                app.navigationBars.buttons.element(boundBy: 0).tap()
                sleep(UInt32(1))
            }
        }

        if !navigated {
            // Fallback: tap at the grid's first card position
            // Grid starts below header ~190pt, card centers at ~270pt, left column ~110pt
            // On 430pt wide screen: x=110/430=0.26, y=270/932=0.29
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.26, dy: 0.30)).tap()
            sleep(UInt32(1))
            let hint = app.staticTexts["Tap image for full-screen"]
            if hint.waitForExistence(timeout: 2) {
                navigated = true
                snapshot("03_CartoonDetail")
            }
        }

        // 4. Find and tap comment bubble if we're in detail view
        if navigated {
            let commentBtn = app.buttons.matching(NSPredicate(format: "label BEGINSWITH '\\u2019' OR label CONTAINS 'reader comment'")).firstMatch
            // Look for a button with a number like "44 reader comments — tap to read"
            let allButtons = app.buttons.allElementsBoundByIndex
            var commentTapped = false
            for btn in allButtons {
                if btn.exists && btn.label.contains("reader comment") {
                    btn.tap()
                    sleep(UInt32(1))
                    snapshot("04_Comments")
                    commentTapped = true
                    // Dismiss comments sheet
                    let done = app.navigationBars.buttons["Done"]
                    if done.waitForExistence(timeout: 2) { done.tap() }
                    sleep(UInt32(1))
                    break
                }
            }
            // Go back to main grid
            let backBtn = app.navigationBars.buttons.element(boundBy: 0)
            if backBtn.exists { backBtn.tap() }
            sleep(UInt32(1))
        }

        // 5. Open book mode (landscape)
        let bookButton = app.buttons["Read Like a Book"]
        if bookButton.waitForExistence(timeout: 3) {
            bookButton.tap()
            sleep(UInt32(3))
            snapshot("05_BookLandscapeChrome")
            // Tap to hide chrome
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).tap()
            sleep(UInt32(1))
            snapshot("06_BookLandscapeNoChrome")
        }
    }

    func snapshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
