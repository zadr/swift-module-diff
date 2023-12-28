import Foundation

struct Parameter {
	enum Decorator: String, Codable, Equatable, Hashable, Sendable {
		case `inout`

	enum Separator: String, Codable, Equatable, Hashable, Sendable {
		case colon = ":"
		case doubleEqual = "=="
	}

	var name: String = ""
	var type: String = ""
	var decorators: Set<Decorator> = .init()
	var attributes: Set<Attribute> = .init()
	var generics: [String] = []
	var genericConstraints: [Parameter] = []
	var separator: Separator = .colon

	var description: String {
"""
------
    name: \(name)
    type: \(type)
	decorators: \(decorators)
    attributes: \(attributes)
    separator: \(separator)
    generics: \(generics) constraints \(genericConstraints)
------
"""
	}
}

// MARK: - Swift Protocol Conformances

extension Parameter: Codable, CustomStringConvertible, Hashable, Sendable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(decorators)
		hasher.combine(type)
		hasher.combine(generics)
		hasher.combine(genericConstraints)
	}

	static func ==(lhs: Parameter, rhs: Parameter) -> Bool {
		lhs.name == rhs.name && lhs.decorators == rhs.decorators && lhs.type == rhs.type && lhs.generics == rhs.generics && lhs.genericConstraints == rhs.genericConstraints
	}
}

// MARK: - Custom Protocol Conformances

extension Parameter: Attributed, Named, Displayable {
	var developerFacingValue: String {
		var generics = generics.joined(separator: ", ")
		if !generics.isEmpty {
			generics = "<\(generics)>"
		}
		if type.isEmpty {
			return name
		}
		var decorators = decorators.map { $0.rawValue }.sorted().joined(separator: " ")
		if !decorators.isEmpty {
			decorators += " "
		}
		return "\(decorators)\(name)\(separator.rawValue) \(type)\(generics)"
	}
}

extension Parameter: Comparable {
	static func <(lhs: Parameter, rhs: Parameter) -> Bool {
		lhs.developerFacingValue < rhs.developerFacingValue
	}
}
