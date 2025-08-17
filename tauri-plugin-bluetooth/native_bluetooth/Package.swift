// swift-tools-version: 6.1
// swift/swift-package.swift
import PackageDescription

let package = Package(
    name: "CLibBluKitBridge",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "CLibBluKitBridge",
            type: .static,
            targets: ["CLibBluKitBridge"]),
    ],
    targets: [
        .target(
            name: "CLibBluKitBridge",
            path: "Sources/CLibBluKitBridge")
    ]
)
