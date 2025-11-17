import Foundation

struct Attribute {
	var name: String = ""
	var parameters: [Parameter] = []

	private var _cachedDeveloperFacingValue: String?

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
		if let cached = _cachedDeveloperFacingValue {
			return cached
		}

		let start = "@\(name)"
		let end = parameters.map { $0.developerFacingValue }.joined(separator: ", ")
		let result = end.isEmpty ? start : start + "(\(end))"
		return result
	}

	mutating func cacheDeveloperFacingValue() {
		_cachedDeveloperFacingValue = developerFacingValue
	}

	/// Returns a normalized version of this attribute filtered for the given platform.
	/// For @available attributes, returns nil if it doesn't apply to the target platform,
	/// otherwise returns a version with only relevant parameters.
	/// For other attributes, returns the attribute unchanged.
	func normalized(for platformName: String) -> Attribute? {
		guard name == "available" else { return self }

		let targetPlatform = platformName.lowercased()

		// Define all known platforms
		let allPlatforms = Set(["ios", "macos", "tvos", "watchos", "visionos", "maccatalyst"])

		// Check if this @available mentions the target platform or is platform-agnostic (has "*")
		let mentionedPlatforms = parameters.map { $0.name.lowercased() }.filter { allPlatforms.contains($0) }
		let hasWildcard = parameters.contains { $0.name == "*" }

		// If it only mentions other platforms (not the target), filter it out entirely
		if !mentionedPlatforms.isEmpty && !mentionedPlatforms.contains(targetPlatform) && !hasWildcard {
			return nil
		}

		var normalized = self
		normalized.parameters = parameters.filter { param in
			let paramName = param.name.lowercased()

			// Keep if it's the target platform
			if paramName == targetPlatform {
				return true
			}

			// Keep wildcards and special markers
			if paramName == "*" || paramName == "unavailable" {
				return true
			}

			// Keep non-platform parameters (introduced, deprecated, obsoleted, message, renamed)
			if !allPlatforms.contains(paramName) {
				return true
			}

			// Filter out other platforms
			return false
		}

		return normalized
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
