import Foundation

struct Framework {
	var attributes: Set<Attribute> = .init()
	var dependencies = [Import]()
	var dataTypes = [NamedType]()
	var members = [Member]()
	var name = ""

	var description: String {
"""
------
    | -- name: \(name) |
    | attributes: \(attributes)
    | dependencies: \(dependencies.count): \(dependencies) |
    | types: \(dataTypes.count):
\(dataTypes) |
	| members: \(members.count):
\(members) |
------
"""
	}
}

// MARK: - Swift Protocol Conformances

extension Framework: Codable, CustomStringConvertible, Hashable, Sendable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}

	static func ==(lhs: Framework, rhs: Framework) -> Bool {
		lhs.name == rhs.name
	}
}

// MARK: - Custom Protocol Conformances

extension Framework: Attributed, Named {}
