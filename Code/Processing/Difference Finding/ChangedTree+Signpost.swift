import Foundation
import os

extension StaticString: Hashable, Equatable {
	public static func ==(lhs: StaticString, rhs: StaticString) -> Bool {
		var isEqual = false
		lhs.withUTF8Buffer { lhsBytes in
			rhs.withUTF8Buffer { rhsBytes in
				if lhsBytes.count != rhsBytes.count {
					return
				}

				isEqual = (0..<lhsBytes.count).reduce(true) { $0 && lhsBytes[$1] == lhsBytes[$1] }
			}
		}
		return isEqual
	}

	public func hash(into hasher: inout Hasher) {
		withUTF8Buffer { bytes in
			bytes.withUnsafeBytes { unsafeBytes in
				hasher.combine(bytes: unsafeBytes)
			}
		}
	}
}

extension ChangedTree {
	static func signpostVisitor(from fromVersion: Version, to toVersion: Version) -> ChangeVisitor {
		let signposter = OSSignposter()
		var signpostIDCache = [StaticString: OSSignpostID]()
		var signpostStateCache = [StaticString: OSSignpostIntervalState]()

		func beginSignpost(_ name: StaticString) {
			let id = signposter.makeSignpostID()
			signpostIDCache[name] = id
			signpostStateCache[name] = signposter.beginInterval(name, id: id)
		}

		func endSignpost(_ name: StaticString) {
			let id = signpostIDCache[name]!
			let state = signposter.beginInterval(name, id: id)
			signposter.endInterval(name, state)
		}

		return ChangeVisitor(
			willBegin: {
				beginSignpost("signposting")
			},
			didEnd: { _ in
				endSignpost("signposting")
			},
			willVisitPlatform: { _ in
				beginSignpost("platform")
			},
			didVisitPlatform: { _ in
				endSignpost("platform")
			},
			willVisitArchitecture: { _ in
				beginSignpost("architecture")
			},
			didVisitArchitecture: { _ in
				endSignpost("architecture")
			},
			willVisitFramework: { _ in
				beginSignpost("framework")
			},
			didVisitFramework: { _ in
				endSignpost("framework")
			},
			willVisitDependency: { _ in
				beginSignpost("dependency")
			},
			didVisitDependency: { _ in
				endSignpost("dependency")
			},
			willVisitNamedType: { _ in
				beginSignpost("type")
			},
			didVisitNamedType: { _ in
				endSignpost("type")
			},
			willVisitMember: { _ in
				beginSignpost("member")
			},
			didVisitMember: { _ in
				endSignpost("member")
			}
		)
	}
}
