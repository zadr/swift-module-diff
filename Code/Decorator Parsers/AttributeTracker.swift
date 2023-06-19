import Foundation
import SwiftSyntax

class AttributeTracker: SyntaxVisitor, AnyTypeParser {
	var value = Attribute()

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
		value.name = ParseAnyType<DeclTypeNameTracker>(node: node.attributeName).run()

		if let argument = node.argument, case .token(let tokenSyntax) = argument {
			var parameter = Parameter()
			parameter.name = tokenSyntax.text
			value.parameters.append(parameter)
		}

		return super.visit(node)
	}

	override func visit(_ node: TupleExprElementSyntax) -> SyntaxVisitorContinueKind {
		if let name = node.expression.as(IdentifierExprSyntax.self)?.identifier.text {
			var parameter = Parameter()
			parameter.name = name
			value.parameters.append(parameter)
		}
		return super.visit(node)
	}

	override func visit(_ node: ObjCSelectorPieceSyntax) -> SyntaxVisitorContinueKind {
		if let nameNode = node.name?.text {
			var parameter = Parameter()
			parameter.name = nameNode
			value.parameters.append(parameter)
		}
		return super.visit(node)
	}
}
