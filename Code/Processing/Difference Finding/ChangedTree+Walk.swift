import Foundation

extension ChangedTree {
	/// Renders an inline diff for modified attributes (e.g., @available version changes)
	/// Example: @available(iOS: <del>17.2</del><ins>18.0</ins>, *)
	private func renderInlineDiff(old: String, new: String) -> String {
		// For @available attributes, split by common tokens and diff at token level
		// This ensures version numbers like "17.2" and "18.0" are treated as whole units

		// Split into tokens: words, numbers (including decimals), and punctuation
		func tokenize(_ str: String) -> [String] {
			var tokens: [String] = []
			var current = ""
			var lastWasDigit = false

			for char in str {
				let isDigit = char.isNumber || char == "."

				if isDigit == lastWasDigit && !current.isEmpty {
					current.append(char)
				} else {
					if !current.isEmpty {
						tokens.append(current)
					}
					current = String(char)
					lastWasDigit = isDigit
				}
			}

			if !current.isEmpty {
				tokens.append(current)
			}

			return tokens
		}

		let oldTokens = tokenize(old)
		let newTokens = tokenize(new)

		var result = ""
		var i = 0
		var j = 0

		// Find common prefix
		while i < oldTokens.count && j < newTokens.count && oldTokens[i] == newTokens[j] {
			result += oldTokens[i].htmlEscape()
			i += 1
			j += 1
		}

		// Find where they differ
		if i < oldTokens.count || j < newTokens.count {
			// Find common suffix
			var oldSuffixStart = oldTokens.count
			var newSuffixStart = newTokens.count

			while oldSuffixStart > i && newSuffixStart > j &&
				  oldTokens[oldSuffixStart - 1] == newTokens[newSuffixStart - 1] {
				oldSuffixStart -= 1
				newSuffixStart -= 1
			}

			// Render the difference
			if i < oldSuffixStart {
				let removed = oldTokens[i..<oldSuffixStart].joined()
				result += "<span class=\"removed\">\(removed.htmlEscape())</span>"
			}

			if j < newSuffixStart {
				let added = newTokens[j..<newSuffixStart].joined()
				result += "<span class=\"added\">\(added.htmlEscape())</span>"
			}

			// Add common suffix
			if oldSuffixStart < oldTokens.count {
				result += oldTokens[oldSuffixStart...].joined().htmlEscape()
			}
		}

		return result
	}

