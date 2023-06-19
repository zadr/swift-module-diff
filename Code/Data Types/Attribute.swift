import Foundation

struct Attribute: Codable, CustomStringConvertible, Equatable, Hashable {
	var name: String = ""
	var parameters: [Parameter] = []

	var description: String {
"""
------
    name: \(name)
    parameters: \(parameters)
------
"""
	}
}
