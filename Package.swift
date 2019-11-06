// swift-tools-version:5.1
// Generated automatically by Perfect Assistant
// Date: 2019-11-01 07:56:33 +0000
import PackageDescription

let package = Package(
	name: "CSServer",
	products: [
		.library(name: "CSServer", targets: ["CSServer"])
	],
	dependencies: [
        .package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", "3.0.23"..<"4.0.0"),
        .package(url: "https://github.com/barimax/CSCoreView.git", .branch("master")),
        .package(url: "https://github.com/iamjono/SwiftMoment.git", "1.2.0"..<"2.0.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-SMTP.git", "4.0.4"..<"4.1.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-Mustache.git", "3.0.2"..<"4.0.0"),
	],
	targets: [
		.target(name: "CSServer", dependencies: ["PerfectHTTPServer", "CSCoreView", "SwiftMoment", "PerfectSMTP", "PerfectMustache"]),
		.testTarget(name: "CSServerTests", dependencies: ["CSServer"])
	]
)
