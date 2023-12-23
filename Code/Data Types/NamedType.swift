import Foundation

struct NamedType {
	enum Decorator: String, Equatable, Codable, Hashable, Sendable {
		case `final`
		case `open`
		case `static`
		case `throwing`
		case `async`
		case `weak`
		case `unsafe`
		case `unowned`
	}

	enum Kind: String, Codable, Hashable {
		case unknown
		case `actor`
		case `class`
		case `enum`
		case `struct`
		case `protocol`
		case `extension`
		case `associatedtype`
		case `macro`
	}

	var attributes: Set<Attribute> = .init()
	var decorators: Set<Decorator> = .init()
	var kind: Kind = .unknown
	var isFinal: Bool = false
	var isOpen: Bool = false
	var name: String = ""

	var conformances = [String]()

	// includes `var`, `let`, and `func`
	var members = [Member]()

	// includes `enum`, `struct`, `class`, extension`, and `associatedtype`
	var nestedTypes = [NamedType]()

	var description: String {
"""
------
    attributes: \(attributes)
    final > '\(isFinal)' || open > '\(isOpen)' for kind > '\(kind)' named > '\(name)'
    conformances: \(conformances.joined(separator: ", "))
    has:
\(members)
------
"""
	}
}

// MARK: - Swift Protocol Conformances

extension NamedType: Codable, CustomStringConvertible, Hashable, Sendable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}

	static func ==(lhs: NamedType, rhs: NamedType) -> Bool {
		lhs.name == rhs.name
	}
}

// MARK: - Custom Protocol Conformances

extension NamedType: Attributed, Decorated, Named, Displayable {
	var developerFacingValue: String {
		let attributes = attributes.sorted { $0.name > $1.name }.map { $0.developerFacingValue }.joined(separator: " ")

		var conformances = conformances.sorted().joined(separator: ", ")
		if !conformances.isEmpty {
			conformances = ": \(conformances)"
		}

		let openString = isOpen ? "open " : ""
		let finalString = isFinal ? "final " : ""

		return "\(attributes) \(openString)\(finalString)\(kind.rawValue) \(name)\(conformances)".trimmingCharacters(in: .whitespaces)
	}
}
