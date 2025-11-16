import Foundation
import os

var __dropAnySubstringCacheLock__ = OSAllocatedUnfairLock()
var __dropAnySubstringCache__ = [String: String]()

extension String {
	func dropAnySubstring(in set: [String]) -> String {
		  __dropAnySubstringCacheLock__.lock()
		  defer { __dropAnySubstringCacheLock__.unlock() }

		  if let result = __dropAnySubstringCache__[self] {
			  return result
		  }

		  let mutableCopy = NSMutableString(string: self)

		  // Combine all patterns into one regex
		  let escapedPatterns = set.map { NSRegularExpression.escapedPattern(for: $0) }
		  let pattern = escapedPatterns.joined(separator: "|")

		  guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
			  // Fallback if regex fails
			  __dropAnySubstringCache__[self] = self
			  return self
		  }

		  // Process all matches in reverse to avoid index shifting issues
		  let matches = regex.matches(in: mutableCopy as String, options: [], range: NSRange(location: 0, length: mutableCopy.length))

		  for match in matches.reversed() {
			  mutableCopy.deleteCharacters(in: match.range)
		  }

		  let result = mutableCopy as String
		  __dropAnySubstringCache__[self] = result
		  return result
	  }}

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
		copy.defaultValue = copy.defaultValue.dropAnySubstring(in: set)
		return copy
	}
}

extension Array where Element == Parameter {
	func dropAnySubstring(in set: [String]) -> [Element] {
		map { $0.dropAnySubstring(in: set) }
	}
}
