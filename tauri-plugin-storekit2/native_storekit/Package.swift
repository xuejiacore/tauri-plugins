// swift-tools-version: 6.1
// swift/swift-package.swift
import PackageDescription

let package = Package(
    name: "CLibStoreKitBridge",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "CLibStoreKitBridge",
            type: .static,
            targets: ["CLibStoreKitBridge"]),
    ],
    targets: [
        .target(
            name: "CLibStoreKitBridge",
            path: "Sources/CLibStoreKitBridge")
    ]
)
