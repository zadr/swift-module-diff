import Foundation

struct Framework: Codable, Hashable, CustomStringConvertible {
	var attributes: Set<Attribute> = .init()
	var availabilities = [Availability]()
	var dependencies = [Import]()
	var dataTypes = [DataType]()
	var members = [Member]()

	var description: String {
"""
------
    | availability: \(availabilities) |
    | dependencies: \(dependencies.count): \(dependencies) |
    | types: \(dataTypes.count):
\(dataTypes) |
------
"""
	}
}
