import Foundation
import SwiftSyntax

class ProtocolTracker: SyntaxVisitor, AnyTypeParser {
	var value = NamedType()

	required init() {
		value.kind = .protocol
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
		let attribute = ParseAnyType<AttributeTracker>(node: node).run()
		value.attributes.insert(attribute)
		return super.visit(node)
	}

	override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
		value.name = node.name.text
		return super.visit(node)
	}

	override func visit(_ node: InheritedTypeListSyntax) -> SyntaxVisitorContinueKind {
		value.conformances = ParseAnyType<InheritanceTracker>(node: node).run()
		return super.visit(node)
	}

	override func visit(_ node: AssociatedTypeDeclSyntax) -> SyntaxVisitorContinueKind {
		let nestedType = ParseAnyType<AssociatedTypeTracker>(node: node).run()
		value.nestedTypes.append(nestedType)
		return super.visit(node)
	}

	override func visit(_ node: OperatorDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseAnyType<OperatorTracker>(node: node).run()
		value.members.append(member)
		return super.visit(node)
	}

	override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseAnyType<TypeAliasTracker>(node: node).run()
		value.members.append(member)
		return super.visit(node)
	}

	override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseAnyType<FunctionTracker>(node: node).run()
		value.members.append(member)
		return super.visit(node)
	}

	override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
		let members = ParseAnyTypeCollection<VariableTracker>(node: node).run()
		value.members += members
		return super.visit(node)
	}
}
