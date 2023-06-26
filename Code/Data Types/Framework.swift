import Foundation

struct Framework: Codable, CustomStringConvertible, Hashable, Sendable {
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
