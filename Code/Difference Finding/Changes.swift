import Foundation

typealias Summary = [SwiftmoduleFinder.Platform: [SwiftmoduleFinder.Architecture: Set<Framework>]]

enum Change {
	case removed
	case modified
	case unchanged
	case added

	/// Find any platforms that were introduced or removed across packages, e.g. visionOS being introduced
	static func platformChanges(from old: Summary, to new: Summary) -> [(Change, SwiftmoduleFinder.Platform)] {
		var visited = Set<SwiftmoduleFinder.Platform>()
		var results = [(Change, SwiftmoduleFinder.Platform)]()
		for platform in old.keys {
			if new[platform] == nil {
				visited.insert(platform)
				results.append((.removed, platform))
			}
		}
		for platform in new.keys {
			if old[platform] == nil {
				visited.insert(platform)
				results.append((.added, platform))
			}
		}
		for platform in Set(Array(old.keys) + Array(new.keys)) {
			if !visited.contains(platform) {
				results.append((.unchanged, platform))
			}
		}

		return results
	}

	/// Find any architectures that were introduced, modified, or removed across packages, e.g. armv6 being removed or arm64 being added
	static func architecturalChanges(from old: [SwiftmoduleFinder.Architecture], to new: [SwiftmoduleFinder.Architecture]) -> [(Change, SwiftmoduleFinder.Architecture)] {
		var visited = Set<SwiftmoduleFinder.Architecture>()
		var results = [(Change, SwiftmoduleFinder.Architecture)]()
		for architecture in new {
			if !old.contains(architecture) {
				visited.insert(architecture)
				results.append((.added, architecture))
			}
		}
		for architecture in old {
			if !new.contains(old) {
				visited.insert(architecture)
				results.append((.removed, architecture))
			}
		}
		for architecture in old + new {
			if !visited.contains(architecture) {
				results.append((.unchanged, architecture))
			}
		}
		return results
	}

	/// Find any frameworks that were introduced, modified, or removed across packages, e.g. ThingKit being added, GizmoKit being removed, or UIKit being updated
	static func frameworkChanges(from old: Set<Framework>, to new: Set<Framework>) -> [(Change, Framework)] {
		var visited = Set<Framework>()
		var results = [(Change, Framework)]()
		let oldList = Array(old.lazy)
		let newList = Array(new.lazy)
		let oldNames = Set(old.map { $0.name })
		let newNames = Set(new.map { $0.name })

		for i in 0..<newList.count {
			let framework = newList[i]
			if !oldNames.contains(framework.name) {
				visited.insert(newList[i])
				results.append((.added, newList[i]))
			}
		}
		for i in 0..<oldList.count {
			let framework = oldList[i]
			if !newNames.contains(framework.name) {
				visited.insert(oldList[i])
				results.append((.removed, oldList[i]))
			}
		}
		for framework in oldList + newList {
			if !visited.contains(framework) {
				results.append((.unchanged, framework))
			}
		}
		return results
	}

	/// Find any dependencies that were introduced, modified, or removed across packages, e.g. starting to import CoreData or @_export Network
	static func importChanges(from old: [Import], to new: [Import]) -> [(Change, Import)] {
		var results = [(Change, Import)]()
		for `import` in old {
			if !new.contains(`import`) {
				results.append((.removed, `import`))
			}
		}
		for `import` in new {
			if !old.contains(`import`) {
				results.append((.added, `import`))
			}
		}
		return results
	}

	/// Find any data structures that were introduced, modified, or removed across packages, e.g. a class being removed or a struct that is added
	static func dataTypeChanges(from old: [NamedType], to new: [NamedType]) -> [(Change, NamedType)] {
		[]
	}

	/// Find any members that were introduced, modified, or removed across packages, e.g. a new enum case or a var that is deprecated
	static func memberChanges(from old: [Member], to new: [Member]) -> [(Change, NamedType)] {
		[]
	}
}
