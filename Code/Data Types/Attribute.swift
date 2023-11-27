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

// MARK: - Swift Protocol Conformances

extension Attribute: Codable, CustomStringConvertible, Equatable, Hashable, Sendable {}

// MARK: - Custom Protocol Conformances

extension Attribute: Named {}
