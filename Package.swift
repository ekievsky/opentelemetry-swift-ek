// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let package = Package(
  name: "opentelemetry-swift-ek",
  platforms: [
    .macOS(.v12),
    .iOS(.v13),
  ],
  products: [
    .library(
      name: "OpenTelemetryProtocolExporterHTTP", targets: ["OpenTelemetryProtocolExporterHttp"]
    ),
    .library(name: "OTelSwiftLog", targets: ["OTelSwiftLog"]),
    .library(name: "OpenTelemetryApi-EK", targets: ["OpenTelemetryApi-EK"]),
    .library(name: "OpenTelemetrySdk-EK", targets: ["OpenTelemetrySdk-EK"]),
    .library(name: "StdoutExporter-EK", targets: ["StdoutExporter-EK"]),
  ],
  dependencies: [
    .package(url: "https://github.com/open-telemetry/opentelemetry-swift-core.git", from: "2.1.0"),
    .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.29.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.6.3"),
    .package(url: "https://github.com/apple/swift-metrics.git", from: "2.7.0"),
    .package(url: "https://github.com/mw99/DataCompression", from: "3.9.0")
  ],
  targets: [
    .target(
      name: "OTelSwiftLog",
      dependencies: [
        .product(name: "OpenTelemetryApi", package: "opentelemetry-swift-core"),
        .product(name: "Logging", package: "swift-log")
      ],
      path: "Sources/Bridges/OTelSwiftLog",
      exclude: ["README.md"]
    ),
    .target(
      name: "OpenTelemetryProtocolExporterCommon",
      dependencies: [
        .product(name: "OpenTelemetrySdk", package: "opentelemetry-swift-core"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "SwiftProtobuf", package: "swift-protobuf")
      ],
      path: "Sources/Exporters/OpenTelemetryProtocolCommon"
    ),
    .target(
      name: "OpenTelemetryProtocolExporterHttp",
      dependencies: [
        .product(name: "OpenTelemetrySdk", package: "opentelemetry-swift-core"),
        "OpenTelemetryProtocolExporterCommon",
        .product(
          name: "DataCompression",
          package: "DataCompression",
          condition: .when(platforms: [.macOS, .iOS, .watchOS, .tvOS, .visionOS])
        ),
      ],
      path: "Sources/Exporters/OpenTelemetryProtocolHttp"
    ),
    .target(
        name: "OpenTelemetryApi-EK",
        dependencies: [
            .product(name: "OpenTelemetryApi", package: "opentelemetry-swift-core")
        ]
    ),
    .target(
        name: "OpenTelemetrySdk-EK",
        dependencies: [
            .product(name: "OpenTelemetrySdk", package: "opentelemetry-swift-core"),
            "OpenTelemetryApi-EK"
        ]
    ),
    .target(
        name: "StdoutExporter-EK",
        dependencies: [
            .product(name: "StdoutExporter", package: "opentelemetry-swift-core"),
            "OpenTelemetrySdk-EK"
        ]
    ),
  ]
).addPlatformSpecific()

extension Package {
  func addPlatformSpecific() -> Self {

    #if canImport(Darwin)
      products.append(contentsOf: [
        .library(name: "NetworkStatus", targets: ["NetworkStatus"]),
        .library(name: "URLSessionInstrumentation", targets: ["URLSessionInstrumentation"]),
        .library(name: "ResourceExtension", targets: ["ResourceExtension"]),
      ])
      targets.append(contentsOf: [
        .target(
          name: "NetworkStatus",
          dependencies: [
            .product(name: "OpenTelemetryApi", package: "opentelemetry-swift-core")
          ],
          path: "Sources/Instrumentation/NetworkStatus",
          linkerSettings: [.linkedFramework("CoreTelephony", .when(platforms: [.iOS]))]
        ),
        .target(
          name: "URLSessionInstrumentation",
          dependencies: [
            .product(name: "OpenTelemetrySdk", package: "opentelemetry-swift-core"),
            "NetworkStatus"],
          path: "Sources/Instrumentation/URLSession",
          exclude: ["README.md"]
        ),
        .target(
          name: "ResourceExtension",
          dependencies: [
            .product(name: "OpenTelemetrySdk", package: "opentelemetry-swift-core")
          ],
          path: "Sources/Instrumentation/SDKResourceExtension",
          exclude: ["README.md"]
        ),
      ])
    #endif

    return self
  }
}

if ProcessInfo.processInfo.environment["OTEL_ENABLE_SWIFTLINT"] != nil {
  package.dependencies.append(contentsOf: [
    .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.57.1")
  ])

  for target in package.targets {
    target.plugins = [
      .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
    ]
  }
}
