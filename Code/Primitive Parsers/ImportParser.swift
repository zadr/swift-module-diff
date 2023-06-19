import Foundation
import SwiftSyntax

class ImportTracker: SyntaxVisitor, PrimitiveParser {
	typealias Value = Import
	
	var value = Value()
	
	required init() {
		super.init(viewMode: .sourceAccurate)
	}
	
	override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
		let attribute = ParsePrimitive<AttributeTracker>(node: node).run()
		if attribute.name != "available" {
			value.attributes.insert(attribute)
		}
		return super.visit(node)
	}
	
	override func visit(_ node: ImportPathComponentSyntax) -> SyntaxVisitorContinueKind {
		value.name = value.name.isEmpty ? node.name.text : node.name.text + "." + value.name
		return super.visit(node)
	}
}
