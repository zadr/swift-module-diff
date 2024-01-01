import Foundation

struct Attribute {
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

extension Attribute {
	var developerFacingValue: String {
		let start = "@\(name)"
		let end = parameters.map { $0.developerFacingValue }.joined(separator: ", ")
		return end.isEmpty ? start : start + "(\(end))"
	}
}

// MARK: - Swift Protocol Conformances

extension Attribute: Codable, CustomStringConvertible, Equatable, Hashable, Sendable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}

	static func ==(lhs: Attribute, rhs: Attribute) -> Bool {
		lhs.name == rhs.name
	}
}
