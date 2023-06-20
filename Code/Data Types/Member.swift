import Foundation

struct Member: Codable, CustomStringConvertible, Hashable, Sendable {
	enum Kind: Codable, Hashable, Sendable {
		case `unknown`
		case `let`
		case `var`
		case `func`
		case `case`
		case `associatedtype`
		case `typealias`
		case `operator`
	}

	enum Accessor: Codable, Hashable, Sendable {
		case `get`
		case `set`
	}

	enum Decorator: Codable, Hashable, Sendable {
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
"""
------
    accessors: \(accessors)
    attributes: \(attributes)
    decorators: \(decorators)
    kind: \(kind)
    name: \(name)
    returnType: \(returnType)
    parameters: \(parameters)
------
"""
	}
}
