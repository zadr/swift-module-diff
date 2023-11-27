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
		var shouldVisitPlatform: ((Change<SwiftmoduleFinder.Platform>) -> Bool) = { _ in true }
		var willVisitPlatform: ((Change<SwiftmoduleFinder.Platform>) -> Void)? = nil
		var didVisitPlatform: ((Change<SwiftmoduleFinder.Platform>) -> Void)? = nil

		var shouldVisitArchitecture: ((Change<SwiftmoduleFinder.Architecture>) -> Bool) = { _ in true }
		var willVisitArchitecture: ((Change<SwiftmoduleFinder.Architecture>) -> Void)? = nil
		var didVisitArchitecture: ((Change<SwiftmoduleFinder.Architecture>) -> Void)? = nil

		var shouldVisitFramework: ((Change<Framework>) -> Bool) = { _ in true }
		var willVisitFramework: ((Change<Framework>) -> Void)? = nil
		var didVisitFramework: ((Change<Framework>) -> Void)? = nil

		var shouldVisitImport: ((Change<Import>) -> Bool) = { _ in true }
		var willVisitImport: ((Change<Import>) -> Void)? = nil
		var didVisitImport: ((Change<Import>) -> Void)? = nil

		var shouldVisitDataType: ((Change<NamedType>) -> Bool) = { _ in true }
		var willVisitDataType: ((Change<NamedType>) -> Void)? = nil
		var didVisitDataType: ((Change<NamedType>) -> Void)? = nil

		var shouldVisitMember: ((Change<Member>) -> Bool) = { _ in true }
		var willVisitMember: ((Change<Member>) -> Void)? = nil
		var didVisitMember: ((Change<Member>) -> Void)? = nil
	}

	internal static func ifNotUnchanged<T>(change: Change<T>, perform: () -> Void, else elseBlock: () -> Void = {}) {
		if case .unchanged(_, _) = change {
			elseBlock()
			return
		}
		perform()
	}

	fileprivate func enumeratePlatformDifferences(visitor: ChangeVisitor) {
		for platformChange in Change<SwiftmoduleFinder.Platform>.differences(from: old.keys, to: new.keys) {
			guard visitor.shouldVisitPlatform(platformChange) else { continue }

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
			guard visitor.shouldVisitArchitecture(architectureChange) else { continue }

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
			guard visitor.shouldVisitFramework(frameworkChange) else { continue }

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
			guard visitor.shouldVisitDependency(dependencyChange) else { continue }

			visitor.willVisitImport?(dependencyChange)
			// nothing to do; imports are leaf nodes
			visitor.didVisitImport?(dependencyChange)
		}
	}

	fileprivate func enumerateMemberDifferences(for platform: SwiftmoduleFinder.Platform, architecture: SwiftmoduleFinder.Architecture, framework: Framework, visitor: ChangeVisitor) {
		let oldMembers = (old[platform]![architecture] ?? .init()).first { $0.name == framework.name }?.members ?? []
		let newMembers = (new[platform]![architecture] ?? .init()).first { $0.name == framework.name }?.members ?? []

		_enumerateMemberDifferences(oldMembers: oldMembers, newMembers: newMembers, visitor: visitor)
	}

	fileprivate func enumerateNamedTypeDifferences(for platform: SwiftmoduleFinder.Platform, architecture: SwiftmoduleFinder.Architecture, framework: Framework, visitor: ChangeVisitor) {
		let oldNamedTypes = (old[platform]![architecture] ?? .init()).first { $0.name == framework.name }?.dataTypes ?? []
		let newNamedTypes = (new[platform]![architecture] ?? .init()).first { $0.name == framework.name }?.dataTypes ?? []

		for namedTypeChange in Change<NamedType>.differences(from: oldNamedTypes, to: newNamedTypes) {
			_enumerateNamedTypeDifferences(oldNamedTypes: oldNamedTypes, newNamedTypes: newNamedTypes, visitor: visitor)
		}
	}

	fileprivate func _enumerateNamedTypeDifferences(oldNamedTypes: [NamedType], newNamedTypes: [NamedType], visitor: ChangeVisitor) {
		for namedTypeChange in Change<NamedType>.differences(from: oldNamedTypes, to: newNamedTypes) {
			guard visitor.shouldVisitDataType(namedTypeChange) else { continue }

			visitor.willVisitDataType?(namedTypeChange)
			switch namedTypeChange {
			case .added(_, let new):
				_enumerateNamedTypeDifferences(oldNamedTypes: [], newNamedTypes: new.nestedTypes, visitor: visitor)
				_enumerateMemberDifferences(oldMembers: [], newMembers: new.members, visitor: visitor)
			case .removed(let old, _):
				_enumerateNamedTypeDifferences(oldNamedTypes: old.nestedTypes, newNamedTypes: [], visitor: visitor)
				_enumerateMemberDifferences(oldMembers: old.members, newMembers: [], visitor: visitor)
			case .modified(let old, let new), .unchanged(let old, let new):
				_enumerateNamedTypeDifferences(oldNamedTypes: old.nestedTypes, newNamedTypes: new.nestedTypes, visitor: visitor)
				_enumerateMemberDifferences(oldMembers: old.members, newMembers: new.members, visitor: visitor)
			}
			visitor.didVisitDataType?(namedTypeChange)
		}
	}

	fileprivate func _enumerateMemberDifferences(oldMembers: [Member], newMembers: [Member], visitor: ChangeVisitor) {
		for memberChange in Change<Member>.differences(from: oldMembers, to: newMembers) {
			guard visitor.shouldVisitMember(memberChange) else { continue }

			visitor.willVisitMember?(memberChange)
			// nothing to do; members are leaf nodes
			visitor.didVisitMember?(memberChange)
		}

	}
}
