import Foundation
import SwiftParser
import SwiftSyntax

protocol DeclParser {
	var value: Bool { get }
	init(keyword: Keyword, detailKeyword: String?)
}

extension DeclParser where Self: SyntaxVisitor {}

struct ParseDecl<T: SyntaxVisitor & DeclParser> {
	let node: any SyntaxProtocol

	init(node: any SyntaxProtocol) {
		self.node = node
	}

	func run(keyword: Keyword, detailKeyword: String? = nil) -> Bool {
		let tracker = T(keyword: keyword, detailKeyword: detailKeyword)
		tracker.walk(node)
		return tracker.value
	}
}

class DeclTracker: SyntaxVisitor, DeclParser {
	var value = false
	let keyword: Keyword
	let detailKeyword: String?

	required init(keyword: Keyword, detailKeyword: String? = nil) {
		self.keyword = keyword
		self.detailKeyword = detailKeyword
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
		var matchedValue = false
		if node.name.tokenKind == .keyword(keyword) {
			matchedValue = true
		}

		var matchedDetail = false
		if let detailKeyword, let detailNode = node.detail {
			matchedDetail = detailNode.detail.tokenKind == .identifier(detailKeyword)
		} else if detailKeyword == nil {
			matchedDetail = true
		}

		value = matchedValue && matchedDetail

		return super.visit(node)
	}
}
