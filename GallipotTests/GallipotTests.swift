import XCTest
@testable import Gallipot

final class GallipotTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: GallipotApp.self), "GallipotApp")
    }
}
