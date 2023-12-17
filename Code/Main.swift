import ArgumentParser
import Foundation

enum Format: String {
	case html
	case json
}

@main
struct Main: ParsableCommand {
	static var configuration = CommandConfiguration(
		abstract: "A utility for diffing two Swift APIs",
		version: "0.1.0"
	)

	@Option(name: .shortAndLong, help: "Path to the older API. Default: /Applications/Xcode.app")
	var old: String = "/Applications/Xcode-14rc.app"

	@Option(name: .shortAndLong, help: "Path to the newer API. Default: /Applications/Xcode-beta.app")
	var new: String = "/Applications/Xcode-15b3.app"

	@Option(name: .long, help: "Path to output results. Default: ~/Desktop/swiftmodule-diff/")
	var output: String = "~/Desktop/swiftmodule-diff/"

	@Option(name: .shortAndLong, help: "Print diff to console. May be combined with --html or --json. Default: true")
	var console: Bool = true

	@Option(name: .shortAndLong, help: "Write html to output directory. May be combined with --json or --console. Default: false.")
	var html: Bool = false

	@Option(name: .shortAndLong, help: "Write json to output directory. May be combined with --html or --console. Default: false")
	var json: Bool = false

	@Option(name: .shortAndLong, help: "Print trace output to console. Default: false")
	var trace: Bool = false

	mutating func run() throws {
		if trace {
			print("Old Xcode: \(old)")
			print("New Xcode: \(new)")
			print("Console Output: \(console)")
			print("HTML: \(html), JSON: \(json)")
			if (html || json) {
				print("Directory: \(output)")
			}
			print("Start: \(Date())")
		}

		let oldFrameworks = Summary.createSummary(for: old, trace: trace)
		let newFrameworks = Summary.createSummary(for: new, trace: trace)

		let fromVersion = Summarizer.Version(majorVersion: 15, minorVersion: 0, patchVersion: 1)
		let toVersion = Summarizer.Version(majorVersion: 15, minorVersion: 1, patchVersion: 0)

		let consoleVisitor = console ? Summarizer.consoleVisitor() : nil
		let signpostVisitor = trace ? Summarizer.signpostVisitor(from: fromVersion, to: toVersion) : nil

		Summarizer(old: oldFrameworks, new: newFrameworks)
			.summarize(
				visitors: consoleVisitor, htmlVisitor, jsonVisitor, signpostVisitor,
				trace: trace
			)

		if trace { print("End: \(Date())") }
	}
}
