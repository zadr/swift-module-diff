import Foundation

struct Dependency {
	var name: String = ""
	var attributes: [Attribute] = []

	var description: String {
"""
------
	name: \(name)
	attributes: \(attributes)
------
"""
	}
}

extension Dependency {
	var developerFacingValue: String {
		attributes.map { $0.developerFacingValue }.joined(separator: " ") + " import \(name)"
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

