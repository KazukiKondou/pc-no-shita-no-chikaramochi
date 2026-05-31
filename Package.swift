// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PCNoShitaNoChikaramochi",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "PCNoShitaNoChikaramochi",
            path: "Sources/PCNoShitaNoChikaramochi"
        ),
        .testTarget(
            name: "PCNoShitaNoChikaramochiTests",
            dependencies: ["PCNoShitaNoChikaramochi"],
            path: "Tests/PCNoShitaNoChikaramochiTests"
        )
    ]
)
