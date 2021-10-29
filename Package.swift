// swift-tools-version:5.5
import PackageDescription


let package = Package(
    name: "Sundials",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "Sundials",
            targets: ["Sundials"]
        ),
        .library(
            name: "CSundials",
            targets: ["CSundials"]
        )
    ],
    targets: [
        .target(
            name: "Sundials",
            dependencies: ["CSundials"]
        ),
        .testTarget(
            name: "SundialsTests",
            dependencies: ["Sundials"]
        ),
        .testTarget(
            name: "CSundialsTests",
            dependencies: ["CSundials"]
        ),
        .systemLibrary(
            name: "CSundials",
            pkgConfig: "libsundials",
            providers: [
                .brew(["sundials"]),
                .apt(["libsundials-dev"])
            ]
        )
    ]
)
