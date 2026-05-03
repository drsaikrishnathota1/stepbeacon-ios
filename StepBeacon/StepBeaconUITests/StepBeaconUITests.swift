import XCTest

final class StepBeaconUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCanNavigateCoreTabs() {
        let app = XCUIApplication()
        app.launchArguments = ["APPSTORE_SCREENSHOTS", "STEPBEACON_DEMO"]
        app.launchEnvironment["STEPBEACON_TAB"] = "today"
        app.launch()

        XCTAssertTrue(app.navigationBars["Today"].exists)
        XCTAssertTrue(app.staticTexts["Step goal"].exists)

        app.tabBars.buttons["Trends"].tap()
        XCTAssertTrue(app.navigationBars["Trends"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Snapshot"].exists)

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Daily Goal"].exists)
    }
}
