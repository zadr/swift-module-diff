import Foundation
import SwiftSyntax

class ClassTracker: SyntaxVisitor, DataTypeParser {
	static let kind: DataType.Kind = .class

	var dataType = DataType()

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
		dataType.isOpen = dataType.isOpen || ParseDecl<DeclTracker>(node: node).run(keyword: .open)
		dataType.isFinal = dataType.isFinal || ParseDecl<DeclTracker>(node: node).run(keyword: .final)
		return super.visit(node)
	}

	override func visit(_ node: AvailabilityVersionRestrictionSyntax) -> SyntaxVisitorContinueKind {
		dataType.availabilities += ParsePrimitive<AvailabilityTracker>(node: node).run()
		return super.visit(node)
	}

	override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
		let attribute = ParsePrimitive<AttributeTracker>(node: node).run()
		if attribute.name != "available" {
			dataType.attributes.insert(attribute)
		}
		return super.visit(node)
	}

	override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
		dataType.name = node.identifier.text
		return super.visit(node)
	}

	override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
		var member = ParseMember<FunctionTracker>(node: node).run()
		member.name = "init"

		if node.optionalMark?.tokenKind == .postfixQuestionMark {
			member.name = member.name + "?"
		} else if node.optionalMark?.tokenKind == .exclamationMark {
			member.name = member.name + "!"
		}

		dataType.members.append(member)

		return super.visit(node)
	}

	override func visit(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
		var member = Member()
		member.name = "deinit"
		dataType.members.append(member)
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
		let member = ParseMember<TypealiasTracker>(node: node).run()
		dataType.members.append(member)
		return super.visit(node)
	}

	override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseMember<VariableTracker>(node: node).run()
		dataType.members.append(member)
		return super.visit(node)
	}

	override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseMember<FunctionTracker>(node: node).run()
		dataType.members.append(member)
		return super.visit(node)
	}
}
