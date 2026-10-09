// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TacticalGoCore",
    products: [
        .library(name: "TacticalGoCore", targets: ["TacticalGoCore"]),
        .library(name: "TacticalGoRecords", targets: ["TacticalGoRecords"]),
        .library(name: "TacticalGoBot", targets: ["TacticalGoBot"]),
        .library(name: "TacticalGoContent", targets: ["TacticalGoContent"]),
        .library(name: "TacticalGoMotion", targets: ["TacticalGoMotion"]),
        .library(name: "TacticalGoVisuals", targets: ["TacticalGoVisuals"]),
        .executable(name: "tacticalgo-records", targets: ["RecordsRunner"]),
        .executable(name: "tacticalgo-content", targets: ["ContentRunner"]),
        .executable(name: "tacticalgo-golden", targets: ["GoldenRunner"]),
        .executable(name: "tacticalgo-r2", targets: ["R2Runner"]),
        .executable(name: "tacticalgo-bot", targets: ["BotRunner"])
    ],
    targets: [
        .target(name: "TacticalGoCore"),
        .target(name: "TacticalGoRecords", dependencies: ["TacticalGoCore"]),
        .testTarget(name: "TacticalGoRecordsTests", dependencies: ["TacticalGoRecords", "TacticalGoCore"]),
        .target(name: "TacticalGoBot", dependencies: ["TacticalGoCore"]),
        .target(name: "TacticalGoContent", dependencies: ["TacticalGoCore"]),
        .executableTarget(name: "ContentRunner", dependencies: ["TacticalGoContent", "TacticalGoCore"]),
        .testTarget(name: "TacticalGoContentTests", dependencies: ["TacticalGoContent", "TacticalGoCore"]),
        .executableTarget(name: "RecordsRunner", dependencies: ["TacticalGoRecords"]),
        .executableTarget(name: "BotRunner", dependencies: ["TacticalGoBot", "TacticalGoCore"]),
        .testTarget(name: "TacticalGoBotTests", dependencies: ["TacticalGoBot", "TacticalGoCore"], resources: [.copy("Fixtures")]),
        .target(name: "TacticalGoMotion", dependencies: ["TacticalGoCore"]),
        .target(name: "TacticalGoVisuals"),
        .target(name: "TacticalGoGolden", dependencies: ["TacticalGoCore"]),
        .executableTarget(name: "GoldenRunner", dependencies: ["TacticalGoGolden"]),
        .executableTarget(name: "R2Runner", dependencies: ["TacticalGoCore"]),
        .testTarget(name: "TacticalGoCoreTests", dependencies: ["TacticalGoCore", "TacticalGoGolden"]),
        .testTarget(name: "TacticalGoMotionTests", dependencies: ["TacticalGoMotion", "TacticalGoCore"]),
        .testTarget(name: "TacticalGoVisualsTests", dependencies: ["TacticalGoVisuals"])
    ]
)
