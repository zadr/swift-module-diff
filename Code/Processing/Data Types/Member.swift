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
	}

	enum Accessor: String, Codable, Hashable, Sendable {
		case `get`
		case `set`
		case `mutating`
		case `nonmutating`
	}

	enum Decorator: String, Codable, Equatable, Hashable, Sendable {
		case `final`
		case `open`
		case `static`
		case `throwing`
		case `async`
		case `weak`
		case `unsafe`
		case `unowned`
		case `nonisolated`
		case `mutating`
		case `nonmutating`
		case `optional`
		case `lazy`
	}

	var accessors: [Accessor] = []
	var attributes: [Attribute] = []
	var kind: Kind = .unknown
	var decorators: Set<Decorator> = .init()
	var generics: [String] = []
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
 returnType: \(returnType)
 parameters: \(parameters)
   generics: \(generics) constraints \(genericConstraints)
"""
	}
}

// MARK: - Swift Protocol Conformances

extension Member: Codable, CustomStringConvertible, Hashable, Sendable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(kind)
		hasher.combine(name)
		hasher.combine(parameters)
		hasher.combine(generics)
		hasher.combine(genericConstraints)
		hasher.combine(returnType)
	}

	static func ==(lhs: Member, rhs: Member) -> Bool {
		lhs.kind == rhs.kind &&
			lhs.name == rhs.name &&
			lhs.parameters == rhs.parameters &&
			lhs.generics == rhs.generics &&
			lhs.genericConstraints == rhs.genericConstraints &&
			lhs.returnType == rhs.returnType
	}
}

// MARK: - Custom Protocol Conformances

extension Member: Attributed, Decorated, Named, Displayable {
	var developerFacingValue: String {
		let attributes = attributes.map { $0.developerFacingValue }.joined(separator: " ")

		var decorators = decorators.map { $0.rawValue }.joined(separator: " ")
		if !decorators.isEmpty { decorators += " " }
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
			return "\(attributes) \(decorators)var \(name): \(returnType)\(accessors)".trimmingCharacters(in: .whitespaces)

		case .func:
			let parameters = parameters.map { $0.developerFacingValue }.joined(separator: ", ")
			let returnType = returnType.isEmpty ? "" : " -> \(returnType)"
			return "\(attributes) \(decorators)func \(name)(\(parameters))\(returnType)".trimmingCharacters(in: .whitespaces)

		case .case:
			var parameters = parameters.map { $0.developerFacingValue }.joined(separator: ", ")
			if !parameters.isEmpty {
				parameters = "(\(parameters))"
			}
			return "\(attributes) \(decorators)case \(name)\(parameters)".trimmingCharacters(in: .whitespaces)

		case .associatedtype:
			return "associatedtype \(name)"

		case .typealias:
			return "typealias \(name) = \(returnType)"
		}
	}
}
