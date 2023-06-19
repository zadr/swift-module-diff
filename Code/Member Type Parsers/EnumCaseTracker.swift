import Foundation
import SwiftSyntax

class EnumCaseTracker: SyntaxVisitor, MemberParser {
	static let kind: Member.Kind = .case

	var member = Member()

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
		let attribute = ParsePrimitive<AttributeTracker>(node: node).run()
		if attribute.name != "available" {
			member.attributes.insert(attribute)
		}
		return super.visit(node)
	}

	override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
		member.kind = .case
		member.name = node.elements.first!.identifier.text
		return super.visit(node)
	}

	override func visit(_ node: EnumCaseParameterSyntax) -> SyntaxVisitorContinueKind {
		var parameter = Parameter()
		if let firstName = node.firstName {
			parameter.name = firstName.text + (node.secondName != nil ? " " + node.secondName!.text : "")
		}
		parameter.type = ParsePrimitive<DeclTypeNameTracker>(node: node.type).run()
		parameter.isInout = ParsePrimitive<InoutTracker>(node: node.type).run()

		member.parameters.append(parameter)
		return super.visit(node)
	}
}
