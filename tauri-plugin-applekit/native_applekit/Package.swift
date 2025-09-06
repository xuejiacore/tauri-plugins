// swift-tools-version: 6.1
// swift/swift-package.swift
import PackageDescription

let package = Package(
    name: "CLibAppleKitBridge",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "CLibAppleKitBridge",
            type: .static,
            targets: ["CLibAppleKitBridge"]),
    ],
    targets: [
        .target(
            name: "CLibAppleKitBridge",
            path: "Sources/CLibAppleKitBridge")
    ]
)
