import Foundation

struct NamedType {
	enum Decorator: String, Equatable, Codable, Hashable, Sendable {
		case `final`
		case `open`
		case `static`
		case `throwing`
		case `async`
		case `weak`
		case `unsafe`
		case `unowned`
		case `indirect`
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
	}

	var attributes: Set<Attribute> = .init()
	var decorators: Set<Decorator> = .init()
	var generics: [String] = []
	var genericConstraints: [Parameter] = []
	var kind: Kind = .unknown
	var name: String = ""

	var conformances = [String]()

	// includes `var`, `let`, and `func`
	var members = [Member]()

	// includes `enum`, `struct`, `class`, extension`, and `associatedtype`
	var nestedTypes = [NamedType]()

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

// MARK: - Swift Protocol Conformances

extension NamedType: Codable, CustomStringConvertible, Hashable, Sendable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(kind)
		hasher.combine(name)
		hasher.combine(conformances)
		hasher.combine(generics)
		hasher.combine(genericConstraints)
	}

	static func ==(lhs: NamedType, rhs: NamedType) -> Bool {
		lhs.kind == rhs.kind &&
			lhs.name == rhs.name &&
			lhs.conformances == rhs.conformances &&
			lhs.generics == rhs.generics &&
			lhs.genericConstraints == rhs.genericConstraints
	}
}

// MARK: - Custom Protocol Conformances

extension NamedType: Attributed, Decorated, Displayable, Named {
	var developerFacingValue: String {
		let attributes = attributes.sorted { $0.name > $1.name }.map { $0.developerFacingValue }.joined(separator: " ")

		var conformances = conformances.sorted().joined(separator: ", ")
		if !conformances.isEmpty {
			conformances = ": \(conformances)"
		}
		var generics = generics.joined(separator: ", ")
		if !generics.isEmpty {
			generics = "<\(generics)>"
		}
		var genericConstraints = genericConstraints.map { $0.developerFacingValue }.joined(separator: ", ")
		if !genericConstraints.isEmpty {
			genericConstraints = " where \(genericConstraints)"
		}

		var decorators = Array(decorators).map { $0.rawValue }.sorted().joined(separator: " ")
		if !decorators.isEmpty {
			decorators = " \(decorators) "
		}
		return "\(attributes)\(decorators)\(kind.rawValue) \(name)\(generics)\(conformances)\(genericConstraints)".trimmingCharacters(in: .whitespaces)
	}
}
