//
//  ComponentScreenshotTests.swift
//  moobbyUITests
//

import XCTest

/// Opens every Components demo, shows its main state, and screenshots it for the DocC catalog.
///
/// Screenshots are attached to the test report. Set `TEST_RUNNER_SCREENSHOT_DIR` to also write them
/// as PNGs; the README shows the full command.
@MainActor
final class ComponentScreenshotTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    func testCaptureAllComponents() {
        capture("Alert", as: "alert") { $0.buttons["Simple Alert"].tap() }
        capture("Action Sheet", as: "action-sheet") { $0.buttons["Show Options"].tap() }
        capture("Context Menu", as: "context-menu") {
            $0.staticTexts["Sunset Over the Bay"].press(forDuration: 1.2)
        }
        capture("Face ID", as: "face-id")
        capture("Keyboard", as: "keyboard") { $0.textFields.firstMatch.tap() }
        capture("List", as: "list") { $0.staticTexts["Design onboarding flow"].swipeLeft() }
        capture("Menus", as: "menus") { $0.buttons["Sort By"].tap() }
        capture("Picker", as: "picker")
        capture("Sheets", as: "sheets") { $0.buttons["Medium Detent Sheet"].tap() }
        capture("Slider", as: "slider")
        capture("Stepper", as: "stepper")
        capture("Tab Bar", as: "tab-bar")
        capture("Text Fields", as: "text-fields") {
            $0.textFields.firstMatch.tap()
            $0.typeText("ab")
        }
        capture("Toolbars — Bottom", as: "bottom-toolbar")
        capture("Toolbars — Top", as: "top-toolbar")
    }

    /// Relaunches the app, opens the demo titled `title`, runs `action`, and saves `component-<name>`.
    private func capture(_ title: String, as name: String, action: (XCUIApplication) -> Void = { _ in }) {
        let app = XCUIApplication()
        app.launch()
        allowLocationIfAsked()

        app.tabBars.buttons["Components"].tap()
        let row = app.buttons[title]
        // Rows below the fold aren't created until scrolled to.
        _ = app.buttons["Alert"].waitForExistence(timeout: 5)
        for _ in 0..<3 where !(row.exists && row.isHittable) { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 5), "No gallery row titled \(title)")
        row.tap()

        action(app)
        // Let presentation animations settle so the shot isn't mid-transition.
        Thread.sleep(forTimeInterval: 1.5)

        let png = XCUIScreen.main.screenshot().pngRepresentation
        let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
        attachment.name = "component-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)

        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            // @3x so DocC shows the shot at point size; it matches the iPhone simulators we capture on.
            let url = URL(fileURLWithPath: dir).appendingPathComponent("component-\(name)@3x.png")
            XCTAssertNoThrow(try png.write(to: url))
        }
    }

    // The Map tab opens first and may ask for location; answer it so it doesn't cover the screenshot.
    private func allowLocationIfAsked() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Allow While Using App"]
        if allow.waitForExistence(timeout: 2) { allow.tap() }
    }
}
