import XCTest
@testable import PhotoEditorCore

final class PhotoEditorCoreTests: XCTestCase {
    func testDefaultImageEdits() {
        let edits = ImageEdits()
        XCTAssertEqual(edits.exposure, 0)
        XCTAssertEqual(edits.saturation, 1)
        XCTAssertEqual(edits.contrast, 1)
        XCTAssertEqual(edits.filter, .none)
    }

    func testPhotoFilterDisplayNames() {
        XCTAssertEqual(PhotoFilter.none.displayName, "None")
        XCTAssertEqual(PhotoFilter.noir.displayName, "Noir")
        XCTAssertEqual(PhotoFilter.chrome.displayName, "Chrome")
        XCTAssertEqual(PhotoFilter.sepia.displayName, "Sepia")
        XCTAssertEqual(PhotoFilter.vivid.displayName, "Vivid")
    }
}
