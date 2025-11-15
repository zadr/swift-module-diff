import Foundation

struct NamedType {
	enum Decorator: String, Equatable, Codable, Hashable, Sendable {
		case `final`
		case `open`
		case `package`
		case `static`
		case `distributed`
		case `indirect`
		case `prefix`
		case `postfix`
		case `infix`
	}

	enum Kind: String, Codable, Hashable {
		case unknown
		case `actor`
		case `class`
		case `enum`
		case `struct`
		case `protocol`
		case `extension`
		case `associatedtype`
		case `macro`
		case `operator`
	}

	var attributes: [Attribute] = []
	var decorators: Set<Decorator> = .init()
	var generics: [Parameter] = []
	var genericConstraints: [Parameter] = []
	var kind: Kind = .unknown
	var name: String = ""

	var conformances = [String]()

	// Primary associated types (Swift 5.7+) - only for protocols
	// Example: protocol Collection<Element> has ["Element"] as primary associated types
	var primaryAssociatedTypes: [String] = []

	// includes `var`, `let`, and `func`
	var members = [Member]()

	// includes `enum`, `struct`, `class`, extension`, and `associatedtype`
	var nestedTypes = [NamedType]()

	// Cache for developerFacingValue to avoid repeated string construction
	private var _cachedDeveloperFacingValue: String?

	var description: String {
"""
------
    attributes: \(attributes)
	decorators > \(decorators)
    kind > '\(kind)' named > '\(name)'
    conformances: \(conformances.joined(separator: ", "))
	generics: \(generics) constraints \(genericConstraints)
    has:
\(members)
------
"""
	}
}

extension NamedType {
	var developerFacingValue: String {
		if let cached = _cachedDeveloperFacingValue {
			return cached
		}

		var attributes = attributes.sorted { $0.name > $1.name }.map { $0.developerFacingValue }.joined(separator: " ")
		if !attributes.isEmpty {
			attributes += " "
		}

		var conformances = conformances.sorted().joined(separator: ", ")
		if !conformances.isEmpty {
			conformances = ": \(conformances)"
		}

		// Primary associated types (for protocols only)
		var primaryTypes = primaryAssociatedTypes.joined(separator: ", ")
		if !primaryTypes.isEmpty {
			primaryTypes = "<\(primaryTypes)>"
		}

		var generics = generics.map { $0.developerFacingValue }.joined(separator: ", ")
		if !generics.isEmpty {
			generics = "<\(generics)>"
		}
		var genericConstraints = genericConstraints.map { $0.developerFacingValue }.joined(separator: ", ")
		if !genericConstraints.isEmpty {
			genericConstraints = " where \(genericConstraints)"
		}

		// Separate access level from other decorators
		var accessLevel = ""
		var otherDecorators = decorators

		if decorators.contains(.open) {
			accessLevel = "open "
			otherDecorators.remove(.open)
		} else if decorators.contains(.package) {
			accessLevel = "package "
			otherDecorators.remove(.package)
		}

		var decoratorsStr = Array(otherDecorators).map { $0.rawValue }.sorted().joined(separator: " ")
		if !decoratorsStr.isEmpty {
			decoratorsStr += " "
		}

		let result = "\(attributes)\(accessLevel)\(decoratorsStr)\(kind.rawValue) \(name)\(primaryTypes)\(generics)\(conformances)\(genericConstraints)".trimmingCharacters(in: .whitespaces)
		return result
	}

	mutating func cacheDeveloperFacingValue() {
		_cachedDeveloperFacingValue = developerFacingValue
	}
}

// MARK: - Swift Protocol Conformances

extension NamedType: Codable, CustomStringConvertible, Hashable, Sendable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(kind)
		hasher.combine(name)
		hasher.combine(conformances)
		hasher.combine(generics)
		hasher.combine(genericConstraints)
		hasher.combine(primaryAssociatedTypes)
	}

	static func ==(lhs: NamedType, rhs: NamedType) -> Bool {
		lhs.kind == rhs.kind &&
			lhs.name == rhs.name &&
			lhs.conformances == rhs.conformances &&
			lhs.generics == rhs.generics &&
			lhs.genericConstraints == rhs.genericConstraints &&
			lhs.primaryAssociatedTypes == rhs.primaryAssociatedTypes
	}

	/// Check if two types are identical except for their conformances
	func isSameExceptConformances(_ other: NamedType) -> Bool {
		kind == other.kind &&
			name == other.name &&
			generics == other.generics &&
			genericConstraints == other.genericConstraints &&
			primaryAssociatedTypes == other.primaryAssociatedTypes
	}

	/// Check if two types are identical except for their attributes
	func isSameExceptAttributes(_ other: NamedType) -> Bool {
		kind == other.kind &&
			name == other.name &&
			conformances == other.conformances &&
			generics == other.generics &&
			genericConstraints == other.genericConstraints &&
			primaryAssociatedTypes == other.primaryAssociatedTypes
	}

	/// Check if two types are identical except for their conformances and/or attributes
	func isSameExceptConformancesAndAttributes(_ other: NamedType) -> Bool {
		kind == other.kind &&
			name == other.name &&
			generics == other.generics &&
			genericConstraints == other.genericConstraints &&
			primaryAssociatedTypes == other.primaryAssociatedTypes
	}
}
