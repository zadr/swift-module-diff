import Foundation

extension Summarizer {
	static func consoleVisitor() -> ChangeVisitor {
		ChangeVisitor(willVisitPlatform: { change in
			ifNotUnchanged(change: change) {
				print("\t\tPlatform: \(change.kind) > \(change.any.name)")
			} else: {
				print("\t\tPlatform: \(change.any.name)")
			}
		}, willVisitArchitecture: { change in
			ifNotUnchanged(change: change) {
				print("\t\tArchitecture: \(change.kind) > \(change.any.name)")
			} else: {
				print("\t\tArchitecture: \(change.any.name)")
			}
		}, willVisitFramework: { change in
			ifNotUnchanged(change: change) {
				print("\t\tFramework: \(change.kind) > \(change.any.name)")
			} else: {
				print("\t\tFramework: \(change.any.name)")
			}
		}, willVisitDependency: { change in
			ifNotUnchanged(change: change) {
				print("\t\t\t\(change.kind) > \(change.any.developerFacingValue)")
			}
		}, willVisitNamedType: { change in
			ifNotUnchanged(change: change) {
				print("\t\t\t\(change.kind) > \(change.any.developerFacingValue)")
			}
		}, willVisitMember: { change in
			ifNotUnchanged(change: change) {
				print("\t\t\t\(change.kind) > \(change.any.developerFacingValue)")
			}
		})
	}
}
