import Foundation

struct Import: Codable, CustomStringConvertible, Hashable {
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
