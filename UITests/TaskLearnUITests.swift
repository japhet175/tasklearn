import XCTest

/// Utilise l'app comme un utilisateur : ajouter, cocher, supprimer, puis relancer
/// pour vérifier que les données sont bien enregistrées dans SQLite.
@MainActor
final class TaskLearnUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testAddToggleDeleteAndRelaunch() throws {
        let app = XCUIApplication()
        app.launch()

        let field = app.textFields["New task"]
        XCTAssertTrue(field.waitForExistence(timeout: 15))
        snapshot("1-empty")

        for title in ["Buy milk", "Prepare interview", "Call the bank"] {
            field.tap()
            field.typeText(title + "\n")
            XCTAssertTrue(app.buttons[title].waitForExistence(timeout: 5))
        }
        snapshot("2-added")

        let milk = app.buttons["Buy milk"]
        milk.tap()
        wait(for: milk, toHave: "value == 'Done'")
        snapshot("3-done")

        let bank = app.buttons["Call the bank"]
        bank.swipeLeft()
        app.buttons["Delete"].tap()
        wait(for: bank, toHave: "exists == false")
        snapshot("4-deleted")

        // Relancer : les tâches viennent de la base SQLite sur le disque.
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["Buy milk"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.buttons["Buy milk"].value as? String, "Done")
        XCTAssertTrue(app.buttons["Prepare interview"].exists)
        XCTAssertFalse(app.buttons["Call the bank"].exists)
        snapshot("5-after-relaunch")
    }

    private func wait(for element: XCUIElement, toHave format: String) {
        let condition = expectation(for: NSPredicate(format: format), evaluatedWith: element)
        wait(for: [condition], timeout: 5)
    }

    /// Joint la capture au rapport de test, et l'écrit aussi dans SCREENSHOTS_DIR si défini (CI).
    private func snapshot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        if let dir = ProcessInfo.processInfo.environment["SCREENSHOTS_DIR"] {
            let url = URL(fileURLWithPath: dir).appendingPathComponent("\(name).png")
            try? screenshot.pngRepresentation.write(to: url)
        }
    }
}
