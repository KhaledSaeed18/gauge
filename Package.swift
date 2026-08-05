// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Gauge",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Gauge", targets: ["Gauge"])],
    targets: [
        .executableTarget(
            name: "Gauge",
            path: "Sources/Gauge",
            linkerSettings: [.linkedFramework("Carbon"), .linkedFramework("ServiceManagement")]
        )
    ]
)
