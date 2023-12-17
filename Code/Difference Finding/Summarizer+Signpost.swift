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

extension Summarizer {
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
			willVisitPlatform: { change in
				beginSignpost("platform")
			},
			didVisitPlatform: { change in
				endSignpost("platform")
			},
			willVisitArchitecture: { change in
				beginSignpost("architecture")
			},
			didVisitArchitecture: { change in
				endSignpost("architecture")
			},
			willVisitFramework: { change in
				beginSignpost("framework")
			},
			didVisitFramework: { change in
				endSignpost("framework")
			},
			willVisitDependency: { change in
				beginSignpost("dependency")
			},
			didVisitDependency: { change in
				endSignpost("dependency")
			},
			willVisitNamedType: { change in
				beginSignpost("type")
			},
			didVisitNamedType: { change in
				endSignpost("type")
			},
			willVisitMember: { change in
				beginSignpost("member")
			},
			didVisitMember: { change in
				endSignpost("member")
			}
		)
	}
}
