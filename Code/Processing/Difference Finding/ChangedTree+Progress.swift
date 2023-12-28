import Foundation

extension ChangedTree {
	static func progressVisitor() -> ChangeVisitor {
		ChangeVisitor(willVisitPlatform: { change in
			if change.isNotUnchanged {
				print("\t\tPlatform: \(change.kind) > \(change.any.name)")
			} else {
				print("\t\tPlatform: \(change.any.name)")
			}
		}, willVisitArchitecture: { change in
			if change.isNotUnchanged {
				print("\t\tArchitecture: \(change.kind) > \(change.any.name)")
			} else {
				print("\t\tArchitecture: \(change.any.name)")
			}
		}, willVisitFramework: { change in
			if change.isNotUnchanged {
				print("\t\tFramework: \(change.kind) > \(change.any.name)")
			} else {
				print("\t\tFramework: \(change.any.name)")
			}
		}, willVisitDependency: { change in
			if change.isNotUnchanged {
				print("\t\t\t\(change.kind) > \(change.any.developerFacingValue)")
			}
		}, willVisitNamedType: { change in
			if change.isNotUnchanged {
				print("\t\t\t\(change.kind) > \(change.any.developerFacingValue)")
			}
		}, willVisitMember: { change in
			if change.isNotUnchanged {
				print("\t\t\t\(change.kind) > \(change.any.developerFacingValue)")
			}
		})
	}
}
