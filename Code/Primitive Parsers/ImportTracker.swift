import Foundation
import SwiftSyntax

class ImportTracker: SyntaxVisitor, AnyTypeParser {
	var value = Import()

	required init() {
		super.init(viewMode: .sourceAccurate)
	}
	
	override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
		let attribute = ParseAnyType<AttributeTracker>(node: node).run()
		value.attributes.insert(attribute)
		return super.visit(node)
	}
	
	override func visit(_ node: ImportPathComponentSyntax) -> SyntaxVisitorContinueKind {
		value.name = value.name.isEmpty ? node.name.text : node.name.text + "." + value.name
		return super.visit(node)
	}
}
