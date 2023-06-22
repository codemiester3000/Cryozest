//
//  Cryozest_Apple_Watch_Watch_AppUITestsLaunchTests.swift
//  Cryozest Apple Watch Watch AppUITests
//
//  Created by Robert Amarin on 6/21/23.
//

import XCTest

final class Cryozest_Apple_Watch_Watch_AppUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
