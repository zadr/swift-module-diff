import Foundation
import SwiftSyntax

class EnumTracker: SyntaxVisitor, DataTypeParser {
	static let kind: DataType.Kind = .enum

	var dataType = DataType()

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AvailabilityVersionRestrictionSyntax) -> SyntaxVisitorContinueKind {
		dataType.availabilities += ParsePrimitive<AvailabilityTracker>(node: node).run()
		return super.visit(node)
	}

	override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
		dataType.name = node.identifier.text
		return super.visit(node)
	}

	override func visit(_ node: InheritedTypeListSyntax) -> SyntaxVisitorContinueKind {
		dataType.conformances = ParsePrimitive<InheritanceTracker>(node: node).run()
		return super.visit(node)
	}

	override func visit(_ node: OperatorDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseMember<OperatorTracker>(node: node).run()
		dataType.members.append(member)
		return super.visit(node)
	}

	override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
		let t = ParseMember<TypealiasTracker>(node: node).run()
		dataType.members.append(t)
		return super.visit(node)
	}

	override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseMember<EnumCaseTracker>(node: node).run()
		dataType.members.append(member)
		return super.visit(node)
	}

	override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseMember<FunctionTracker>(node: node).run()
		dataType.members.append(member)
		return super.visit(node)
	}

	override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseMember<VariableTracker>(node: node).run()
		dataType.members.append(member)
		return super.visit(node)
	}
}
