// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "R3P1Probe", dependencies: [.package(path: "../../../swift/TacticalGoCore")], targets: [
    .executableTarget(name: "R3P1Probe", dependencies: [.product(name: "TacticalGoCore", package: "TacticalGoCore"), .product(name: "TacticalGoBot", package: "TacticalGoCore")], path: "Sources"),
    .executableTarget(name: "FullTurnProbe", dependencies: [.product(name: "TacticalGoCore", package: "TacticalGoCore")], path: "FullTurn")])
