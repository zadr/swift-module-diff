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
		case `package`
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
		case `__consuming` = "__consuming"
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

	private var _cachedDeveloperFacingValue: String?

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
		if let cached = _cachedDeveloperFacingValue {
			return cached
		}

		let attributes = attributes.map { $0.developerFacingValue }.joined(separator: " ")

		var accessLevel = ""
		var otherDecorators = decorators

		if decorators.contains(.open) {
			accessLevel = "open "
			otherDecorators.remove(.open)
		} else if decorators.contains(.package) {
			accessLevel = "package "
			otherDecorators.remove(.package)
		}

		var decoratorsStr = otherDecorators.map { $0.rawValue }.joined(separator: " ")
		if !decoratorsStr.isEmpty { decoratorsStr += " " }

		var effects = effects.map { $0.rawValue }.joined(separator: " ")
		if !effects.isEmpty { effects = " \(effects) "}

		let result: String
		switch kind {
		case .unknown:
			result = "<<MEMBER UNKNOWN>>"

		case .let:
			result = "\(attributes) \(accessLevel)\(decoratorsStr)let \(name): \(returnType)".trimmingCharacters(in: .whitespaces)

		case .var:
			var accessors = accessors.map { $0.rawValue }.joined(separator: " ")
			if !accessors.isEmpty {
				accessors = " { \(accessors)\(effects) }"
			}
			result = "\(attributes) \(accessLevel)\(decoratorsStr)var \(name): \(returnType)\(accessors)".trimmingCharacters(in: .whitespaces)

		case .func:
			let parameters = parameters.map { $0.developerFacingValue }.joined(separator: ", ")
			let returnType = returnType.isEmpty ? "" : " -> \(returnType)"
			let generics = generics.isEmpty ? "" : "<\(generics.map { $0.developerFacingValue }.joined(separator: ", "))>"
			let constraint = genericConstraints.isEmpty ? "" : " where \(genericConstraints.map { $0.developerFacingValue }.joined(separator: ", "))"
			result = "\(attributes) \(accessLevel)\(decoratorsStr)func \(name)\(generics)(\(parameters))\(effects)\(returnType)\(constraint)".trimmingCharacters(in: .whitespaces)

		case .case:
			var parameters = parameters.map { $0.developerFacingValue }.joined(separator: ", ")
			if !parameters.isEmpty {
				parameters = "(\(parameters))"
			}
			result = "\(attributes) \(accessLevel)\(decoratorsStr)case \(name)\(parameters)".trimmingCharacters(in: .whitespaces)

		case .associatedtype:
			result = "associatedtype \(name)"

		case .typealias:
			let generics = generics.isEmpty ? "" : " <\(generics.map { $0.developerFacingValue }.joined(separator: ", "))>"
			result = "typealias \(name)\(generics) = \(returnType)"

		case .subscript:
			let parameters = parameters.map { $0.developerFacingValue }.joined(separator: ", ")
			let returnType = returnType.isEmpty ? "" : " -> \(returnType)"
			let accessors = accessors.isEmpty ? "" : " { \(accessors.map { $0 .rawValue }.joined(separator: " ")) \(effects) }".trimmingCharacters(in: .whitespaces)
			result = "subscript (\(parameters))\(returnType)\(accessors)"
		}

		return result
	}

	mutating func cacheDeveloperFacingValue() {
		_cachedDeveloperFacingValue = developerFacingValue
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
