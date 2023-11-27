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
		case `operator`
	}

	enum Accessor: String, Codable, Hashable, Sendable {
		case `get`
		case `set`
	}

	enum Decorator: String, Codable, Hashable, Sendable {
		case `final`
		case `open`
		case `static`
		case `throwing`
		case `async`
		case `weak`
		case `unsafe`
		case `unowned`
	}

	var accessors: Set<Accessor> = .init()
	var attributes: Set<Attribute> = .init()
	var kind: Kind = .unknown
	var decorators: Set<Decorator> = .init()
	var name: String = ""
	var returnType: String = ""
	var parameters: [Parameter] = []

	var description: String {
		let attributes = attributes.map { $0.developerFacingName }.joined(separator: " ")

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
			let parameters = parameters.map { $0.developerFacingName }.joined(separator: ", ")
			let returnType = returnType.isEmpty ? "" : " -> \(returnType)"
			return "\(attributes) \(decorators)func \(name)(\(parameters))\(returnType)".trimmingCharacters(in: .whitespaces)

		case .case:
			var parameters = parameters.map { $0.developerFacingName }.joined(separator: ", ")
			if !parameters.isEmpty {
				parameters = "(\(parameters))"
			}
			return "\(attributes) \(decorators)case \(name)\(parameters)".trimmingCharacters(in: .whitespaces)

		case .associatedtype:
			return "associatedtype \(name)"

		case .typealias:
			return "typealias \(name) = \(returnType)"

		case .operator:
			return "operator \(name)"
		}
	}
}

// MARK: - Swift Protocol Conformances

extension Member: Codable, CustomStringConvertible, Hashable, Sendable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}

	static func ==(lhs: Member, rhs: Member) -> Bool {
		lhs.name == rhs.name
	}
}

// MARK: - Custom Protocol Conformances

extension Member: Attributed, Decorated, Named, Displayable {
	var developerFacingName: String {
		description
	}
}
