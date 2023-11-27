import Foundation

typealias Summary = [SwiftmoduleFinder.Platform: [SwiftmoduleFinder.Architecture: Set<Framework>]]

extension Summary {
	static func createSummary(for path: String, trace: Bool) -> Summary {
		let modules = SwiftmoduleFinder(app: path).run()

		var results = Summary()
		for (platform, architectureToModules) in modules {
			if trace { print(platform) }

			var platformSDKs = [SwiftmoduleFinder.Architecture: Set<Framework>]()
			for (architecture, moduleList) in architectureToModules {
				if trace { print(architecture) }

				var architectureFrameworks = Set<Framework>()
				for i in 0 ..< moduleList.count {
					let module = moduleList[i]
					if trace { print(module.absoluteString) }

					let path = module.absoluteString.replacingOccurrences(of: "file://", with: "")
					var framework = ParseSwiftmodule(path: path).run()
					framework.name = (
						(
							(
								module.absoluteString as NSString
							).deletingLastPathComponent as NSString
						).lastPathComponent as NSString
					).deletingPathExtension

					architectureFrameworks.insert(framework)
				}

				if !architectureFrameworks.isEmpty {
					platformSDKs[architecture] = architectureFrameworks
				}
			}

			if !platformSDKs.isEmpty {
				results[platform] = platformSDKs
			}
		}

		return results
	}
}

struct Summarizer {
	let old: Summary
	let new: Summary

	init(old: Summary, new: Summary) {
		self.old = old
		self.new = new
	}

	func summarize(consoleVisitor: ChangeVisitor? = nil, htmlVisitor: ChangeVisitor? = nil, jsonVisitor: ChangeVisitor? = nil, trace: Bool) {
		precondition(consoleVisitor != nil || htmlVisitor != nil || jsonVisitor != nil)

		let visitors = [consoleVisitor, htmlVisitor, jsonVisitor].compactMap { $0 }

		enumeratePlatformDifferences(visitor: ChangeVisitor { platform in
			visitors.forEach { v in v.willVisitPlatform?(platform) }
		} didVisitPlatform: { platform in
			visitors.forEach { v in v.didVisitPlatform?(platform) }
		} willVisitArchitecture: { architecture in
			visitors.forEach { v in v.willVisitArchitecture?(architecture) }
		} didVisitArchitecture: { architecture in
			visitors.forEach { v in v.didVisitArchitecture?(architecture) }
		} willVisitFramework: { framework in
			visitors.forEach { v in v.willVisitFramework?(framework) }
		} didVisitFramework: { framework in
			visitors.forEach { v in v.didVisitFramework?(framework) }
		} willVisitImport: { dependency in
			visitors.forEach { v in v.willVisitImport?(dependency) }
		} didVisitImport: { dependency in
			visitors.forEach { v in v.didVisitImport?(dependency) }
		} willVisitDataType: { namedType in
			visitors.forEach { v in v.willVisitDataType?(namedType) }
		} didVisitDataType: { namedType in
			visitors.forEach { v in v.didVisitDataType?(namedType) }
		} willVisitMember: { member in
			visitors.forEach { v in v.willVisitMember?(member) }
		} didVisitMember: { member in
			visitors.forEach { v in v.didVisitMember?(member) }
		})
	}
}

extension Summarizer {
	internal struct ChangeVisitor {
		var willVisitPlatform: ((Change<SwiftmoduleFinder.Platform>) -> Void)? = nil
		var didVisitPlatform: ((Change<SwiftmoduleFinder.Platform>) -> Void)? = nil

		var willVisitArchitecture: ((Change<SwiftmoduleFinder.Architecture>) -> Void)? = nil
		var didVisitArchitecture: ((Change<SwiftmoduleFinder.Architecture>) -> Void)? = nil

		var willVisitFramework: ((Change<Framework>) -> Void)? = nil
		var didVisitFramework: ((Change<Framework>) -> Void)? = nil

		var willVisitImport: ((Change<Import>) -> Void)? = nil
		var didVisitImport: ((Change<Import>) -> Void)? = nil

		var willVisitDataType: ((Change<NamedType>) -> Void)? = nil
		var didVisitDataType: ((Change<NamedType>) -> Void)? = nil

		var willVisitMember: ((Change<Member>) -> Void)? = nil
		var didVisitMember: ((Change<Member>) -> Void)? = nil
	}

	internal static func ifNotUnchanged<T>(change: Change<T>, perform: () -> Void) {
		if case .unchanged(_, _) = change {
			return
		}
		perform()
	}

	fileprivate func enumeratePlatformDifferences(visitor: ChangeVisitor) {
		for platformChange in Change<SwiftmoduleFinder.Platform>.differences(from: old.keys, to: new.keys) {
			visitor.willVisitPlatform?(platformChange)
			switch platformChange {
			case .added(_, let new):
				enumerateArchitectureDifferences(for: new, visitor: visitor)
			case .removed(_, _):
				break
			case .modified(let old, _):
				enumerateArchitectureDifferences(for: old, visitor: visitor)
			case .unchanged(let old, _):
				enumerateArchitectureDifferences(for: old, visitor: visitor)
			}
			visitor.didVisitPlatform?(platformChange)
		}
	}

