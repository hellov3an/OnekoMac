// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OnekoMac",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "OnekoMac", targets: ["OnekoMac"])
    ],
    targets: [
        .executableTarget(
            name: "OnekoMac",
            path: ".",
            sources: [
                "App",
                "Engine",
                "Pets",
                "Skins",
                "Utils"
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .unsafeFlags(["-O"])
            ]
        )
    ]
)
