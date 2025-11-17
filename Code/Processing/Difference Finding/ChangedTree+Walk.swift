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
				let completedType = activeNamedTypeStack.removeLast() as! ChangedTree.Platform.Architecture.Framework.NamedType

				// Skip over an attribute with properly balanced parentheses
				func skipAttribute(in string: String, startingAt index: String.Index) -> String.Index {
					var current = index

					// Skip '@' and attribute name
					guard current < string.endIndex, string[current] == "@" else { return index }
					current = string.index(after: current)

					// Skip attribute name (word characters)
					while current < string.endIndex, string[current].isLetter || string[current].isNumber || string[current] == "_" {
						current = string.index(after: current)
					}

					// If followed by '(', skip balanced parentheses
					if current < string.endIndex, string[current] == "(" {
						current = string.index(after: current)
						var depth = 1
						while current < string.endIndex, depth > 0 {
							if string[current] == "(" {
								depth += 1
							} else if string[current] == ")" {
								depth -= 1
							}
							current = string.index(after: current)
						}
					}

					return current
				}

				// Extract simple type name from a full type declaration
				func extractTypeName(from fullDeclaration: String) -> String? {
					// Pattern matches: [@attrs] [modifiers] <kind> <name>[: conformances]
					// We need to manually skip attributes because they can have nested parentheses
					var current = fullDeclaration.startIndex

					// Skip whitespace and attributes
					while current < fullDeclaration.endIndex {
						// Skip leading whitespace
						while current < fullDeclaration.endIndex, fullDeclaration[current].isWhitespace {
							current = fullDeclaration.index(after: current)
						}

						// If we hit an attribute, skip it
						if current < fullDeclaration.endIndex, fullDeclaration[current] == "@" {
							current = skipAttribute(in: fullDeclaration, startingAt: current)
						} else {
							break
						}
					}

					// Now use regex to match modifiers + type kind + name
					let remainingString = String(fullDeclaration[current...])
					if let range = remainingString.range(of: "^(?:open\\s+|package\\s+|public\\s+|internal\\s+|fileprivate\\s+|private\\s+)?(?:final\\s+|static\\s+)?(?:class|struct|enum|protocol|actor|extension)\\s+([^:<{\\s]+)", options: .regularExpression) {
						let extracted = String(remainingString[range])
						let parts = extracted.split(separator: " ")
						return parts.last.map(String.init)
					}
					return nil
				}

				// Extract the type kind and name (without attributes/conformances)
				// e.g., "@available(...) struct Foo: Bar" -> "struct Foo"
				func extractTypeDeclaration(from fullDeclaration: String) -> String {
					// Skip attributes first
					var current = fullDeclaration.startIndex
					while current < fullDeclaration.endIndex {
						while current < fullDeclaration.endIndex, fullDeclaration[current].isWhitespace {
							current = fullDeclaration.index(after: current)
						}
						if current < fullDeclaration.endIndex, fullDeclaration[current] == "@" {
							current = skipAttribute(in: fullDeclaration, startingAt: current)
						} else {
							break
						}
					}

					// Now extract everything up to the colon or opening brace
					let remainingString = String(fullDeclaration[current...])
					if let colonRange = remainingString.range(of: ":") {
						return remainingString[..<colonRange.lowerBound].trimmingCharacters(in: .whitespaces)
					} else if let braceRange = remainingString.range(of: "{") {
						return remainingString[..<braceRange.lowerBound].trimmingCharacters(in: .whitespaces)
					} else {
						return remainingString.trimmingCharacters(in: .whitespaces)
					}
				}

				// Build path from all parents (excluding the framework level)
				var parentNames: [String] = []
				for item in activeNamedTypeStack {
					if let namedType = item as? ChangedTree.Platform.Architecture.Framework.NamedType {
						if let name = extractTypeName(from: namedType.value.any) {
							parentNames.append(name)
						}
					}
				}

				// Build the base type declaration (with kind like "struct", "class", etc)
				let baseTypeDecl = extractTypeDeclaration(from: completedType.value.any)

				// For nested types, we want to show: "struct ParentType.ChildType"
				// Extract the type kind and name separately
				var typeKind = ""
				var simpleName = ""
				if let typeName = extractTypeName(from: baseTypeDecl) {
					// baseTypeDecl is like "struct Metadata" or "class Foo"
					// Extract the kind (struct/class/etc) by removing the name
					let nameIndex = baseTypeDecl.range(of: typeName, options: .backwards)
					if let idx = nameIndex {
						typeKind = String(baseTypeDecl[..<idx.lowerBound]).trimmingCharacters(in: .whitespaces)
						simpleName = typeName
					}
				}

				// Build qualified name with type kind
				var qualifiedTypeDecl: String
				if !parentNames.isEmpty {
					let fullPath = parentNames.joined(separator: ".") + "." + simpleName
					qualifiedTypeDecl = typeKind.isEmpty ? fullPath : "\(typeKind) \(fullPath)"
				} else {
					qualifiedTypeDecl = baseTypeDecl
				}

				// Generate styled display name if there are attribute or conformance changes
				if !completedType.attributeChanges.isEmpty || !completedType.conformanceChanges.isEmpty {
					let baseTypeName = qualifiedTypeDecl

					// Separate attribute and conformance changes
					var attributeChanges: [String] = []
					var conformanceChanges: [String] = []

					for attrChange in completedType.attributeChanges {
						switch attrChange {
						case .added(_, let value):
							attributeChanges.append("<span class=\"added\">\(value.htmlEscape())</span>")
						case .removed(_, let value):
							attributeChanges.append("<span class=\"removed\">\(value.htmlEscape())</span>")
						default:
							break
						}
					}

					for confChange in completedType.conformanceChanges {
						switch confChange {
						case .added(_, let value):
							conformanceChanges.append("<span class=\"added\">\(value.htmlEscape())</span>")
						case .removed(_, let value):
							conformanceChanges.append("<span class=\"removed\">\(value.htmlEscape())</span>")
						default:
							break
						}
					}

					// Build display: attributes first (Swift syntax), then type declaration, then conformances
					var display = ""

					// Attributes go before the type declaration
					if !attributeChanges.isEmpty {
						display = attributeChanges.joined(separator: " ") + " "
					}

					// Add the base type name
					display += baseTypeName.htmlEscape()

					// Conformances go after the type declaration
					if !conformanceChanges.isEmpty {
						display += " " + conformanceChanges.joined(separator: " ")
					}

					completedType.displayName = display
				} else if activeNamedTypeStack.last is ChangedTree.Platform.Architecture.Framework.NamedType {
					// For nested types without changes, still show qualified name with type kind
					completedType.displayName = qualifiedTypeDecl.htmlEscape()
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
			visitor.didVisitDependency?(dependencyChange)
		}
	}

	fileprivate func enumeratePrecedenceGroupDifferences(for platform: SwiftmoduleFinder.Platform, architecture: SwiftmoduleFinder.Architecture, framework: Framework, visitor: ChangeVisitor) {
		let oldPrecedenceGroups = oldIndex[platform]?[architecture]?[framework.name]?.precedenceGroups ?? []
		let newPrecedenceGroups = newIndex[platform]?[architecture]?[framework.name]?.precedenceGroups ?? []

		for precedenceGroupChange in Change<PrecedenceGroup>.differences(from: oldPrecedenceGroups, to: newPrecedenceGroups) {
			guard visitor.shouldVisitPrecedenceGroup(precedenceGroupChange) else { continue }

			visitor.willVisitPrecedenceGroup?(precedenceGroupChange)
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
		var remainingOld = oldNamedTypes
		var remainingNew = newNamedTypes
		var matchedChanges: [(old: NamedType, new: NamedType)] = []

		for oldType in oldNamedTypes {
			if let newType = newNamedTypes.first(where: { $0.isSameExceptConformancesAndAttributes(oldType) && $0 != oldType }) {
				matchedChanges.append((old: oldType, new: newType))
				remainingOld.removeAll { $0 == oldType }
				remainingNew.removeAll { $0 == newType }
			}
		}

		for (oldType, newType) in matchedChanges {
			let typeChange = Change<NamedType>.modified(oldType, newType)
			guard visitor.shouldVisitNamedType(typeChange) else { continue }

			visitor.willVisitNamedType?(typeChange)

			_enumerateNamedTypeDifferences(oldNamedTypes: oldType.nestedTypes, newNamedTypes: newType.nestedTypes, visitor: visitor)
			_enumerateMemberDifferences(oldMembers: oldType.members, newMembers: newType.members, visitor: visitor)

			visitor.didVisitNamedType?(typeChange)
		}

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
			visitor.didVisitMember?(memberChange)
		}
	}
}
