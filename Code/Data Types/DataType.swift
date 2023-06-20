import Foundation

struct DataType: Codable, CustomStringConvertible, Hashable, Sendable {
	enum Kind: Codable, Hashable {
		case unknown
		case `class`
		case `enum`
		case `struct`
		case `protocol`
		case `extension`
		case `associatedtype`
	}

	var attributes: Set<Attribute> = .init()
	var availabilities: [Availability] = []
	var kind: Kind = .unknown
	var isFinal: Bool = false
	var isOpen: Bool = false
	var name: String = ""

	var conformances = [String]()

	// includes `var`, `let`, and `func`
	var members = [Member]()

	// includes `enum`, `struct`, `class`, extension`, and `associatedtype`
	var nestedTypes = [DataType]()

	var description: String {
"""
------
    attributes: \(attributes)
    availability: \(availabilities)
    final > '\(isFinal)' || open > '\(isOpen)' for kind > '\(kind)' named > '\(name)'
    conformances: \(conformances.joined(separator: ", "))
    has:
\(members)
------
"""
	}
}
