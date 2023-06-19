import Foundation
import SwiftSyntax

class TypealiasTracker: SyntaxVisitor, AnyTypeParser {
	var value = Member()

	required init() {
		self.value.kind = .typealias
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
		   let attribute = ParseAnyType<AttributeTracker>(node: node).run()
		   if attribute.name != "available" {
			   value.attributes.insert(attribute)
		   }
		   return super.visit(node)
	   }

	override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
		value.name = node.identifier.text
		return super.visit(node)
	}

	override func visit(_ node: TypeInitializerClauseSyntax) -> SyntaxVisitorContinueKind {
		value.returnType = ParseAnyType<DeclTypeNameTracker>(node: node.value).run()
		return super.visit(node)
	}
}
