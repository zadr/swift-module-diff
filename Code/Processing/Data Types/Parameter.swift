import Foundation

struct Parameter {
	enum Decorator: String, Codable, Equatable, Hashable, Sendable {
		case `inout`
		case `borrowing`
		case `consuming`
		case `isolated`
		case `__owned` = "__owned"
		case `__shared` = "__shared"
	}

	enum Separator: String, Codable, Equatable, Hashable, Sendable {
		case colon = ":"
		case doubleEqual = "=="

		var developerFacingValue: String {
			switch self {
			case .colon: return ":"
			case .doubleEqual: return " =="
			}
		}
	}

	var name: String = ""
	var type: String = ""
	var decorators: Set<Decorator> = .init()
	var attributes: [Attribute] = []
	var generics: [Parameter] = []
	var genericConstraints: [Parameter] = []
	var separator: Separator = .colon
	var suffix: String = ""
	var defaultValue: String = ""

	// Cache for developerFacingValue to avoid repeated string construction
	private var _cachedDeveloperFacingValue: String?

	var description: String {
"""
------
    name: \(name)
    type: \(type)
	decorators: \(decorators)
    attributes: \(attributes)
    separator: \(separator)
    generics: \(generics) constraints \(genericConstraints)
    suffix: \(suffix)
    defaultValue: \(defaultValue)
------
"""
	}
}

extension Parameter {
	var developerFacingValue: String {
		if let cached = _cachedDeveloperFacingValue {
			return cached
		}

		var generics = generics.map { $0.developerFacingValue }.joined(separator: ", ")
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
		var defaultVal = ""
		if !defaultValue.isEmpty {
			defaultVal = " = \(defaultValue)"
		}
		let result = "\(decorators)\(name)\(separator.developerFacingValue) \(type)\(generics)\(suffix)\(defaultVal)"
		return result
	}

	mutating func cacheDeveloperFacingValue() {
		_cachedDeveloperFacingValue = developerFacingValue
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
		hasher.combine(suffix)
		hasher.combine(defaultValue)
	}

	static func ==(lhs: Parameter, rhs: Parameter) -> Bool {
		lhs.name == rhs.name && lhs.decorators == rhs.decorators && lhs.type == rhs.type && lhs.generics == rhs.generics && lhs.genericConstraints == rhs.genericConstraints && lhs.suffix == rhs.suffix && lhs.defaultValue == rhs.defaultValue
	}
}

extension Parameter: Comparable {
	static func <(lhs: Parameter, rhs: Parameter) -> Bool {
		lhs.developerFacingValue < rhs.developerFacingValue
	}
}
