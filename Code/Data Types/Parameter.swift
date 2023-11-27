import Foundation

struct Parameter {
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

// MARK: - Swift Protocol Conformances

extension Parameter: Codable, CustomStringConvertible, Hashable, Sendable {}

// MARK: - Custom Protocol Conformances

extension Parameter: Attributed, Named {}
