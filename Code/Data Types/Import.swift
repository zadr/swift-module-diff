import Foundation

struct Import {
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

// MARK: - Swift Protocol Conformances

extension Import: Codable, CustomStringConvertible, Hashable, Sendable {}

// MARK: - Custom Protocol Conformances

extension Import: Attributed, Named {}
