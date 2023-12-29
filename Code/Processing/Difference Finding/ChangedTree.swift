import Foundation

protocol Nested {
	var namedTypes: [ChangedTree.Platform.Architecture.Framework.NamedType] { get set }
	var members: [Change<String>] { get set }
}

struct ChangedTree {
	class Platform: Equatable, Hashable, Comparable, Encodable {
		class Architecture: Equatable, Hashable, Comparable, Encodable {
			class Framework: Equatable, Hashable, Comparable, Encodable, Nested {
				class NamedType: Equatable, Hashable, Comparable, Encodable, Named, Nested {
					let value: Change<String>

					var name: String { value.any }
					var members = [Change<String>]()
					var namedTypes = [ChangedTree.Platform.Architecture.Framework.NamedType]()

					var isInteresting: Bool {
						return value.isNotUnchanged ||
						members.reduce(false) { $0 || $1.isNotUnchanged } ||
						namedTypes.reduce(false) { $0 || $1.isInteresting }
					}

					init(value: Change<String>) {
						self.value = value
					}

					static func ==(lhs: ChangedTree.Platform.Architecture.Framework.NamedType, rhs: ChangedTree.Platform.Architecture.Framework.NamedType) -> Bool {
						lhs.value == rhs.value
					}

					func hash(into hasher: inout Hasher) {
						hasher.combine(value)
					}

					static func <(lhs: ChangedTree.Platform.Architecture.Framework.NamedType, rhs: ChangedTree.Platform.Architecture.Framework.NamedType) -> Bool {
						return lhs.value.any < rhs.value.any
					}
				}

				let value: Change<String>
				var dependencies = [Change<String>]()
				var members = [Change<String>]()
				var namedTypes = [ChangedTree.Platform.Architecture.Framework.NamedType]()
				var precedenceGroups = [Change<String>]()

				init(value: Change<String>) {
					self.value = value
				}

				static func ==(lhs: ChangedTree.Platform.Architecture.Framework, rhs: ChangedTree.Platform.Architecture.Framework) -> Bool {
					lhs.value == rhs.value
				}

				func hash(into hasher: inout Hasher) {
					hasher.combine(value)
				}

				static func <(lhs: ChangedTree.Platform.Architecture.Framework, rhs: ChangedTree.Platform.Architecture.Framework) -> Bool {
					return lhs.value.any < rhs.value.any
				}
			}

			let value: Change<String>
			var frameworks = [ChangedTree.Platform.Architecture.Framework]()

			init(value: Change<String>) {
				self.value = value
			}

			static func ==(lhs: ChangedTree.Platform.Architecture, rhs: ChangedTree.Platform.Architecture) -> Bool {
				lhs.value == rhs.value
			}

			func hash(into hasher: inout Hasher) {
				hasher.combine(value)
			}

			static func <(lhs: ChangedTree.Platform.Architecture, rhs: ChangedTree.Platform.Architecture) -> Bool {
				return lhs.value.any < rhs.value.any
			}
		}

		let value: Change<String>
		var architectures = [ChangedTree.Platform.Architecture]()

		init(value: Change<String>) {
			self.value = value
		}

		static func ==(lhs: ChangedTree.Platform, rhs: ChangedTree.Platform) -> Bool {
			lhs.value == rhs.value
		}

		func hash(into hasher: inout Hasher) {
			hasher.combine(value)
		}

		static func <(lhs: ChangedTree.Platform, rhs: ChangedTree.Platform) -> Bool {
			return lhs.value.any < rhs.value.any
		}
	}

	typealias Version = OperatingSystemVersion
	typealias StorageTree = [ChangedTree.Platform]

	struct ChangeVisitor {
		var willBegin: (() -> Void) = {}
		var didEnd: ((StorageTree) -> Void) = { _ in }

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

		var shouldVisitPrecedenceGroup: ((Change<PrecedenceGroup>) -> Bool) = { _ in true }
		var willVisitPrecedenceGroup: ((Change<PrecedenceGroup>) -> Void)? = nil
		var didVisitPrecedenceGroup: ((Change<PrecedenceGroup>) -> Void)? = nil
	}

	let old: Summary
	let new: Summary

	init(old: Summary, new: Summary) {
		self.old = old
		self.new = new
	}
}

extension ChangedTree.Version {
	var name: String { "\(majorVersion).\(minorVersion).\(patchVersion)" }

	init?(appPath root: String) {
		let plistPath = "Contents/Info.plist"
		let url = URL(fileURLWithPath: root + "/" + plistPath)
		guard let data = try? Data(contentsOf: url) else { return nil }
		guard let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else { return nil }
		guard let version = plist["CFBundleShortVersionString"] as? String else { return nil }

		let components = version.components(separatedBy: ".")
		switch components.count {
		case 0: return nil
		case 1: self = .init(majorVersion: Int(components[0]) ?? 0, minorVersion: 0, patchVersion: 0)
		case 2: self = .init(majorVersion: Int(components[0]) ?? 0, minorVersion: Int(components[1]) ?? 0, patchVersion: 0)
		case 3..<Int.max: self = .init(majorVersion: Int(components[0]) ?? 0, minorVersion: Int(components[1]) ?? 0, patchVersion: Int(components[2]) ?? 0)
		default: return nil
		}
	}
}

extension Array where Element == ChangedTree.Platform {
	func notableDifferences() -> [ChangedTree.Platform] {
		var interestingTree = [ChangedTree.Platform]()

		func append(members: [Change<String>], nested namedTypes: [ChangedTree.Platform.Architecture.Framework.NamedType], to parent: inout Nested) {
			let filteredMembers = members.filter { $0.isNotUnchanged }
			if !filteredMembers.isEmpty {
				parent.members.append(contentsOf: filteredMembers.sorted())
			}

			let filteredNamedTypes = namedTypes.filter { $0.isInteresting }
			for type in filteredNamedTypes.sorted() {
				var nested: Nested = ChangedTree.Platform.Architecture.Framework.NamedType(value: type.value)
				append(members: type.members, nested: type.namedTypes, to: &nested)
				parent.namedTypes.append(type)
			}
		}

		for platform in sorted() {
			interestingTree.append(.init(value: platform.value))

			for architecture in platform.architectures.sorted() {
				interestingTree.last!.architectures.append(.init(value: architecture.value))

				for framework in architecture.frameworks.sorted() {
					let dependencies = framework.dependencies.filter { $0.isNotUnchanged }
					let members = framework.members.filter { $0.isNotUnchanged }
					let namedTypes = framework.namedTypes.filter { $0.isInteresting }
					let precedenceGroups = framework.precedenceGroups.filter { $0.isNotUnchanged }

					if dependencies.isEmpty && members.isEmpty && namedTypes.isEmpty && precedenceGroups.isEmpty {
						continue
					}

					let frameworkAsFramework = ChangedTree.Platform.Architecture.Framework(value: framework.value)
					frameworkAsFramework.dependencies += dependencies
					frameworkAsFramework.precedenceGroups += precedenceGroups

					var frameworkAsNested: Nested = frameworkAsFramework

					append(members: members, nested: namedTypes, to: &frameworkAsNested)
					interestingTree.last!.architectures.last!.frameworks.append(frameworkAsFramework)
					continue
				}
			}
		}

		return interestingTree
	}
}
