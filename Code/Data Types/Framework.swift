import Foundation

struct Framework: Hashable, CustomStringConvertible {
	var attributes: Set<Attribute> = .init()
	var availabilities = [Availability]()
	var dependencies = [String]()
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
