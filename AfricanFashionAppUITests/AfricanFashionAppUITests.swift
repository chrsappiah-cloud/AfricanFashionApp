//
//  AfricanFashionAppUITests.swift
//  AfricanFashionAppUITests
//
//  Created by Christopher Appiah-Thompson  on 23/4/2026.
//

import XCTest

final class AfricanFashionAppUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testOnboardingTabsAndUploadStudioRouting() throws {
        let app = XCUIApplication()
        app.launchEnvironment["AFRICANFASHION_API_BASE_URL"] = "https://africanfashion-api.chrsappiah.workers.dev"
        app.launch()

        completeOnboardingIfNeeded(app)

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.tabBars.buttons["Studio"].exists)
        XCTAssertTrue(app.tabBars.buttons["Catalog"].exists)
        XCTAssertTrue(app.tabBars.buttons["Cart"].exists)
        XCTAssertTrue(app.tabBars.buttons["Saved"].exists)
        XCTAssertTrue(app.tabBars.buttons["Profile"].exists)

        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.buttons["Upload studio"].waitForExistence(timeout: 8))
        app.buttons["Upload studio"].tap()

        XCTAssertTrue(app.navigationBars["Upload Studio"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Check backend + middleware now"].exists)
        XCTAssertTrue(app.buttons["Probe upload endpoint"].exists)
    }

    @MainActor
    func testAuthValidationShowsErrorForMissingCredentials() throws {
        let app = XCUIApplication()
        app.launchEnvironment["AFRICANFASHION_API_BASE_URL"] = "https://africanfashion-api.chrsappiah.workers.dev"
        app.launch()

        completeOnboardingIfNeeded(app)

        app.tabBars.buttons["Profile"].tap()
        let signInButton = app.buttons["Sign in"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 8))
        signInButton.tap()

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 8))
        continueButton.tap()

        XCTAssertTrue(app.staticTexts["Enter email and password."].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDesignStudioWorkflow() throws {
        for section in ["generate", "trends", "board"] {
            let app = launchStudio(section: section)
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))

            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "studio-\(section)-launch"
            screenshot.lifetime = .keepAlways
            add(screenshot)

            app.terminate()
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    private func completeOnboardingIfNeeded(_ app: XCUIApplication) {
        let enterAtelier = app.buttons["Enter the atelier"]
        if enterAtelier.waitForExistence(timeout: 3) {
            enterAtelier.tap()
        }
    }

    private func launchStudio(section: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["AFRICANFASHION_API_BASE_URL"] = "https://africanfashion-api.chrsappiah.workers.dev"
        app.launchArguments += [
            "-uiTestingCompleteOnboarding",
            "-uiTestingOpenStudio",
            "-uiTestingStudioSection",
            section
        ]
        app.launch()
        return app
    }
}
