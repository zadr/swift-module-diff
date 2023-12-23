import Foundation
import SwiftSyntax

class MacroTracker: SyntaxVisitor, AnyTypeParser {
	var value = NamedType()

	required init() {
		value.kind = .macro
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
		let attribute = ParseAnyType<AttributeTracker>(node: node).run()
		value.attributes.insert(attribute)
		return super.visit(node)
	}

	override func visit(_ node: MacroDeclSyntax) -> SyntaxVisitorContinueKind {
		value.name = node.name.text
		return super.visit(node)
	}
}
