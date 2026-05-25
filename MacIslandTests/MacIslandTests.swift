import XCTest

final class MacIslandTests: XCTestCase {
    func testSurfacedItemInit() {
        let item = SurfacedItem(type: .calendar, message: "Standup in 5 mins", urgency: .high, source: "calendar")
        XCTAssertEqual(item.urgency, .high)
        XCTAssertEqual(item.type, .calendar)
    }

    func testKeychainStoreAndRetrieve() {
        KeychainHelper.store(key: "test_key", value: "test_value")
        XCTAssertEqual(KeychainHelper.retrieve(key: "test_key"), "test_value")
        KeychainHelper.delete(key: "test_key")
        XCTAssertNil(KeychainHelper.retrieve(key: "test_key"))
    }
}