	fileprivate func enumerateArchitectureDifferences(for platform: SwiftmoduleFinder.Platform, visitor: ChangeVisitor) {
		let oldArchs = (old[platform] ?? [:]).keys
		let newArchs = (new[platform] ?? [:]).keys

		for architectureChange in Change<Framework>.differences(from: oldArchs, to: newArchs) {
			visitor.willVisitArchitecture?(architectureChange)
			switch architectureChange {
			case .added(_, let new):
				enumerateFrameworkDifferences(for: platform, architecture: new, visitor: visitor)
			case .removed(_, _):
				break
			case .modified(let old, _):
				enumerateFrameworkDifferences(for: platform, architecture: old, visitor: visitor)
			case .unchanged(let old, _):
				enumerateFrameworkDifferences(for: platform, architecture: old, visitor: visitor)
			}
			visitor.didVisitArchitecture?(architectureChange)
		}
	}

	fileprivate func enumerateFrameworkDifferences(for platform: SwiftmoduleFinder.Platform, architecture: SwiftmoduleFinder.Architecture, visitor: ChangeVisitor) {
		let oldFrameworks = old[platform]![architecture] ?? .init()
		let newFrameworks = new[platform]![architecture] ?? .init()

		for frameworkChange in Change<Framework>.differences(from: oldFrameworks, to: newFrameworks) {
			visitor.willVisitFramework?(frameworkChange)
			switch frameworkChange {
			case .added(_, let new):
				enumerateDependencyDifferences(for: platform, architecture: architecture, framework: new, visitor: visitor)
				enumerateMemberDifferences(for: platform, architecture: architecture, framework: new, visitor: visitor)
				enumerateNamedTypeDifferences(for: platform, architecture: architecture, framework: new, visitor: visitor)
			case .removed(_, _):
				break
			case .modified(let old, _):
				enumerateDependencyDifferences(for: platform, architecture: architecture, framework: old, visitor: visitor)
				enumerateMemberDifferences(for: platform, architecture: architecture, framework: old, visitor: visitor)
				enumerateNamedTypeDifferences(for: platform, architecture: architecture, framework: old, visitor: visitor)
			case .unchanged(let old, _):
				enumerateDependencyDifferences(for: platform, architecture: architecture, framework: old, visitor: visitor)
				enumerateMemberDifferences(for: platform, architecture: architecture, framework: old, visitor: visitor)
				enumerateNamedTypeDifferences(for: platform, architecture: architecture, framework: old, visitor: visitor)
			}
			visitor.didVisitFramework?(frameworkChange)
		}
	}

	fileprivate func enumerateDependencyDifferences(for platform: SwiftmoduleFinder.Platform, architecture: SwiftmoduleFinder.Architecture, framework: Framework, visitor: ChangeVisitor) {
		let oldDependencies = (old[platform]![architecture] ?? .init()).first { $0.name == framework.name }?.dependencies ?? []
		let newDependencies = (new[platform]![architecture] ?? .init()).first { $0.name == framework.name }?.dependencies ?? []

		for dependencyChange in Change<Framework>.differences(from: oldDependencies, to: newDependencies) {
			visitor.willVisitImport?(dependencyChange)
			// ..anything to do?
			visitor.didVisitImport?(dependencyChange)
		}
	}

	fileprivate func enumerateMemberDifferences(for platform: SwiftmoduleFinder.Platform, architecture: SwiftmoduleFinder.Architecture, framework: Framework, visitor: ChangeVisitor) {
		let oldMembers = (old[platform]![architecture] ?? .init()).first { $0.name == framework.name }?.members ?? []
		let newMembers = (new[platform]![architecture] ?? .init()).first { $0.name == framework.name }?.members ?? []

		for memberChange in Change<Member>.differences(from: oldMembers, to: newMembers) {
			visitor.willVisitMember?(memberChange)
			// ..anything to do?
			visitor.didVisitMember?(memberChange)
		}
	}

	fileprivate func enumerateNamedTypeDifferences(for platform: SwiftmoduleFinder.Platform, architecture: SwiftmoduleFinder.Architecture, framework: Framework, visitor: ChangeVisitor) {
		let oldNamedTypes = (old[platform]![architecture] ?? .init()).first { $0.name == framework.name }?.dataTypes ?? []
		let newNamedTypes = (new[platform]![architecture] ?? .init()).first { $0.name == framework.name }?.dataTypes ?? []

		for namedTypeChange in Change<NamedType>.differences(from: oldNamedTypes, to: newNamedTypes) {
			visitor.willVisitDataType?(namedTypeChange)
			_enumerateNamedTypeDifferences(oldNamedTypes: oldNamedTypes, newNamedTypes: newNamedTypes, visitor: visitor)
			visitor.didVisitDataType?(namedTypeChange)
		}
	}

	fileprivate func _enumerateNamedTypeDifferences(oldNamedTypes: [NamedType], newNamedTypes: [NamedType], visitor: ChangeVisitor) {
		for namedTypeChange in Change<NamedType>.differences(from: oldNamedTypes, to: newNamedTypes) {
			visitor.willVisitDataType?(namedTypeChange)
			// recurse named types
			visitor.didVisitDataType?(namedTypeChange)
		}
	}
}
