import Foundation

extension Summarizer {
	static func consoleVisitor() -> ChangeVisitor {
		ChangeVisitor(willVisitPlatform: { change in
			print("Platform: \(change.kind) > \(change.any.name)")
		}, willVisitArchitecture: { change in
			print("\tArchitecture: \(change.kind) > \(change.any.name)")
		}, willVisitFramework: { change in
			ifNotUnchanged(change: change) {
				print("\t\tFramework: \(change.kind) > \(change.any.name)")
			}
		}, willVisitImport: { change in
			ifNotUnchanged(change: change) {
				print("\t\t\t\(change.kind) > \(change.any.developerFacingName)")
			}
		}, willVisitDataType: { change in
			ifNotUnchanged(change: change) {
				print("\t\t\t\(change.kind) > \(change.any.developerFacingName)")
			}
		}, willVisitMember: { change in
			ifNotUnchanged(change: change) {
				print("\t\t\t\(change.kind) > \(change.any.developerFacingName)")
			}
		})
	}
}
