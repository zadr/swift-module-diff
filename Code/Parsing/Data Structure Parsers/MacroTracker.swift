import Foundation
import SwiftSyntax

class MacroTracker: SyntaxVisitor, AnyTypeParser {
	var value = NamedType()

	required init() {
		value.kind = .macro
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: MacroDeclSyntax) -> SyntaxVisitorContinueKind {
		value.name = node.name.text

		let generics = GenericsTracker(parametersNode: node.genericParameterClause, requirementsNode: node.genericWhereClause).run()
		value.generics += generics.parameters
		value.genericConstraints += generics.constraints

		let attributes = node.attributes.map { ParseAnyType<AttributeTracker>(node: $0).run() }
		value.attributes.formUnion(attributes)

		return super.visit(node)
	}
}
