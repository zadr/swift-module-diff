import Foundation

struct Member {
	enum Kind: String, Codable, Hashable, Sendable {
		case `unknown`
		case `let`
		case `var`
		case `func`
		case `case`
		case `associatedtype`
		case `typealias`
		case `subscript`
	}

	enum Accessor: String, Codable, Hashable, Sendable {
		case `get`
		case `set`
		case `mutating`
		case `nonmutating`
		case `async`
		case `throws`
	}

	enum Decorator: String, Codable, Equatable, Hashable, Sendable {
		case `final`
		case `open`
		case `static`
		case `weak`
		case `unsafe` = "unowned(unsafe)"
		case `safe` = "unowned(safe)"
		case `unowned`
		case `nonisolated`
		case `distributed`
		case `mutating`
		case `nonmutating`
		case `optional`
		case `lazy`
		case `dynamic`
		case `indirect`
		case `required`
		case `convenience`
		case `consuming`
		case `borrowing`
	}

	enum Effect: Codable, Equatable, Hashable, Sendable {
		case `async`
		case `throws`(errorType: String?)
		case `rethrows`
		case `reasync`

		var rawValue: String {
			switch self {
			case .async: return "async"
			case .throws(let errorType):
				if let errorType = errorType {
					return "throws(\(errorType))"
				}
				return "throws"
			case .rethrows: return "rethrows"
			case .reasync: return "reasync"
			}
		}
	}

	var accessors: [Accessor] = []
	var attributes: [Attribute] = []
	var kind: Kind = .unknown
	var decorators: Set<Decorator> = .init()
	var effects: [Effect] = []
	var generics: [Parameter] = []
	var genericConstraints: [Parameter] = []
	var name: String = ""
	var returnType: String = ""
	var parameters: [Parameter] = []

	var description: String {
"""
  accessors: \(accessors)
 attributes: \(attributes)
	   kind: \(kind)
 decorators: \(decorators)
       name: \(name)
    effects: \(effects)
 returnType: \(returnType)
 parameters: \(parameters)
   generics: \(generics) constraints \(genericConstraints)
"""
	}
}

extension Member {
	var developerFacingValue: String {
		let attributes = attributes.map { $0.developerFacingValue }.joined(separator: " ")

		var decorators = decorators.map { $0.rawValue }.joined(separator: " ")
		if !decorators.isEmpty { decorators += " " }

		var effects = effects.map { $0.rawValue }.joined(separator: " ")
		if !effects.isEmpty { effects = " \(effects) "}

		switch kind {
		case .unknown:
			return "<<MEMBER UNKNOWN>>"

		case .let:
			return "\(attributes) \(decorators)let \(name): \(returnType)".trimmingCharacters(in: .whitespaces)

		case .var:
			var accessors = accessors.map { $0.rawValue }.joined(separator: " ")
			if !accessors.isEmpty {
				accessors = " { \(accessors) }"
			}
			return "\(attributes) \(decorators)var \(name): \(returnType)\(accessors) \(effects)".trimmingCharacters(in: .whitespaces)

		case .func:
			let parameters = parameters.map { $0.developerFacingValue }.joined(separator: ", ")
			let returnType = returnType.isEmpty ? "" : " -> \(returnType)"
			let generics = generics.isEmpty ? "" : "<\(generics.map { $0.developerFacingValue }.joined(separator: ", "))>"
			let constraint = genericConstraints.isEmpty ? "" : " where \(genericConstraints.map { $0.developerFacingValue }.joined(separator: ", "))"
			return "\(attributes) \(decorators)func \(name)\(generics)(\(parameters))\(effects)\(returnType)\(constraint)".trimmingCharacters(in: .whitespaces)

		case .case:
			var parameters = parameters.map { $0.developerFacingValue }.joined(separator: ", ")
			if !parameters.isEmpty {
				parameters = "(\(parameters))"
			}
			return "\(attributes) \(decorators)case \(name)\(parameters)".trimmingCharacters(in: .whitespaces)

		case .associatedtype:
			return "associatedtype \(name)"

		case .typealias:
			let generics = generics.isEmpty ? "" : " <\(generics.map { $0.developerFacingValue }.joined(separator: ", "))>"
			return "typealias \(name)\(generics) = \(returnType)"

		case .subscript:
			let parameters = parameters.map { $0.developerFacingValue }.joined(separator: ", ")
			let returnType = returnType.isEmpty ? "" : " -> \(returnType)"
			let accessors = accessors.isEmpty ? "" : " { \(accessors.map { $0 .rawValue }.joined(separator: " ")) \(effects) }".trimmingCharacters(in: .whitespaces)
			return "subscript (\(parameters))\(returnType)\(accessors)"
		}
	}
}

// MARK: - Swift Protocol Conformances

extension Member: Codable, CustomStringConvertible, Hashable, Sendable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(kind)
		hasher.combine(name)
		hasher.combine(decorators)
		hasher.combine(effects)
		hasher.combine(parameters)
		hasher.combine(generics)
		hasher.combine(genericConstraints)
		hasher.combine(returnType)
	}

	static func ==(lhs: Member, rhs: Member) -> Bool {
		lhs.kind == rhs.kind &&
			lhs.name == rhs.name &&
			lhs.decorators == rhs.decorators &&
			lhs.effects == rhs.effects &&
			lhs.parameters == rhs.parameters &&
			lhs.generics == rhs.generics &&
			lhs.genericConstraints == rhs.genericConstraints &&
			lhs.returnType == rhs.returnType
	}
}
