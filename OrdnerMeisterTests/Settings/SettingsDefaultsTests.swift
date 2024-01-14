//
//  SettingsDefaultsTests.swift
//  OrdnerMeisterTests
//
//  Created by Marvin Tseng on 14.01.2024.
//

@testable import OrdnerMeister
import XCTest

final class SettingsDefaultsTests: XCTestCase {
    func testInboxDirectory() {
        let defaults = UserDefaults(suiteName: "testDefaults")!
        var settings = SettingsDefaults(defaults: defaults)

        let expectedDirectory = "/path/to/inbox"
        settings.inboxDirectory = expectedDirectory

        let actualDirectory = settings.inboxDirectory

        XCTAssertEqual(actualDirectory, expectedDirectory)
    }

    func testOutputDirectory() {
        let defaults = UserDefaults(suiteName: "testDefaults")!
        var settings = SettingsDefaults(defaults: defaults)

        let expectedDirectory = "/path/to/output"
        settings.outputDirectory = expectedDirectory

        let actualDirectory = settings.outputDirectory

        XCTAssertEqual(actualDirectory, expectedDirectory)
    }
}