	func walk(visitors: ChangeVisitor?..., trace: Bool) {
		var tree = StorageTree()

		var activeNamedTypeStack = [Nested]()
		var currentPlatform: String = ""  // Track current platform for @available normalization

		let visitors = visitors.compactMap { $0 }
		let aggregateVisitor = ChangeVisitor(
			willBegin: { visitors.forEach { v in v.willBegin() } },
			didEnd: { tree in visitors.forEach { v in v.didEnd(tree) } },
			willVisitPlatform: { platform in
				// Update current platform for attribute normalization
				switch platform {
				case .added(_, let p), .removed(_, let p), .modified(let p, _), .unchanged(let p, _):
					currentPlatform = p.rawValue
				}

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
					// Add attribute changes (normalize @available for current platform)
					let normalizedOldAttrs = oldNT.attributes.compactMap { $0.normalized(for: currentPlatform) }
					let normalizedNewAttrs = newNT.attributes.compactMap { $0.normalized(for: currentPlatform) }

					// Group attributes by name for comparison
					var oldAttrsByName: [String: Attribute] = [:]
					var newAttrsByName: [String: Attribute] = [:]

					for attr in normalizedOldAttrs {
						oldAttrsByName[attr.name] = attr
					}
					for attr in normalizedNewAttrs {
						newAttrsByName[attr.name] = attr
					}

					// Find added, removed, and modified attributes
					let oldNames = Set(oldAttrsByName.keys)
					let newNames = Set(newAttrsByName.keys)

					let removedNames = oldNames.subtracting(newNames)
					let addedNames = newNames.subtracting(oldNames)
					let commonNames = oldNames.intersection(newNames)

					for name in removedNames.sorted() {
						let attr = oldAttrsByName[name]!
						newType.attributeChanges.append(.removed(attr.developerFacingValue, attr.developerFacingValue))
					}

					for name in addedNames.sorted() {
						let attr = newAttrsByName[name]!
						newType.attributeChanges.append(.added(attr.developerFacingValue, attr.developerFacingValue))
					}

					for name in commonNames.sorted() {
						let oldAttr = oldAttrsByName[name]!
						let newAttr = newAttrsByName[name]!

						// Check if the attribute parameters changed
						if oldAttr.parameters != newAttr.parameters {
							newType.attributeChanges.append(.modified(oldAttr.developerFacingValue, newAttr.developerFacingValue))
						}
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

					// Add generic constraint changes (where clauses)
					let oldConstraintSet = Set(oldNT.genericConstraints)
					let newConstraintSet = Set(newNT.genericConstraints)
					let addedConstraints = newConstraintSet.subtracting(oldConstraintSet)
					let removedConstraints = oldConstraintSet.subtracting(newConstraintSet)

					for constraint in removedConstraints.sorted() {
						newType.genericConstraintChanges.append(.removed(constraint.developerFacingValue, constraint.developerFacingValue))
					}

					for constraint in addedConstraints.sorted() {
						newType.genericConstraintChanges.append(.added(constraint.developerFacingValue, constraint.developerFacingValue))
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

				// Generate styled display name if there are attribute, conformance, or constraint changes
				if !completedType.attributeChanges.isEmpty || !completedType.conformanceChanges.isEmpty || !completedType.genericConstraintChanges.isEmpty {
					let baseTypeName = qualifiedTypeDecl

					// Separate attribute, conformance, and constraint changes
					var attributeChanges: [String] = []
					var conformanceChanges: [String] = []
					var constraintChanges: [String] = []

					for attrChange in completedType.attributeChanges {
						switch attrChange {
						case .added(_, let value):
							attributeChanges.append("<span class=\"added\">\(value.htmlEscape())</span>")
						case .removed(_, let value):
							attributeChanges.append("<span class=\"removed\">\(value.htmlEscape())</span>")
						case .modified(let old, let new):
							// Render inline diff for modified attributes
							let inlineDiff = renderInlineDiff(old: old, new: new)
							attributeChanges.append(inlineDiff)
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

					for constraintChange in completedType.genericConstraintChanges {
						switch constraintChange {
						case .added(_, let value):
							constraintChanges.append("<span class=\"added\">\(value.htmlEscape())</span>")
						case .removed(_, let value):
							constraintChanges.append("<span class=\"removed\">\(value.htmlEscape())</span>")
						default:
							break
						}
					}

					// Build display: attributes first (Swift syntax), then type declaration, then conformances, then constraints
					var display = ""

					// Attributes go before the type declaration
					if !attributeChanges.isEmpty {
						display = attributeChanges.joined(separator: " ") + " "
					}

					// Add the base type name
					display += baseTypeName.htmlEscape()

					// Conformance changes go after the type declaration (only show changes, not all conformances)
					// Format: "extension Foo added:Bar,Baz removed:Qux"
					if !conformanceChanges.isEmpty {
						display += " " + conformanceChanges.joined(separator: " ")
					}

					// Generic constraints go at the end (where clause)
					if !constraintChanges.isEmpty {
						display += " where " + constraintChanges.joined(separator: ", ")
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

		_enumerateNamedTypeDifferences(oldNamedTypes: oldNamedTypes, newNamedTypes: newNamedTypes, platform: platform.rawValue, visitor: visitor)
	}

	fileprivate func _enumerateNamedTypeDifferences(oldNamedTypes: [NamedType], newNamedTypes: [NamedType], platform: String, visitor: ChangeVisitor) {
		var remainingOld = oldNamedTypes
		var remainingNew = newNamedTypes
		var unchangedMatches: [(old: NamedType, new: NamedType)] = []
		var modifiedMatches: [(old: NamedType, new: NamedType)] = []

		// Helper to check if normalized attributes are the same
		func attributesMatch(_ old: NamedType, _ new: NamedType) -> Bool {
			let normalizedOld = old.attributes.compactMap { $0.normalized(for: platform) }
			let normalizedNew = new.attributes.compactMap { $0.normalized(for: platform) }
			return Set(normalizedOld) == Set(normalizedNew)
		}

		// First pass: Try to match types with exact conformances (for extensions)
		// This handles the case where we have multiple extensions of the same type
		// with different conformances that haven't changed
		for oldType in oldNamedTypes {
			// Try to find exact match first (including conformances)
			// We check if they're the same except for attributes, then verify attributes are also the same (after normalization)
			if let exactMatch = newNamedTypes.first(where: {
				$0.isSameExceptAttributes(oldType) && attributesMatch(oldType, $0)
			}) {
				unchangedMatches.append((old: oldType, new: exactMatch))
				remainingOld.removeAll { $0 == oldType }
				remainingNew.removeAll { $0 == exactMatch }
			}
		}

		// Second pass: Match remaining types with same identity but different conformances/attributes
		// This handles types where conformances or attributes actually changed
		for oldType in remainingOld {
			// Match types that have the same identity but different conformances and/or attributes
			if let newType = remainingNew.first(where: { $0.isSameExceptConformancesAndAttributes(oldType) }) {
				modifiedMatches.append((old: oldType, new: newType))
				remainingOld.removeAll { $0 == oldType }
				remainingNew.removeAll { $0 == newType }
			}
		}

		// Process unchanged matches
		for (oldType, newType) in unchangedMatches {
			let typeChange = Change<NamedType>.unchanged(oldType, newType)
			guard visitor.shouldVisitNamedType(typeChange) else { continue }

			visitor.willVisitNamedType?(typeChange)

			_enumerateNamedTypeDifferences(oldNamedTypes: oldType.nestedTypes, newNamedTypes: newType.nestedTypes, platform: platform, visitor: visitor)
			_enumerateMemberDifferences(oldMembers: oldType.members, newMembers: newType.members, visitor: visitor)

			visitor.didVisitNamedType?(typeChange)
		}

		// Process modified matches
		for (oldType, newType) in modifiedMatches {
			let typeChange = Change<NamedType>.modified(oldType, newType)
			guard visitor.shouldVisitNamedType(typeChange) else { continue }

			visitor.willVisitNamedType?(typeChange)

			_enumerateNamedTypeDifferences(oldNamedTypes: oldType.nestedTypes, newNamedTypes: newType.nestedTypes, platform: platform, visitor: visitor)
			_enumerateMemberDifferences(oldMembers: oldType.members, newMembers: newType.members, visitor: visitor)

			visitor.didVisitNamedType?(typeChange)
		}

		for namedTypeChange in Change<NamedType>.differences(from: remainingOld, to: remainingNew) {
			guard visitor.shouldVisitNamedType(namedTypeChange) else { continue }

			visitor.willVisitNamedType?(namedTypeChange)
			switch namedTypeChange {
			case .added(_, let new):
				_enumerateNamedTypeDifferences(oldNamedTypes: [], newNamedTypes: new.nestedTypes, platform: platform, visitor: visitor)
				_enumerateMemberDifferences(oldMembers: [], newMembers: new.members, visitor: visitor)
			case .removed(let old, _):
				_enumerateNamedTypeDifferences(oldNamedTypes: old.nestedTypes, newNamedTypes: [], platform: platform, visitor: visitor)
				_enumerateMemberDifferences(oldMembers: old.members, newMembers: [], visitor: visitor)
			case .modified(let old, let new), .unchanged(let old, let new):
				_enumerateNamedTypeDifferences(oldNamedTypes: old.nestedTypes, newNamedTypes: new.nestedTypes, platform: platform, visitor: visitor)
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
