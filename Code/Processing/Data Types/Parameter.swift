import Foundation

struct Parameter {
	enum Separator: String, Codable, Hashable, Sendable {
		case colon = ":"
		case doubleEqual = "=="
	}

	var name: String = ""
	var type: String = ""
	var isInout: Bool = false
	var attributes: Set<Attribute> = .init()
	var generics: Set<String> = .init()
	var genericConstraints: Set<Parameter> = .init()
	var separator: Separator = .colon

	var description: String {
"""
------
    name: \(name)
    type: \(type)
    isInout: \(isInout)
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
		hasher.combine(type)
		hasher.combine(generics)
		hasher.combine(genericConstraints)
	}

	static func ==(lhs: Parameter, rhs: Parameter) -> Bool {
		lhs.name == rhs.name && lhs.type == rhs.type && lhs.generics == rhs.generics && lhs.genericConstraints == rhs.genericConstraints
	}
}

// MARK: - Custom Protocol Conformances

extension Parameter: Attributed, Named, Displayable {
	var developerFacingValue: String {
		if type.isEmpty {
			return name
		}
		if isInout {
			return "inout \(name): \(type)"
		}
		return "\(name)\(separator.rawValue) \(type)"
	}
}
