import CoreGraphics

/// Pure, testable description of a display's pixel geometry.
///
/// Gauge draws in AppKit points but counts in physical pixels; every overlay
/// view also has to reserve the macOS menu-bar strip at the top of a display.
/// That conversion and inset math used to be duplicated across every overlay
/// view. `DisplayGeometry` centralises it in one value type with no AppKit
/// dependency, so it can be unit tested without a real screen.
public struct DisplayGeometry: Equatable {
    /// Backing scale factor (pixels per point). Always positive.
    public let scale: CGFloat
    /// Points reserved at the top of the display for the menu bar. Never negative.
    public let menuBarInset: CGFloat

    public init(scale: CGFloat, menuBarInset: CGFloat) {
        self.scale = scale > 0 ? scale : 1
        self.menuBarInset = max(0, menuBarInset)
    }

    /// Physical pixels for a distance in points, rounded to the nearest pixel.
    public func pixels(fromPoints value: CGFloat) -> Int {
        Int((value * scale).rounded())
    }

    /// Points for a distance in physical pixels.
    public func points(fromPixels value: Int) -> CGFloat {
        CGFloat(value) / scale
    }

    /// The content frame for a full-screen interactive or HUD overlay panel:
    /// the display's frame with the menu-bar strip removed from the top.
    public func overlayFrame(in screenFrame: CGRect) -> CGRect {
        CGRect(
            x: screenFrame.minX,
            y: screenFrame.minY,
            width: screenFrame.width,
            height: screenFrame.height - menuBarInset
        )
    }
}
