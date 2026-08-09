import XCTest
@testable import GaugeCore

final class DisplayGeometryTests: XCTestCase {
    func testPixelsFromPointsAtRetina() {
        let geometry = DisplayGeometry(scale: 2, menuBarInset: 0)
        XCTAssertEqual(geometry.pixels(fromPoints: 100), 200)
        XCTAssertEqual(geometry.pixels(fromPoints: 0), 0)
        XCTAssertEqual(geometry.pixels(fromPoints: 12.5), 25)
    }

    func testPixelsFromPointsAtNonRetina() {
        let geometry = DisplayGeometry(scale: 1, menuBarInset: 0)
        XCTAssertEqual(geometry.pixels(fromPoints: 100), 100)
        XCTAssertEqual(geometry.pixels(fromPoints: 0.5), 1) // rounds to nearest, away from zero
    }

    func testPointsFromPixels() {
        let geometry = DisplayGeometry(scale: 2, menuBarInset: 0)
        XCTAssertEqual(geometry.points(fromPixels: 200), 100)
        XCTAssertEqual(geometry.points(fromPixels: 1), 0.5)
    }

    func testRoundTripForPixelAlignedPoints() {
        let geometry = DisplayGeometry(scale: 2, menuBarInset: 0)
        for pixels in [0, 1, 37, 200, 1999] {
            XCTAssertEqual(geometry.pixels(fromPoints: geometry.points(fromPixels: pixels)), pixels)
        }
    }

    func testScaleIsClampedToPositive() {
        XCTAssertEqual(DisplayGeometry(scale: 0, menuBarInset: 0).scale, 1)
        XCTAssertEqual(DisplayGeometry(scale: -2, menuBarInset: 0).scale, 1)
    }

    func testMenuBarInsetIsClampedToNonNegative() {
        XCTAssertEqual(DisplayGeometry(scale: 2, menuBarInset: -10).menuBarInset, 0)
        XCTAssertEqual(DisplayGeometry(scale: 2, menuBarInset: 24).menuBarInset, 24)
    }

    func testOverlayFrameRemovesMenuBarFromTop() {
        let geometry = DisplayGeometry(scale: 2, menuBarInset: 24)
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let frame = geometry.overlayFrame(in: screen)
        XCTAssertEqual(frame.minX, 0)
        XCTAssertEqual(frame.minY, 0)
        XCTAssertEqual(frame.width, 1440)
        XCTAssertEqual(frame.height, 876)
    }

    func testOverlayFramePreservesOrigin() {
        let geometry = DisplayGeometry(scale: 2, menuBarInset: 0)
        let screen = CGRect(x: -1440, y: 120, width: 1440, height: 900)
        let frame = geometry.overlayFrame(in: screen)
        XCTAssertEqual(frame.origin, CGPoint(x: -1440, y: 120))
        XCTAssertEqual(frame.height, 900)
    }
}
