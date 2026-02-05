import XCTest

final class MusicColoursUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testRecordsPanelOpensAndCloses() {
        let app = XCUIApplication()
        app.launch()

        let playButton = app.buttons["playButton"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 5))
        playButton.tap()

        let toggle = app.buttons["recordsToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.tap()

        let panel = app.otherElements["recordsPanel"]
        XCTAssertTrue(panel.waitForExistence(timeout: 5))

        let backdrop = app.otherElements["recordsBackdrop"]
        XCTAssertTrue(backdrop.waitForExistence(timeout: 5))
        backdrop.tap()

        XCTAssertFalse(panel.waitForExistence(timeout: 2))
    }
}
