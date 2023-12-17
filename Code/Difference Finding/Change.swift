import Foundation

enum Change<T: Named> {
	case removed(_ old: T, _ new: T)
	case modified(_ old: T, _ new: T)
	case unchanged(_ old: T, _ new: T)
	case added(_ old: T, _ new: T)

	var kind: String {
		switch self {
		case .removed(_, _):
			"removed"
		case .modified(_, _):
			"modified"
		case .unchanged(_, _):
			"unchanged"
		case .added(_, _):
			"added"
		}
	}

	var any: T {
		switch self {
		case .removed(let old, _), .modified(let old, _), .unchanged(let old, _), .added(let old, _):
			old
		}
	}

	// MARK: - Differences

	/// Find differences between two sets, e.g. any platforms that were introduced or removed across packages, such as **visionOS** being introduced
	/// architectures that were introduced, modified, or removed across packages like _armv6_ being removed or _arm64_ being added,
	/// or modifications like a type becoming `Sendable`.
	static func differences<U: Attributed & Decorated & Named & Equatable & Hashable>(from old: any Sequence<U>, to new: any Sequence<U>) -> [Change<U>] {
		func calculateModifiedOrUnchanged(between old: U, and new: U) -> Change<U> {
			precondition(old.name == new.name)
			return (old.decorators == new.decorators && old.attributes == new.attributes) ? .unchanged(old, new) : .modified(old, new)
		}

		let oldSet = Set(old)
		let newSet = Set(new)
		var results = [Change<U>]()
		for value in oldSet {
			if !newSet.contains(value) {
				results.append(.removed(value, value))
			} else {
				let newValue = newSet.first { $0.name == value.name }!
				results.append(calculateModifiedOrUnchanged(between: value, and: newValue))
			}
		}
		for value in newSet {
			if !oldSet.contains(value) {
				results.append(.added(value, value))
			}
			// else { remove/updated/unchanged diff calculated from old iteration }
		}

		return results
	}

	/// Find differences between two sets, e.g. any platforms that were introduced or removed across packages, such as **visionOS** being introduced
	/// architectures that were introduced, modified, or removed across packages like _armv6_ being removed or _arm64_ being added,
	/// or modifications like a type becoming `Sendable`.
	static func differences<U: Attributed & Named & Equatable & Hashable>(from old: any Sequence<U>, to new: any Sequence<U>) -> [Change<U>] {
		func calculateModifiedOrUnchanged(between old: U, and new: U) -> Change<U> {
			precondition(old.name == new.name)
			return (old.attributes == new.attributes) ? .unchanged(old, new) : .modified(old, new)
		}
		let oldSet = Set(old)
		let newSet = Set(new)
		var results = [Change<U>]()
		for value in oldSet {
			if !newSet.contains(value) {
				results.append(.removed(value, value))
			} else {
				let newValue = newSet.first { $0.name == value.name }!
				results.append(calculateModifiedOrUnchanged(between: value, and: newValue))
			}
		}
		for value in newSet {
			if !oldSet.contains(value) {
				results.append(.added(value, value))
			}
			// else { remove/updated/unchanged diff calculated from old iteration }
		}

		return results
	}

	/// Find differences between two sets, e.g. any platforms that were introduced or removed across packages, such as **visionOS** being introduced
	/// architectures that were introduced, modified, or removed across packages like _armv6_ being removed or _arm64_ being added,
	/// or modifications like a type becoming `Sendable`.
	static func differences<U: Decorated & Named & Equatable & Hashable>(from old: any Sequence<U>, to new: any Sequence<U>) -> [Change<U>] {
		func calculateModifiedOrUnchanged(between old: U, and new: U) -> Change<U> {
			precondition(old.name == new.name)
			return (old.decorators == new.decorators) ? .unchanged(old, new) : .modified(old, new)
		}

		let oldSet = Set(old)
		let newSet = Set(new)
		var results = [Change<U>]()
		for value in oldSet {
			if !newSet.contains(value) {
				results.append(.removed(value, value))
			} else {
				let newValue = newSet.first { $0.name == value.name }!
				results.append(calculateModifiedOrUnchanged(between: value, and: newValue))
			}
		}
		for value in newSet {
			if !oldSet.contains(value) {
				results.append(.added(value, value))
			}
			// else { remove/updated/unchanged diff calculated from old iteration }
		}

		return results
	}

	/// Find differences between two sets, e.g. any platforms that were introduced or removed across packages, such as **visionOS** being introduced
	/// architectures that were introduced, modified, or removed across packages like _armv6_ being removed or _arm64_ being added,
	/// or modifications like a type becoming `Sendable`.
	static func differences<U: Equatable & Hashable>(from old: any Sequence<U>, to new: any Sequence<U>) -> [Change<U>] {
		func calculateModifiedOrUnchanged(between old: U, and new: U) -> Change<U> {
			return (old == new) ? .unchanged(old, new) : .modified(old, new)
		}

		let oldSet = Set(old)
		let newSet = Set(new)
		var results = [Change<U>]()
		for value in oldSet {
			if !newSet.contains(value) {
				results.append(.removed(value, value))
			} else {
				let newValue = newSet.first { $0.name == value.name }!
				results.append(calculateModifiedOrUnchanged(between: value, and: newValue))
			}
		}
		for value in newSet {
			if !oldSet.contains(value) {
				results.append(.added(value, value))
			}
			// else { remove/updated/unchanged diff calculated from old iteration }
		}

		return results
	}
}
