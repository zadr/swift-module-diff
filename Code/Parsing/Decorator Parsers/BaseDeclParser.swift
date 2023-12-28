import Foundation
import SwiftParser
import SwiftSyntax

protocol DeclParser {
	var value: Bool { get }
	init(keyword: Keyword)
}

extension DeclParser where Self: SyntaxVisitor {}

struct ParseDecl<T: SyntaxVisitor & DeclParser> {
	let node: any SyntaxProtocol

	init(node: any SyntaxProtocol) {
		self.node = node
	}

	func run(keyword: Keyword) -> Bool {
		autoreleasepool {
			let tracker = T(keyword: keyword)
			tracker.walk(node)

			return tracker.value
		}
	}
}

class DeclTracker: SyntaxVisitor, DeclParser {
	var value = false
	let keyword: Keyword

	required init(keyword: Keyword) {
		self.keyword = keyword
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
		if node.name.tokenKind == .keyword(keyword) {
			value = true
		}
		return super.visit(node)
	}
}
