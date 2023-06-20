import Foundation

struct Framework: Codable, CustomStringConvertible, Hashable, Sendable {
	var attributes: Set<Attribute> = .init()
	var availabilities = [Availability]()
	var dependencies = [Import]()
	var dataTypes = [DataType]()
	var members = [Member]()
	var name = ""

	var description: String {
"""
------
    | -- name: \(name) |
    | attributes: \(attributes)
    | availability: \(availabilities) |
    | dependencies: \(dependencies.count): \(dependencies) |
    | types: \(dataTypes.count):
\(dataTypes) |
	| members: \(members.count):
\(members) |
------
"""
	}
}
