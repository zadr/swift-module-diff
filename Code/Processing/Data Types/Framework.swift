import Foundation

struct Framework {
	var attributes: [Attribute] = []
	var dependencies = [Dependency]()
	var namedTypes = [NamedType]()
	var members = [Member]()
	var precedenceGroups = [PrecedenceGroup]()
	var name = ""

	var description: String {
"""
------
    | name: \(name) |
    | attributes: \(attributes)
    | dependencies: \(dependencies.count): \(dependencies) |
    | types: \(namedTypes.count):
\(namedTypes) |
	| members: \(members.count):
\(members) |
	| precedenceGroups: \(precedenceGroups.count):
\(precedenceGroups)
------
"""
	}
}

// MARK: - Swift Protocol Conformances

extension Framework: Codable, CustomStringConvertible, Equatable, Hashable, Sendable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}

	static func ==(lhs: Framework, rhs: Framework) -> Bool {
		lhs.name == rhs.name
	}

	/// Merges duplicate extensions of the same type into a single extension with combined conformances.
	/// This is useful because Swift may define separate extensions for each conformance:
	///   extension Never : TransferRepresentation { ... }
	///   extension Never : Transferable { ... }
	/// We want to treat these as a single extension: `extension Never : TransferRepresentation, Transferable`
	mutating func mergeExtensions() {
		// Group extensions by their identity (name, attributes, generic constraints)
		var extensionGroups: [String: [Int]] = [:]

		for (index, type) in namedTypes.enumerated() {
			guard type.kind == .extension else { continue }

			// Create a key from the extension's identity (everything except conformances)
			// Use full developerFacingValue for attributes to distinguish @available(iOS 15) from @available(iOS 16)
			let key = "\(type.name)|\(type.attributes.map { $0.developerFacingValue }.sorted().joined(separator: ","))|\(type.generics.map { $0.developerFacingValue }.joined(separator: ","))|\(type.genericConstraints.map { $0.developerFacingValue }.joined(separator: ","))|\(type.decorators.map { $0.rawValue }.sorted().joined(separator: ","))"

			extensionGroups[key, default: []].append(index)
		}

		// Merge extensions that have the same identity
		var mergedTypes: [NamedType] = []
		var processedIndices = Set<Int>()

		for (_, indices) in extensionGroups {
			if indices.count > 1 {
				// Multiple extensions with same identity - merge them
				var merged = namedTypes[indices[0]]

				for i in indices.dropFirst() {
					let ext = namedTypes[i]
					// Combine conformances
					merged.conformances.append(contentsOf: ext.conformances)
					// Combine members
					merged.members.append(contentsOf: ext.members)
					// Combine nested types
					merged.nestedTypes.append(contentsOf: ext.nestedTypes)
					processedIndices.insert(i)
				}

				// Sort conformances to maintain canonical order
				merged.conformances = merged.conformances.sorted()
				// Remove duplicates
				merged.conformances = Array(Set(merged.conformances)).sorted()

				mergedTypes.append(merged)
				processedIndices.insert(indices[0])
			}
		}

		// Add all non-merged types
		for (index, type) in namedTypes.enumerated() {
			if !processedIndices.contains(index) {
				mergedTypes.append(type)
			}
		}

		namedTypes = mergedTypes
	}
}
