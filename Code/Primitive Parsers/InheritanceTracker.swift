import Foundation
import SwiftSyntax

class InheritanceTracker: SyntaxVisitor, AnyTypeParser {
	var value = [String]()

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: InheritedTypeSyntax) -> SyntaxVisitorContinueKind {
		let name = ParseAnyType<DeclTypeNameTracker>(node: node).run()
		value.append(name)
		return super.visit(node)
	}
}
