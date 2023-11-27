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

	var name: String {
		switch self {
		case .removed(let old, _), .modified(let old, _), .unchanged(let old, _), .added(let old, _):
			old.name
		}
	}

	/// Find differences between two sets, e.g. any platforms that were introduced or removed across packages, such as **visionOS** being introduced
	/// architectures that were introduced, modified, or removed across packages like _armv6_ being removed or _arm64_ being added,
	/// or modifications like a type becoming `Sendable`.
	static func differences<U: Named & Equatable & Hashable>(from old: any Sequence<U>, to new: any Sequence<U>) -> [Change<U>] {
		func calculateModifiedOrUnchanged(between old: U, and new: U) -> Change<U> {
			precondition(old.name == new.name)

			if let oldAD = old as? Attributed & Decorated, let newAD = new as? Attributed & Decorated {
				if oldAD.attributes == newAD.attributes && oldAD.decorators == newAD.decorators {
					return .unchanged(old, new)
				}
				return .modified(old, new)
			}

			if let oldA = old as? Attributed, let newA = new as? Attributed {
				if oldA.attributes == newA.attributes {
					return .unchanged(old, new)
				}

				return .modified(old, new)
			}

			// no attributes + no decorators = same name but nothing else to check against
			return .unchanged(old, new)
		}

		let oldSet = Set(old)
		let newSet = Set(new)
		var results = [Change<U>]()
		for value in oldSet {
			if !newSet.contains(value) {
				results.append(.removed(value, value))
			} else {
				results.append(calculateModifiedOrUnchanged(between: value, and: value))
			}
		}
		for value in newSet {
			if !oldSet.contains(value) {
				results.append(.added(value, value))
			}
			// else { already diff already calculated from old iteration }
		}

		return results
	}
}
