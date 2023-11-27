import Foundation

struct Dependency {
	var name: String = ""
	var attributes: Set<Attribute> = .init()

	var description: String {
"""
------
	name: \(name)
	attributes: \(attributes)
------
"""
	}
}

// MARK: - Swift Protocol Conformances

extension Dependency: Codable, CustomStringConvertible, Hashable, Sendable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}

	static func ==(lhs: Dependency, rhs: Dependency) -> Bool {
		lhs.name == rhs.name
	}
}

// MARK: - Custom Protocol Conformances

extension Dependency: Attributed, Named, Displayable {
	var developerFacingName: String {
		attributes.map { $0.developerFacingName }.joined(separator: " ") + "import \(name)"
	}
}
