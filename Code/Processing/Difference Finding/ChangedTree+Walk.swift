import Foundation

extension ChangedTree {
	func walk(visitors: ChangeVisitor?..., trace: Bool) {
		var tree = StorageTree()

		var activeNamedTypeStack = [Nested]()

		let visitors = visitors.compactMap { $0 }
		let aggregateVisitor = ChangeVisitor(
			willBegin: { visitors.forEach { v in v.willBegin() } },
			didEnd: { tree in visitors.forEach { v in v.didEnd(tree) } },
			willVisitPlatform: { platform in
				tree.append(.init(value: platform.change(keyPath: \.rawValue)))

				visitors.forEach { v in if v.shouldVisitPlatform(platform) { v.willVisitPlatform?(platform) } }
			}, didVisitPlatform: { platform in
				visitors.forEach { v in if v.shouldVisitPlatform(platform) { v.didVisitPlatform?(platform) } }
			}, willVisitArchitecture: { architecture in
				tree.last!.architectures.append(.init(value: architecture.change(keyPath: \.self)))

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
				let newType = ChangedTree.Platform.Architecture.Framework.NamedType(value: namedType.change(keyPath: \.developerFacingValue))

				// For ALL changes (not just modifications), check if base type is the same
				// This handles cases where conformances differ but everything else matches
				let (oldNT, newNT): (NamedType?, NamedType?) = {
					switch namedType {
					case .modified(let old, let new):
						return (old, new)
					case .added(_, let new), .removed(_, let new):
						// For added/removed, check if there's a matching type with different conformances
						// This shouldn't happen in normal diff, but we'll be defensive
						return (nil, new)
					case .unchanged(let old, let new):
						return (old, new)
					}
				}()

				if let oldNT = oldNT, let newNT = newNT {
					// Add attribute changes
					let addedAttributes = Set(newNT.attributes).subtracting(oldNT.attributes)
					let removedAttributes = Set(oldNT.attributes).subtracting(newNT.attributes)

					for attribute in removedAttributes.sorted(by: { $0.name < $1.name }) {
						newType.attributeChanges.append(.removed(attribute.developerFacingValue, attribute.developerFacingValue))
					}

					for attribute in addedAttributes.sorted(by: { $0.name < $1.name }) {
						newType.attributeChanges.append(.added(attribute.developerFacingValue, attribute.developerFacingValue))
					}

					// Add conformance changes
					let addedConformances = Set(newNT.conformances).subtracting(oldNT.conformances)
					let removedConformances = Set(oldNT.conformances).subtracting(newNT.conformances)

					for conformance in removedConformances.sorted() {
						newType.conformanceChanges.append(.removed(conformance, conformance))
					}

					for conformance in addedConformances.sorted() {
						newType.conformanceChanges.append(.added(conformance, conformance))
					}
				}

				activeNamedTypeStack.append(newType)

				visitors.forEach { v in if v.shouldVisitNamedType(namedType) { v.willVisitNamedType?(namedType) } }
			}, didVisitNamedType: { namedType in
				// Pre-compute display name with inline changes for the completed type
				var completedType = activeNamedTypeStack.removeLast() as! ChangedTree.Platform.Architecture.Framework.NamedType

				// Check if this is a metadata-only change
				let hasMembers = completedType.members.contains { $0.isNotUnchanged }
				let hasNestedTypes = completedType.namedTypes.contains { $0.isInteresting }
				let hasConformanceChanges = !completedType.conformanceChanges.isEmpty
				let hasAttributeChanges = !completedType.attributeChanges.isEmpty
				let isMetadataOnlyChange = (hasConformanceChanges || hasAttributeChanges) &&
					completedType.value.kind == "modified" && !hasMembers && !hasNestedTypes

				// Build fully qualified name for nested types
				// The parent is at the top of activeNamedTypeStack (after we removed completedType)
				var qualifiedName = completedType.value.any
				if let parent = activeNamedTypeStack.last as? ChangedTree.Platform.Architecture.Framework.NamedType {
					// This is a nested type, prefix with parent name
					let parentName = parent.value.any
					// Extract just the type name from parent (strip attributes, conformances, etc.)
					// Parent format is like "struct Foo" or "class Bar: Protocol"
					if let typeNameRange = parentName.range(of: "^(?:@[^\\s]+\\s+)*(?:open\\s+|package\\s+|public\\s+|internal\\s+|fileprivate\\s+|private\\s+)?(?:final\\s+|static\\s+)?(?:class|struct|enum|protocol|actor|extension)\\s+([^:<{]+)", options: .regularExpression) {
						let extractedParent = String(parentName[typeNameRange])
						// Get just the name part after the keyword
						let parts = extractedParent.split(separator: " ")
						if let lastName = parts.last {
							qualifiedName = "\(lastName).\(qualifiedName)"
						}
					}
				}

				if isMetadataOnlyChange {
					var changes: [String] = []

					for attrChange in completedType.attributeChanges {
						switch attrChange {
						case .added(_, let value):
							changes.append("<span class=\"added\">\(value.htmlEscape())</span>")
						case .removed(_, let value):
							changes.append("<span class=\"removed\">\(value.htmlEscape())</span>")
						default:
							break
						}
					}

					for confChange in completedType.conformanceChanges {
						switch confChange {
						case .added(_, let value):
							changes.append("<span class=\"added\">\(value.htmlEscape())</span>")
						case .removed(_, let value):
							changes.append("<span class=\"removed\">\(value.htmlEscape())</span>")
						default:
							break
						}
					}

					if !changes.isEmpty {
						completedType.displayName = "\(qualifiedName.htmlEscape()) (\(changes.joined(separator: ", ")))"
					}
				} else if activeNamedTypeStack.last is ChangedTree.Platform.Architecture.Framework.NamedType {
					// For non-metadata-only nested types, still show qualified name
					completedType.displayName = qualifiedName.htmlEscape()
				}

				var copy = activeNamedTypeStack.removeLast()
				copy.namedTypes.append(completedType)
				activeNamedTypeStack.append(copy)

				visitors.forEach { v in if v.shouldVisitNamedType(namedType) { v.didVisitNamedType?(namedType) } }
			}, willVisitMember: { member in
				var copy = activeNamedTypeStack.removeLast()
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
		let oldFrameworks = old[platform]?[architecture] ?? .init()
		let newFrameworks = new[platform]?[architecture] ?? .init()

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
		let oldDependencies = oldIndex[platform]?[architecture]?[framework.name]?.dependencies ?? []
		let newDependencies = newIndex[platform]?[architecture]?[framework.name]?.dependencies ?? []

		for dependencyChange in Change<Framework>.differences(from: oldDependencies, to: newDependencies) {
			guard visitor.shouldVisitDependency(dependencyChange) else { continue }

			visitor.willVisitDependency?(dependencyChange)
			// nothing to do; imports are leaf nodes
			visitor.didVisitDependency?(dependencyChange)
		}
	}

	fileprivate func enumeratePrecedenceGroupDifferences(for platform: SwiftmoduleFinder.Platform, architecture: SwiftmoduleFinder.Architecture, framework: Framework, visitor: ChangeVisitor) {
		let oldPrecedenceGroups = oldIndex[platform]?[architecture]?[framework.name]?.precedenceGroups ?? []
		let newPrecedenceGroups = newIndex[platform]?[architecture]?[framework.name]?.precedenceGroups ?? []

		for precedenceGroupChange in Change<PrecedenceGroup>.differences(from: oldPrecedenceGroups, to: newPrecedenceGroups) {
			guard visitor.shouldVisitPrecedenceGroup(precedenceGroupChange) else { continue }

			visitor.willVisitPrecedenceGroup?(precedenceGroupChange)
			// nothing to do; precedence groups are leaf nodes
			visitor.didVisitPrecedenceGroup?(precedenceGroupChange)
		}
	}

	fileprivate func enumerateMemberDifferences(for platform: SwiftmoduleFinder.Platform, architecture: SwiftmoduleFinder.Architecture, framework: Framework, visitor: ChangeVisitor) {
		let oldMembers = oldIndex[platform]?[architecture]?[framework.name]?.members ?? []
		let newMembers = newIndex[platform]?[architecture]?[framework.name]?.members ?? []

		_enumerateMemberDifferences(oldMembers: oldMembers, newMembers: newMembers, visitor: visitor)
	}

	fileprivate func enumerateNamedTypeDifferences(for platform: SwiftmoduleFinder.Platform, architecture: SwiftmoduleFinder.Architecture, framework: Framework, visitor: ChangeVisitor) {
		let oldNamedTypes = oldIndex[platform]?[architecture]?[framework.name]?.namedTypes ?? []
		let newNamedTypes = newIndex[platform]?[architecture]?[framework.name]?.namedTypes ?? []

		_enumerateNamedTypeDifferences(oldNamedTypes: oldNamedTypes, newNamedTypes: newNamedTypes, visitor: visitor)
	}

	fileprivate func _enumerateNamedTypeDifferences(oldNamedTypes: [NamedType], newNamedTypes: [NamedType], visitor: ChangeVisitor) {
		// First pass: find types that only differ in conformances and/or attributes
		var remainingOld = oldNamedTypes
		var remainingNew = newNamedTypes
		var metadataOnlyChanges: [(old: NamedType, new: NamedType)] = []

		for oldType in oldNamedTypes {
			if let newType = newNamedTypes.first(where: { $0.isSameExceptConformancesAndAttributes(oldType) && $0 != oldType }) {
				metadataOnlyChanges.append((old: oldType, new: newType))
				remainingOld.removeAll { $0 == oldType }
				remainingNew.removeAll { $0 == newType }
			}
		}

		// Handle conformance/attribute-only changes as modified types
		for (oldType, newType) in metadataOnlyChanges {
			let typeChange = Change<NamedType>.modified(oldType, newType)
			guard visitor.shouldVisitNamedType(typeChange) else { continue }

			visitor.willVisitNamedType?(typeChange)

			// Process nested types and members normally
			_enumerateNamedTypeDifferences(oldNamedTypes: oldType.nestedTypes, newNamedTypes: newType.nestedTypes, visitor: visitor)
			_enumerateMemberDifferences(oldMembers: oldType.members, newMembers: newType.members, visitor: visitor)

			visitor.didVisitNamedType?(typeChange)
		}

		// Second pass: handle regular changes for remaining types
		for namedTypeChange in Change<NamedType>.differences(from: remainingOld, to: remainingNew) {
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
