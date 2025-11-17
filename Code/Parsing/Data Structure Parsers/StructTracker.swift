import Foundation
import SwiftSyntax

class StructTracker: SyntaxVisitor, AnyTypeParser {
	var value = NamedType()

	required init() {
		value.kind = .struct
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
		if case .keyword(.package) = node.name.tokenKind {
			value.decorators.insert(.package)
		}
		return super.visit(node)
	}

	override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
		if !value.name.isEmpty {
			return .skipChildren
		}

		value.name = node.name.text

		let generics = GenericsTracker(parametersNode: node.genericParameterClause, requirementsNode: node.genericWhereClause).run()
		value.generics += generics.parameters
		value.genericConstraints += generics.constraints

		value.attributes += node.attributes.map { ParseAnyType<AttributeTracker>(node: $0).run() }

		return super.visit(node)
	}

	override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseAnyType<InitializerTracker>(node: node).run()
		value.members.append(member)
		return super.visit(node)
	}

	override func visit(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
		var member = Member()
		member.name = "deinit" // ~Copyable types may have deinitializers
		value.members.append(member)
		return super.visit(node)
	}

	override func visit(_ node: InheritedTypeListSyntax) -> SyntaxVisitorContinueKind {
		value.conformances = ParseAnyType<InheritanceTracker>(node: node).run()
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
