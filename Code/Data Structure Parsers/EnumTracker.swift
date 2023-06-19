import Foundation
import SwiftSyntax

class EnumTracker: SyntaxVisitor, AnyTypeParser {
	var value = DataType()

	required init() {
		self.value.kind = .enum
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AvailabilityVersionRestrictionSyntax) -> SyntaxVisitorContinueKind {
		value.availabilities += ParseAnyType<AvailabilityTracker>(node: node).run()
		return super.visit(node)
	}

	override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
		let attribute = ParseAnyType<AttributeTracker>(node: node).run()
		if attribute.name != "available" {
			value.attributes.insert(attribute)
		}
		return super.visit(node)
	}

	override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
		value.name = node.identifier.text
		return super.visit(node)
	}

	override func visit(_ node: InheritedTypeListSyntax) -> SyntaxVisitorContinueKind {
		value.conformances = ParseAnyType<InheritanceTracker>(node: node).run()
		return super.visit(node)
	}

	override func visit(_ node: OperatorDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseAnyType<OperatorTracker>(node: node).run()
		value.members.append(member)
		return super.visit(node)
	}

	override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
		let t = ParseAnyType<TypealiasTracker>(node: node).run()
		value.members.append(t)
		return super.visit(node)
	}

	override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
		let members = ParseMultiTypeCollection<EnumCaseTracker>(node: node).run()
		value.members += members
		return super.visit(node)
	}

	override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseAnyType<FunctionTracker>(node: node).run()
		value.members.append(member)
		return super.visit(node)
	}

	override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
		let members = ParseMultiTypeCollection<VariableTracker>(node: node).run()
		value.members += members
		return super.visit(node)
	}
}
