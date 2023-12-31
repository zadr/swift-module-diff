import ArgumentParser
import Foundation

@main
struct SwiftmoduleDiff: ParsableCommand {
	static var configuration = CommandConfiguration(
		abstract: "A utility for diffing two Swift APIs",
		version: "0.1.0"
	)

	@Option(name: .shortAndLong, help: "Path to the older API. Default: /Applications/Xcode.app")
	var old: String = "/Applications/Xcode.app"

	@Option(name: .shortAndLong, help: "Path to the newer API. Default: /Applications/Xcode-beta.app")
	var new: String = "/Applications/Xcode-beta.app"

	@Option(name: .long, help: "Path to output results. Default: ~/Desktop/swiftmodule-diff/")
	var output: String = "~/Desktop/swiftmodule-diff/"

	@Option(name: .shortAndLong, help: "Print files to console as they're visited. Default: true")
	var progress: Bool = true

	@Option(name: .shortAndLong, help: "Write html to output directory. May be combined with --json or --console. Default: false.")
	var html: Bool = false

	@Option(name: .shortAndLong, help: "Path to extra CSS to customize output. Will be copied into HTML ouptut dir if --html is passed.")
	var extraCSS: String? = nil

	@Option(name: .shortAndLong, help: "Write json to output directory. May be combined with --html or --console. Default: false")
	var json: Bool = false

	@Option(name: .shortAndLong, help: "Create signposts for performance debugging, and print extra data to console. Default: false")
	var trace: Bool = false

	@Option(name: .shortAndLong, help: "Attempt to remove framework prefixes from type names. Increases runtime, but dramatically reduces the diff size. For example `var isTrue: Swift.Bool` will become `var isTrue: Bool`, and `func with(_ parameter: UIKit.UIView) -> CoreGraphics.CGRect` will become `func with(_ parameter: UIView) -> CGRect`. Not applicable to --single-file. Default: false.")
	var attemptFrameworkPrefixesRemovalFromTypeNames: Bool = true

	@Option(name: .shortAndLong, help: "Parse a single file, for testing. Takes precedence over --old --new")
	var singleFile: String? = nil

	mutating func run() throws {
		if trace { print("Start: \(Date())") }

		if let singleFile {
			if trace { print("Single File: \(singleFile)") }

			print(ParseSwiftmodule(path: singleFile, typePrefixesToRemove: []).run())
		} else {
			if trace {
				print("Old Xcode: \(old)")
				print("New Xcode: \(new)")
				print("Show Progress: \(progress)")
				print("HTML: \(html), JSON: \(json)")
				print("Extra CSS: \(extraCSS ?? "")")
				if (html || json) {
					print("Directory: \(output)")
				}
				print("Start: \(Date())")
			}

			var frameworkNames = Set<String>()
			if attemptFrameworkPrefixesRemovalFromTypeNames {
				frameworkNames.formUnion(Summary.listFrameworks(for: old, progress: progress).filter { !$0.hasSuffix("_") }) // remove _-prefixed frameworks; these are typically Swift overlays that don't add new types
				frameworkNames.formUnion(Summary.listFrameworks(for: new, progress: progress).filter { !$0.hasPrefix("_") }) // and the framework names list is used in O(N^2) logic
			}

			let oldFrameworks = Summary.createSummary(for: old, typePrefixesToRemove: frameworkNames, progress: progress)
			let newFrameworks = Summary.createSummary(for: new, typePrefixesToRemove: frameworkNames, progress: progress)

			let fromVersion = ChangedTree.Version(appPath: old)!
			let toVersion = ChangedTree.Version(appPath: new)!

			let progressVisitor = progress ? ChangedTree.progressVisitor() : nil
			let htmlVisitor = html ? ChangedTree.htmlVisitor(from: fromVersion, to: toVersion, root: output, extraCSS: extraCSS) : nil
			let jsonVisitor = json ? ChangedTree.jsonVisitor(from: fromVersion, to: toVersion, root: output) : nil
			let signpostVisitor = trace ? ChangedTree.signpostVisitor(from: fromVersion, to: toVersion) : nil

			ChangedTree(old: oldFrameworks, new: newFrameworks)
				.walk(
					visitors: progressVisitor, htmlVisitor, jsonVisitor, signpostVisitor,
					trace: trace
				)
		}

		if trace { print("End: \(Date())") }
	}
}
