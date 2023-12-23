import Foundation
import SwiftSyntax

class TypeAliasTracker: SyntaxVisitor, AnyTypeParser {
	var value = Member()

	required init() {
		value.kind = .typealias
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
		   let attribute = ParseAnyType<AttributeTracker>(node: node).run()
		   value.attributes.insert(attribute)
		   return super.visit(node)
	   }

	override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
		value.name = node.name.text
		return super.visit(node)
	}

	override func visit(_ node: TypeInitializerClauseSyntax) -> SyntaxVisitorContinueKind {
		value.returnType = ParseAnyType<TypeNameTracker>(node: node.value).run()
		return super.visit(node)
	}
}
