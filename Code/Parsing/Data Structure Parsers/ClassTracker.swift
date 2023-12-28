import Foundation
import SwiftSyntax

class ClassTracker: SyntaxVisitor, AnyTypeParser {
	var value = NamedType()

	required init() {
		value.kind = .class
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
		value.isOpen = value.isOpen || ParseDecl<DeclTracker>(node: node).run(keyword: .open)
		value.isFinal = value.isFinal || ParseDecl<DeclTracker>(node: node).run(keyword: .final)
		return super.visit(node)
	}

	override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
		value.name = node.name.text

		let generics = GenericsTracker(parametersNode: node.genericParameterClause, requirementsNode: node.genericWhereClause).run()
		value.generics.formUnion(generics.parameters)
		value.genericConstraints.formUnion(generics.constraints)

		let attributes = node.attributes.map { ParseAnyType<AttributeTracker>(node: $0).run() }
		value.attributes.formUnion(attributes)

		return super.visit(node)
	}

	override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseAnyType<InitializerTracker>(node: node).run()
		value.members.append(member)
		return super.visit(node)
	}

	override func visit(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
		var member = Member()
		member.name = "deinit"
		value.members.append(member)
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

	override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseAnyType<TypeAliasTracker>(node: node).run()
		value.members.append(member)
		return super.visit(node)
	}

	override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
		let members = ParseAnyTypeCollection<VariableTracker>(node: node).run()
		value.members += members
		return super.visit(node)
	}

	override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseAnyType<FunctionTracker>(node: node).run()
		value.members.append(member)
		return super.visit(node)
	}
}