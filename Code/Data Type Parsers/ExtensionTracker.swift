import Foundation
import SwiftSyntax

class ExtensionTracker: SyntaxVisitor, AnyTypeParser {
	var value = DataType()

	required init() {
		self.value.kind = .extension
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

	override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
		value.name = ParseAnyType<DeclTypeNameTracker>(node: node.extendedType).run()
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
		let member = ParseAnyType<TypealiasTracker>(node: node).run()
		value.members.append(member)
		return super.visit(node)
	}

	override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseAnyType<FunctionTracker>(node: node).run()
		value.members.append(member)
		return super.visit(node)
	}

	override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseAnyType<VariableTracker>(node: node).run()
		value.members.append(member)
		return super.visit(node)
	}
}
