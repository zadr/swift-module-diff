import Foundation

struct Summarizer {
	struct ChangeVisitor {
		var shouldVisitPlatform: ((Change<SwiftmoduleFinder.Platform>) -> Bool) = { _ in true }
		var willVisitPlatform: ((Change<SwiftmoduleFinder.Platform>) -> Void)? = nil
		var didVisitPlatform: ((Change<SwiftmoduleFinder.Platform>) -> Void)? = nil

		var shouldVisitArchitecture: ((Change<SwiftmoduleFinder.Architecture>) -> Bool) = { _ in true }
		var willVisitArchitecture: ((Change<SwiftmoduleFinder.Architecture>) -> Void)? = nil
		var didVisitArchitecture: ((Change<SwiftmoduleFinder.Architecture>) -> Void)? = nil

		var shouldVisitFramework: ((Change<Framework>) -> Bool) = { _ in true }
		var willVisitFramework: ((Change<Framework>) -> Void)? = nil
		var didVisitFramework: ((Change<Framework>) -> Void)? = nil

		var shouldVisitDependency: ((Change<Dependency>) -> Bool) = { _ in true }
		var willVisitDependency: ((Change<Dependency>) -> Void)? = nil
		var didVisitDependency: ((Change<Dependency>) -> Void)? = nil

		var shouldVisitNamedType: ((Change<NamedType>) -> Bool) = { _ in true }
		var willVisitNamedType: ((Change<NamedType>) -> Void)? = nil
		var didVisitNamedType: ((Change<NamedType>) -> Void)? = nil

		var shouldVisitMember: ((Change<Member>) -> Bool) = { _ in true }
		var willVisitMember: ((Change<Member>) -> Void)? = nil
		var didVisitMember: ((Change<Member>) -> Void)? = nil
	}

	let old: Summary
	let new: Summary

	init(old: Summary, new: Summary) {
		self.old = old
		self.new = new
	}

	func summarize(visitors: ChangeVisitor?..., trace: Bool) {
		let visitors = visitors.compactMap { $0 }
		let aggregateVisitor = ChangeVisitor(
			willBegin: { visitors.forEach { v in v.willBegin() } },
			didEnd: { visitors.forEach { v in v.didEnd() } },
			willVisitPlatform: { platform in
				visitors.forEach { v in if v.shouldVisitPlatform(platform) { v.willVisitPlatform?(platform) } }
			}, didVisitPlatform: { platform in
				visitors.forEach { v in if v.shouldVisitPlatform(platform) { v.didVisitPlatform?(platform) } }
			}, willVisitArchitecture: { architecture in
				visitors.forEach { v in if v.shouldVisitArchitecture(architecture) { v.willVisitArchitecture?(architecture) } }
			}, didVisitArchitecture: { architecture in
				visitors.forEach { v in if v.shouldVisitArchitecture(architecture) { v.didVisitArchitecture?(architecture) } }
			}, willVisitFramework: { framework in
				visitors.forEach { v in if v.shouldVisitFramework(framework) { v.willVisitFramework?(framework) } }
			}, didVisitFramework: { framework in
				visitors.forEach { v in if v.shouldVisitFramework(framework) { v.didVisitFramework?(framework) } }
			}, willVisitDependency: { dependency in
				visitors.forEach { v in if v.shouldVisitDependency(dependency) { v.willVisitDependency?(dependency) } }
			}, didVisitDependency: { dependency in
				visitors.forEach { v in if v.shouldVisitDependency(dependency) { v.didVisitDependency?(dependency) } }
			}, willVisitNamedType: { namedType in
				visitors.forEach { v in if v.shouldVisitNamedType(namedType) { v.willVisitNamedType?(namedType) } }
			}, didVisitNamedType: { namedType in
				visitors.forEach { v in if v.shouldVisitNamedType(namedType) { v.didVisitNamedType?(namedType) } }
			}, willVisitMember: { member in
				visitors.forEach { v in if v.shouldVisitMember(member) { v.willVisitMember?(member) } }
			}, didVisitMember: { member in
				visitors.forEach { v in if v.shouldVisitMember(member) { v.didVisitMember?(member) } }
			}
		)

		aggregateVisitor.willBegin()
		enumeratePlatformDifferences(visitor: aggregateVisitor)
		aggregateVisitor.didEnd()
	}
}

extension Summarizer {
	internal static func ifNotUnchanged<T>(change: Change<T>, perform: () -> Void, else elseBlock: () -> Void = {}) {
		if case .unchanged(_, _) = change {
			elseBlock()
		} else {
			perform()
		}
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

			visitor.willVisitDependency?(dependencyChange)
			// nothing to do; imports are leaf nodes
			visitor.didVisitDependency?(dependencyChange)
		}
	}

	fileprivate func enumerateMemberDifferences(for platform: SwiftmoduleFinder.Platform, architecture: SwiftmoduleFinder.Architecture, framework: Framework, visitor: ChangeVisitor) {
		let oldMembers = (old[platform]![architecture] ?? .init()).first { $0.name == framework.name }?.members ?? []
		let newMembers = (new[platform]![architecture] ?? .init()).first { $0.name == framework.name }?.members ?? []

		_enumerateMemberDifferences(oldMembers: oldMembers, newMembers: newMembers, visitor: visitor)
	}

	fileprivate func enumerateNamedTypeDifferences(for platform: SwiftmoduleFinder.Platform, architecture: SwiftmoduleFinder.Architecture, framework: Framework, visitor: ChangeVisitor) {
		let oldNamedTypes = (old[platform]![architecture] ?? .init()).first { $0.name == framework.name }?.namedTypes ?? []
		let newNamedTypes = (new[platform]![architecture] ?? .init()).first { $0.name == framework.name }?.namedTypes ?? []

		_enumerateNamedTypeDifferences(oldNamedTypes: oldNamedTypes, newNamedTypes: newNamedTypes, visitor: visitor)
	}

	fileprivate func _enumerateNamedTypeDifferences(oldNamedTypes: [NamedType], newNamedTypes: [NamedType], visitor: ChangeVisitor) {
		for namedTypeChange in Change<NamedType>.differences(from: oldNamedTypes, to: newNamedTypes) {
			guard visitor.shouldVisitNamedType(namedTypeChange) else { continue }

			visitor.willVisitNamedType?(namedTypeChange)
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
			visitor.didVisitNamedType?(namedTypeChange)
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
