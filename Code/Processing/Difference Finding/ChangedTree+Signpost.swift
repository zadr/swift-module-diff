import Foundation
import os

private struct Signpost {
	let name: StaticString
	let id: OSSignpostID
	let state: OSSignpostIntervalState
}

private let signposter = OSSignposter()

// Create static signposts for each operation
private let signpostingSignpost = Signpost(
	name: "signposting",
	id: signposter.makeSignpostID(),
	state: signposter.beginInterval("signposting", id: signposter.makeSignpostID())
)
private let platformSignpost = Signpost(
	name: "platform",
	id: signposter.makeSignpostID(),
	state: signposter.beginInterval("platform", id: signposter.makeSignpostID())
)
private let architectureSignpost = Signpost(
	name: "architecture",
	id: signposter.makeSignpostID(),
	state: signposter.beginInterval("architecture", id: signposter.makeSignpostID())
)
private let frameworkSignpost = Signpost(
	name: "framework",
	id: signposter.makeSignpostID(),
	state: signposter.beginInterval("framework", id: signposter.makeSignpostID())
)
private let dependencySignpost = Signpost(
	name: "dependency",
	id: signposter.makeSignpostID(),
	state: signposter.beginInterval("dependency", id: signposter.makeSignpostID())
)
private let typeSignpost = Signpost(
	name: "type",
	id: signposter.makeSignpostID(),
	state: signposter.beginInterval("type", id: signposter.makeSignpostID())
)
private let memberSignpost = Signpost(
	name: "member",
	id: signposter.makeSignpostID(),
	state: signposter.beginInterval("member", id: signposter.makeSignpostID())
)

extension ChangedTree {
	static func signpostVisitor(from fromVersion: Version, to toVersion: Version) -> ChangeVisitor {
		ChangeVisitor(
			willBegin: {
				_ = signposter.beginInterval(signpostingSignpost.name, id: signpostingSignpost.id)
			},
			didEnd: { _ in
				signposter.endInterval(signpostingSignpost.name, signpostingSignpost.state)
			},
			willVisitPlatform: { _ in
				_ = signposter.beginInterval(platformSignpost.name, id: platformSignpost.id)
			},
			didVisitPlatform: { _ in
				signposter.endInterval(platformSignpost.name, platformSignpost.state)
			},
			willVisitArchitecture: { _ in
				_ = signposter.beginInterval(architectureSignpost.name, id: architectureSignpost.id)
			},
			didVisitArchitecture: { _ in
				signposter.endInterval(architectureSignpost.name, architectureSignpost.state)
			},
			willVisitFramework: { _ in
				_ = signposter.beginInterval(frameworkSignpost.name, id: frameworkSignpost.id)
			},
			didVisitFramework: { _ in
				signposter.endInterval(frameworkSignpost.name, frameworkSignpost.state)
			},
			willVisitDependency: { _ in
				_ = signposter.beginInterval(dependencySignpost.name, id: dependencySignpost.id)
			},
			didVisitDependency: { _ in
				signposter.endInterval(dependencySignpost.name, dependencySignpost.state)
			},
			willVisitNamedType: { _ in
				_ = signposter.beginInterval(typeSignpost.name, id: typeSignpost.id)
			},
			didVisitNamedType: { _ in
				signposter.endInterval(typeSignpost.name, typeSignpost.state)
			},
			willVisitMember: { _ in
				_ = signposter.beginInterval(memberSignpost.name, id: memberSignpost.id)
			},
			didVisitMember: { _ in
				signposter.endInterval(memberSignpost.name, memberSignpost.state)
			}
		)
	}
}
