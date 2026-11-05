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
            exclude: [
                "Engine/Render/Shader.metal",
                "Resources/DefaultCat/generate_atlas.swift"
            ],
            sources: [
                "App",
                "Engine",
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
