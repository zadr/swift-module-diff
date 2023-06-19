import Foundation
import SwiftSyntax

class EnumCaseTracker: SyntaxVisitor, AnyTypeParser {
	var value = Member()

	required init() {
		self.value.kind = .case
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
		let attribute = ParseAnyType<AttributeTracker>(node: node).run()
		if attribute.name != "available" {
			value.attributes.insert(attribute)
		}
		return super.visit(node)
	}

	override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
		value.kind = .case
		value.name = node.elements.first!.identifier.text
		return super.visit(node)
	}

	override func visit(_ node: EnumCaseParameterSyntax) -> SyntaxVisitorContinueKind {
		var parameter = Parameter()
		if let firstName = node.firstName {
			parameter.name = firstName.text + (node.secondName != nil ? " " + node.secondName!.text : "")
		}
		parameter.type = ParseAnyType<DeclTypeNameTracker>(node: node.type).run()
		parameter.isInout = ParseAnyType<InoutTracker>(node: node.type).run()

		value.parameters.append(parameter)
		return super.visit(node)
	}
}
