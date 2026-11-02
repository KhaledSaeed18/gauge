import CoreGraphics
import XCTest
@testable import GaugeCore

final class PixelMeasurementTests: XCTestCase {
    private func box(x: CGFloat = 100, y: CGFloat = 50, width: CGFloat, height: CGFloat) -> PixelMeasurement {
        PixelMeasurement(displayID: 1, kind: .box, originPixels: CGPoint(x: x, y: y), sizePixels: CGSize(width: width, height: height))
    }

    private func line(dx: CGFloat, dy: CGFloat) -> PixelMeasurement {
        PixelMeasurement(displayID: 1, kind: .line, originPixels: .zero, sizePixels: CGSize(width: dx, height: dy))
    }

    func testEveryCopyFormat() {
        let measurement = box(width: 320, height: 200)
        XCTAssertEqual(measurement.copyString(format: .dimensions), "320 × 200")
        XCTAssertEqual(measurement.copyString(format: .plain), "320x200")
        XCTAssertEqual(measurement.copyString(format: .withUnits), "320px × 200px")
        XCTAssertEqual(measurement.copyString(format: .css), "width: 320px; height: 200px;")
        XCTAssertEqual(measurement.copyString(format: .withPosition), "320 × 200 @ 100, 50")
    }

    func testFormatExampleMatchesSettingsPreview() {
        XCTAssertEqual(MeasurementFormat.css.example, "width: 320px; height: 200px;")
    }

    func testBoxValuesRoundToWholePixels() {
        let measurement = box(x: 10.4, y: 10.6, width: 99.5, height: 0.4)
        XCTAssertEqual(measurement.widthPixels, 100)
        XCTAssertEqual(measurement.heightPixels, 0)
        XCTAssertEqual(measurement.xPixels, 10)
        XCTAssertEqual(measurement.yPixels, 11)
        XCTAssertEqual(measurement.dimensionLabel, "100 × 0")
    }

    func testReducedRatio() {
        XCTAssertEqual(reducedRatio(width: 320, height: 200), "8:5")
        XCTAssertEqual(reducedRatio(width: 1920, height: 1080), "16:9")
        XCTAssertEqual(reducedRatio(width: 500, height: 500), "1:1")
        XCTAssertEqual(reducedRatio(width: 7, height: 3), "7:3")
    }

    func testReducedRatioOfEmptySideIsDash() {
        XCTAssertEqual(reducedRatio(width: 0, height: 200), "—")
        XCTAssertEqual(reducedRatio(width: 200, height: 0), "—")
    }

    func testLineLengthAndAngle() {
        // 800 right and 400 down: a downward line reads as a negative angle.
        let measurement = line(dx: 800, dy: 400)
        XCTAssertEqual(measurement.lengthPixels, 894)
        XCTAssertEqual(measurement.angleDegrees, -27)
        XCTAssertEqual(measurement.lineLabel, "894 px · -27°")
    }

    func testLineAnglesInEachDirection() {
        XCTAssertEqual(line(dx: 100, dy: 0).angleDegrees, 0)
        XCTAssertEqual(line(dx: 0, dy: -100).angleDegrees, 90)
        XCTAssertEqual(line(dx: 0, dy: 100).angleDegrees, -90)
    }

    func testLineCopiesLengthAndAngleWhateverTheFormat() {
        let measurement = line(dx: 300, dy: -400)
        XCTAssertEqual(measurement.endPixels, CGPoint(x: 300, y: -400))
        for format in MeasurementFormat.allCases {
            XCTAssertEqual(measurement.copyString(format: format), "500 px · 53°")
        }
    }
}
