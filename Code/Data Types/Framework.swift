import Foundation

struct Framework: CustomStringConvertible {
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
