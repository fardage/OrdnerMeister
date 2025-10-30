//
//  DomainPropertyTests.swift
//  OrdnerMeisterTests
//
//  Created by Marvin Tseng on 04.01.2024.
//

import Combine
@testable import OrdnerMeister
@testable import OrdnerMeisterPresentation
import XCTest

final class DomainPropertyTests: XCTestCase {
    func testSubscribing() {
        let initialValue = UUID()
        let newValue = UUID()
        let subject = CurrentValueSubject<UUID, Never>(initialValue)

        let property = subject.domainProperty()

        var receivedValues = [UUID]()

        let cancelable = property.sink {
            receivedValues.append($0)
        }

        subject.value = newValue

        XCTAssertEqual(property.currentValue, newValue)

        cancelable.cancel()

        subject.value = UUID()

        XCTAssertEqual(receivedValues, [initialValue, newValue])
    }
}
