import Foundation

struct Member: CustomStringConvertible, Hashable {
	enum Kind: Hashable {
		case `unknown`
		case `let`
		case `var`
		case `func`
		case `case`
		case `associatedtype`
		case `typealias`
		case `operator`
	}

	enum Accessor: Hashable {
		case `get`
		case `set`
	}

	var accessors: Set<Accessor> = .init()
	var attributes: Set<Attribute> = .init()
	var kind: Kind = .unknown
	var isFinal: Bool = false
	var isOpen: Bool = false
	var name: String = ""
	var isStatic: Bool = false
	var returnType: String = ""
	var isThrowing: Bool = false
	var isAsync: Bool = false
	var isWeak: Bool = false
	var isUnsafe: Bool = false
	var isUnowned: Bool = false
	var parameters: [Parameter] = []

	var description: String {
"""
------
    accessors: \(accessors)
    attributes: \(attributes)
    kind: \(kind)
    isFinal: \(isFinal)
    isOpen: \(isOpen)
    name: \(name)
    isStatic: \(isStatic)
    returnType: \(returnType)
    isThrowing: \(isThrowing)
    isAsync: \(isAsync)
    isWeak: \(isWeak)
    isUnsafe: \(isUnsafe)
    isUnowned: \(isUnowned)
    parameters: \(parameters)
------
"""
	}
}
