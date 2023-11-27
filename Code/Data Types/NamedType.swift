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
		let attributes = self.attributes.map { attribute in
			var baseName = "@" + attribute.name
			if !attribute.parameters.isEmpty {
				baseName += "("
				baseName += attribute.parameters.map {
					return $0.name + " " + $0.type
				}
				.map { $0.trimmingCharacters(in: .whitespaces) }
				.joined(separator: ", ")
				baseName += ")"
			}
			return baseName
		}.joined(separator: " ")

		var conformances = self.conformances.joined(separator: ", ")
		if !conformances.isEmpty {
			conformances = ": \(conformances)"
		}

		let openString = isOpen ? "open " : ""
		let finalString = isFinal ? "final " : ""

		return """
\(attributes)
\(openString)\(finalString)\(kind.rawValue) \(name)\(conformances) {
\(members)
}
"""
//
//------
//    attributes: \(attributes)
//    availability: \(availabilities)
//    final > '\(isFinal)' || open > '\(isOpen)' for kind > '\(kind)' named > '\(name)'
//    conformances: \(conformances.joined(separator: ", "))
//    has:
//\(members)
//------
//"""
	}
}

// MARK: - Swift Protocol Conformances

extension NamedType: Codable, CustomStringConvertible, Hashable, Sendable {}

// MARK: - Custom Protocol Conformances

extension NamedType: Attributed, Named {}
