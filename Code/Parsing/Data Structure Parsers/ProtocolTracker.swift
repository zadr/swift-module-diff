import Foundation
import SwiftSyntax

class ProtocolTracker: SyntaxVisitor, AnyTypeParser {
	var value = NamedType()

	required init() {
		value.kind = .protocol
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
		if ParseDecl<DeclTracker>(node: node).run(keyword: .package) {
			value.decorators.insert(.package)
		}
		return super.visit(node)
	}

	override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
		value.name = node.name.text

		// Extract primary associated types (Swift 5.7+)
		if let primaryTypes = node.primaryAssociatedTypeClause {
			value.primaryAssociatedTypes = primaryTypes.primaryAssociatedTypes.map { $0.name.text }
		}

		let generics = GenericsTracker(parametersNode: nil, requirementsNode: node.genericWhereClause).run()
		value.generics += generics.parameters
		value.genericConstraints += generics.constraints

		value.attributes += node.attributes.map { ParseAnyType<AttributeTracker>(node: $0).run() }

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

	override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseAnyType<TypeAliasTracker>(node: node).run()
		value.members.append(member)
		return super.visit(node)
	}

	override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseAnyType<SubscriptTracker>(node: node).run()
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
