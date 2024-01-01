import Foundation

extension String {
	func dropAnySubstring(in set: [String]) -> String {
		var copy = self
		for substring in set {
			let ranges = copy.ranges(of: substring).reversed()
			for range in ranges {
				copy = copy.replacingCharacters(in: range, with: "")
			}
		}
		return copy
	}
}

extension NamedType {
	func dropAnySubstring(in set: [String]) -> NamedType {
		var copy = self
		copy.name = copy.name.dropAnySubstring(in: set)
		copy.generics = copy.generics.dropAnySubstring(in: set)
		copy.genericConstraints = copy.genericConstraints.dropAnySubstring(in: set)
		copy.members = copy.members.dropAnySubstring(in: set)
		copy.nestedTypes = copy.nestedTypes.dropAnySubstring(in: set)
		return copy
	}
}

extension Array where Element == NamedType {
	func dropAnySubstring(in set: [String]) -> [Element] {
		map { $0.dropAnySubstring(in: set) }
	}
}

extension Member {
	func dropAnySubstring(in set: [String]) -> Member {
		var copy = self
		copy.name = copy.name.dropAnySubstring(in: set)
		copy.parameters = copy.parameters.dropAnySubstring(in: set)
		copy.returnType = copy.returnType.dropAnySubstring(in: set)
		copy.generics = copy.generics.dropAnySubstring(in: set)
		copy.genericConstraints = copy.genericConstraints.dropAnySubstring(in: set)
		return copy
	}
}

extension Array where Element == Member {
	func dropAnySubstring(in set: [String]) -> [Element] {
		map { $0.dropAnySubstring(in: set) }
	}
}

extension Parameter {
	func dropAnySubstring(in set: [String]) -> Parameter {
		var copy = self
		copy.type = copy.type.dropAnySubstring(in: set)
		copy.generics = copy.generics.dropAnySubstring(in: set)
		copy.genericConstraints = copy.genericConstraints.dropAnySubstring(in: set)
		return copy
	}
}

extension Array where Element == Parameter {
	func dropAnySubstring(in set: [String]) -> [Element] {
		map { $0.dropAnySubstring(in: set) }
	}
}
