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
		if trace { print("Start: \(Date())") }

		let oldFrameworks = Summary.createSummary(for: old, trace: trace)
		let newFrameworks = Summary.createSummary(for: new, trace: trace)

		let consoleVisitor = console ? nil : Summarizer.consoleVisitor()

		Summarizer(old: oldFrameworks, new: newFrameworks)
			.summarize(
				consoleVisitor: consoleVisitor,
				htmlVisitor: nil,
				jsonVisitor: nil,
				trace: trace
			)

		if trace { print("End: \(Date())") }
	}
}
