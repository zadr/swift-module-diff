import Foundation

protocol Nested {
	var namedTypes: [Summarizer.Tree.Platform.Architecture.Framework.NamedType] { get set }
	var members: [Change<String>] { get set }
}

struct Summarizer {
	enum Tree {
		class Platform: Equatable, Hashable, Comparable, Codable {
			class Architecture: Equatable, Hashable, Comparable, Codable {
				class Framework: Equatable, Hashable, Comparable, Codable, Nested {
					class NamedType: Equatable, Hashable, Comparable, Codable, Named, Nested {
						let value: Change<String>

						var name: String { value.any }
						var members = [Change<String>]()
						var namedTypes = [Summarizer.Tree.Platform.Architecture.Framework.NamedType]()

						init(value: Change<String>) {
							self.value = value
						}

						static func ==(lhs: Summarizer.Tree.Platform.Architecture.Framework.NamedType, rhs: Summarizer.Tree.Platform.Architecture.Framework.NamedType) -> Bool {
							lhs.value == rhs.value
						}

						func hash(into hasher: inout Hasher) {
							hasher.combine(value)
						}

						static func <(lhs: Summarizer.Tree.Platform.Architecture.Framework.NamedType, rhs: Summarizer.Tree.Platform.Architecture.Framework.NamedType) -> Bool {
							return lhs.value.any < rhs.value.any
						}
					}

					let value: Change<String>
					var dependencies = [Change<String>]()
					var members = [Change<String>]()
					var namedTypes = [Summarizer.Tree.Platform.Architecture.Framework.NamedType]()

					init(value: Change<String>) {
						self.value = value
					}

					static func ==(lhs: Summarizer.Tree.Platform.Architecture.Framework, rhs: Summarizer.Tree.Platform.Architecture.Framework) -> Bool {
						lhs.value == rhs.value
					}

					func hash(into hasher: inout Hasher) {
						hasher.combine(value)
					}

					static func <(lhs: Summarizer.Tree.Platform.Architecture.Framework, rhs: Summarizer.Tree.Platform.Architecture.Framework) -> Bool {
						return lhs.value.any < rhs.value.any
					}
				}

				let value: Change<String>
				var frameworks = [Summarizer.Tree.Platform.Architecture.Framework]()

				init(value: Change<String>) {
					self.value = value
				}

				static func ==(lhs: Summarizer.Tree.Platform.Architecture, rhs: Summarizer.Tree.Platform.Architecture) -> Bool {
					lhs.value == rhs.value
				}

				func hash(into hasher: inout Hasher) {
					hasher.combine(value)
				}

				static func <(lhs: Summarizer.Tree.Platform.Architecture, rhs: Summarizer.Tree.Platform.Architecture) -> Bool {
					return lhs.value.any < rhs.value.any
				}
			}

			let value: Change<String>
			var architectures = [Summarizer.Tree.Platform.Architecture]()

			init(value: Change<String>) {
				self.value = value
			}

			static func ==(lhs: Summarizer.Tree.Platform, rhs: Summarizer.Tree.Platform) -> Bool {
				lhs.value == rhs.value
			}

			func hash(into hasher: inout Hasher) {
				hasher.combine(value)
			}

			static func <(lhs: Summarizer.Tree.Platform, rhs: Summarizer.Tree.Platform) -> Bool {
				return lhs.value.any < rhs.value.any
			}
		}
	}

	typealias Version = OperatingSystemVersion
	typealias StorageTree = [Summarizer.Tree.Platform]

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
	}

	let old: Summary
	let new: Summary

	init(old: Summary, new: Summary) {
		self.old = old
		self.new = new
	}

	func summarize(visitors: ChangeVisitor?..., trace: Bool) {
		var tree = StorageTree()

		var activeNamedTypeStack = [Nested]()

		let visitors = visitors.compactMap { $0 }
		let aggregateVisitor = ChangeVisitor(
			willBegin: { visitors.forEach { v in v.willBegin() } },
			didEnd: { tree in visitors.forEach { v in v.didEnd(tree) } },
			willVisitPlatform: { platform in
				tree.append(.init(value: platform.change(keyPath: \.name)))

				visitors.forEach { v in if v.shouldVisitPlatform(platform) { v.willVisitPlatform?(platform) } }
			}, didVisitPlatform: { platform in
				visitors.forEach { v in if v.shouldVisitPlatform(platform) { v.didVisitPlatform?(platform) } }
			}, willVisitArchitecture: { architecture in
				tree.last!.architectures.append(.init(value: architecture.change(keyPath: \.name)))

				visitors.forEach { v in if v.shouldVisitArchitecture(architecture) { v.willVisitArchitecture?(architecture) } }
			}, didVisitArchitecture: { architecture in
				visitors.forEach { v in if v.shouldVisitArchitecture(architecture) { v.didVisitArchitecture?(architecture) } }
			}, willVisitFramework: { framework in
				tree.last!.architectures.last!.frameworks.append(.init(value: framework.change(keyPath: \.name)))
				activeNamedTypeStack.append(tree.last!.architectures.last!.frameworks.last!)

				visitors.forEach { v in if v.shouldVisitFramework(framework) { v.willVisitFramework?(framework) } }
			}, didVisitFramework: { framework in
				activeNamedTypeStack.removeLast()

				visitors.forEach { v in if v.shouldVisitFramework(framework) { v.didVisitFramework?(framework) } }
			}, willVisitDependency: { dependency in
				tree.last!.architectures.last!.frameworks.last!.dependencies.append(dependency.change(keyPath: \.developerFacingValue))

				visitors.forEach { v in if v.shouldVisitDependency(dependency) { v.willVisitDependency?(dependency) } }
			}, didVisitDependency: { dependency in
				visitors.forEach { v in if v.shouldVisitDependency(dependency) { v.didVisitDependency?(dependency) } }
			}, willVisitNamedType: { namedType in
				activeNamedTypeStack.append(Summarizer.Tree.Platform.Architecture.Framework.NamedType(value: namedType.change(keyPath: \.developerFacingValue)))

				visitors.forEach { v in if v.shouldVisitNamedType(namedType) { v.willVisitNamedType?(namedType) } }
			}, didVisitNamedType: { namedType in
				let completedType = activeNamedTypeStack.removeLast() as! Summarizer.Tree.Platform.Architecture.Framework.NamedType
				var copy = activeNamedTypeStack.removeLast()
				copy.namedTypes.append(completedType)
				activeNamedTypeStack.append(copy)

				visitors.forEach { v in if v.shouldVisitNamedType(namedType) { v.didVisitNamedType?(namedType) } }
			}, willVisitMember: { member in
				var copy = activeNamedTypeStack.removeLast()
				print("\(copy) gets \(member.change(keyPath: \.developerFacingValue).any)")
				copy.members.append(member.change(keyPath: \.developerFacingValue))
				activeNamedTypeStack.append(copy)

				visitors.forEach { v in if v.shouldVisitMember(member) { v.willVisitMember?(member) } }
			}, didVisitMember: { member in
				visitors.forEach { v in if v.shouldVisitMember(member) { v.didVisitMember?(member) } }
			}
		)

		aggregateVisitor.willBegin()
		enumeratePlatformDifferences(visitor: aggregateVisitor)
		aggregateVisitor.didEnd(tree)
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

extension Summarizer.Version {
	var name: String { "\(majorVersion).\(minorVersion).\(patchVersion)" }
}
