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
        ),
        .library(
            name: "COpenMPI",
            targets: ["COpenMPI"]
        )        
    ],
    targets: [
        .target(
            name: "Sundials",
            dependencies: ["CSundials", "COpenMPI"]
        ),
        .testTarget(
            name: "SundialsTests",
            dependencies: ["Sundials"]
        ),
        .testTarget(
            name: "CSundialsTests",
            dependencies: ["CSundials", "COpenMPI"]
        ),
        .systemLibrary(
            name: "CSundials",
            pkgConfig: "libsundials",
            providers: [
                .brew(["sundials"]),
                .apt(["libsundials-dev"])
            ]
        ),
        .systemLibrary(
            name: "COpenMPI",
            pkgConfig: "ompi",
            providers: [
                .brew(["open-mpi"]),
                .apt(["libopenmpi-dev"])
            ]
        )
    ]
)
