import Foundation

struct NamedType {
	enum Kind: String, Codable, Hashable {
		case unknown
		case `class`
		case `enum`
		case `struct`
		case `protocol`
		case `extension`
		case `associatedtype`
	}

	var attributes: Set<Attribute> = .init()
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

extension NamedType: Attributed, Named, Displayable {
	var developerFacingName: String {
		let attributes = self.attributes.sorted { $0.name > $1.name }.map { $0.developerFacingName }.joined(separator: " ")

		var conformances = self.conformances.sorted().joined(separator: ", ")
		if !conformances.isEmpty {
			conformances = ": \(conformances)"
		}

		let openString = isOpen ? "open " : ""
		let finalString = isFinal ? "final " : ""

		return "\(attributes) \(openString)\(finalString)\(kind.rawValue) \(name)\(conformances)".trimmingCharacters(in: .whitespaces)
	}
}
