import Foundation

extension Summarizer {
	static func consoleVisitor() -> ChangeVisitor {
		ChangeVisitor(willVisitPlatform: { change in
			print("Platform: \(change.kind) > \(change.name)")
		}, willVisitArchitecture: { change in
			print("\tArchitecture: \(change.kind) > \(change.name)")
		}, willVisitFramework: { change in
			print("\t\tFramework: \(change.kind) > \(change.name)")
		}, willVisitImport: { change in
			print("\t\t\tImport: \(change.kind) > \(change.name)")
		}, willVisitDataType: { change in
			print("\t\t\tNamed Type: \(change.kind) > \(change.name)")
		}, willVisitMember: { change in
			print("\t\t\tMember: \(change.kind) > \(change.name)")
		})
	}
}
