import Foundation

struct Parameter: Codable, CustomStringConvertible, Hashable {
	var name: String = ""
	var type: String = ""
	var isInout: Bool = false
	var attributes: Set<Attribute> = .init()

	var description: String {
"""
------
    name: \(name)
    type: \(type)
    isInout: \(isInout)
    attributes: \(attributes)
------
"""
	}
}
