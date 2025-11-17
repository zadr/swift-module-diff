import Foundation
import SwiftSyntax

class ExtensionTracker: SyntaxVisitor, AnyTypeParser {
	var value = NamedType()

	required init() {
		value.kind = .extension
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
		if !value.name.isEmpty {
			return .skipChildren
		}

		value.name = ParseAnyType<TypeNameTracker>(node: node.extendedType).run()

		let generics = GenericsTracker(parametersNode: nil, requirementsNode: node.genericWhereClause).run()
		value.generics += generics.parameters
		value.genericConstraints += generics.constraints

		value.attributes += node.attributes.map { ParseAnyType<AttributeTracker>(node: $0).run() }

		return super.visit(node)
	}

	override func visit(_ node: InheritedTypeListSyntax) -> SyntaxVisitorContinueKind {
		value.conformances = ParseAnyType<InheritanceTracker>(node: node).run().sorted()
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
