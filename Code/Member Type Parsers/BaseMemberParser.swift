import Foundation
import SwiftParser
import SwiftSyntax

protocol MemberParser {
	static var kind: Member.Kind { get }
	var member: Member { get }
	init()
}

extension MemberParser where Self: SyntaxVisitor {}

struct ParseMember<T: SyntaxVisitor & MemberParser> {
	let node: any SyntaxProtocol

	init(node: any SyntaxProtocol) {
		self.node = node
	}

	func run() -> Member {
		autoreleasepool {
			let tracker = T()
			tracker.walk(node)

			var member = tracker.member

			// for var decl's: avoid overwriting `kind = .let`
			if member.kind == .unknown {
				member.kind = T.kind
			}

			return member
		}
	}
}
