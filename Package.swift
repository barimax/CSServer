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
	],
	targets: [
		.target(name: "CSServer", dependencies: ["PerfectHTTPServer", "CSCoreView"]),
		.testTarget(name: "CSServerTests", dependencies: ["CSServer"])
	]
)
