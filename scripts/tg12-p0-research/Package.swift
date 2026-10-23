// swift-tools-version: 6.0
import PackageDescription

let package = Package(name: "TG12P0", platforms: [.macOS(.v14)], dependencies: [
    .package(path: "../../swift/TacticalGoCore")
], targets: [
    .target(name: "P0Metrics", dependencies: [.product(name: "TacticalGoCore", package: "TacticalGoCore")]),
    .target(name: "P2ResearchBot", dependencies: [.product(name: "TacticalGoCore", package: "TacticalGoCore")]),
    .executableTarget(name: "P0Runner", dependencies: ["P0Metrics", "P2ResearchBot",
        .product(name: "TacticalGoCore", package: "TacticalGoCore"),
        .product(name: "TacticalGoBot", package: "TacticalGoCore"),
        .product(name: "TacticalGoContent", package: "TacticalGoCore"),
        .product(name: "TacticalGoRecords", package: "TacticalGoCore")]),
    .testTarget(name: "P0MetricsTests", dependencies: ["P0Metrics"])
])
