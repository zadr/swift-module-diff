import Foundation

struct Framework {
	var attributes: [Attribute] = []
	var dependencies = [Dependency]()
	var namedTypes = [NamedType]()
	var members = [Member]()
	var precedenceGroups = [PrecedenceGroup]()
	var name = ""

	var description: String {
"""
------
    | name: \(name) |
    | attributes: \(attributes)
    | dependencies: \(dependencies.count): \(dependencies) |
    | types: \(namedTypes.count):
\(namedTypes) |
	| members: \(members.count):
\(members) |
	| precedenceGroups: \(precedenceGroups.count):
\(precedenceGroups)
------
"""
	}
}

// MARK: - Swift Protocol Conformances

extension Framework: Codable, CustomStringConvertible, Equatable, Hashable, Sendable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}

	static func ==(lhs: Framework, rhs: Framework) -> Bool {
		lhs.name == rhs.name
	}
}
