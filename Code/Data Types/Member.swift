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
		let attributes = self.attributes.map { attribute in
			var baseName = "@" + attribute.name
			if !attribute.parameters.isEmpty {
				baseName += "("
				baseName += attribute.parameters.reduce("") {
					return $0 + $1.name + $1.type
				}
				baseName += ")"
			}
			return baseName
		}.joined(separator: " ")

		var decorators = self.decorators.map { $0.rawValue }.joined(separator: " ")
		if !decorators.isEmpty { decorators += " " }
		switch kind {
		case .unknown:
			return "<<MEMBER UNKNOWN>>"

		case .let:
			return """
\(attributes)
\(decorators)let \(name): \(returnType)
"""

		case .var:
			var accessors = self.accessors.map { $0.rawValue }.joined(separator: " ")
			if !accessors.isEmpty {
				accessors = " { \(accessors) }"
			}
			return """
\(attributes)
\(decorators)var \(name): \(returnType)\(accessors)
"""

		case .func:
			let parameters = self.parameters.map {
				"\($0.name): \($0.type)"
			}.joined(separator: ", ")
			let returnType = self.returnType.isEmpty ? "" : " -> \(returnType)"
			return """
\(attributes)
\(decorators)func \(name)(\(parameters))\(returnType)
"""

		case .case:
			var p = self.parameters.map {
				"\($0.type)"
			}.joined(separator: ", ")
			if !p.isEmpty {
				p = "(\(p))"
			}
			return """
\(attributes)
\(decorators)case \(name)\(p)
"""

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
