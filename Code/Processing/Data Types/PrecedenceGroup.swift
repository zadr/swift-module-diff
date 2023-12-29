import Foundation

struct PrecedenceGroup {
	enum Associativity {
		case left
		case right
	}

	var associativity: Associativity? = nil
	var higherThan: [String] = []
	var lowerThan: [String] = []
	var assignment: Bool? = nil
	var name: String = ""
}

extension PrecedenceGroup: Codable, Comparable, Hashable, Sendable {
	static func <(lhs: PrecedenceGroup, rhs: PrecedenceGroup) -> Bool {
		lhs.name < rhs.name
	}
}
extension PrecedenceGroup.Associativity: Codable, Hashable, Sendable {}
extension PrecedenceGroup: Named {}
