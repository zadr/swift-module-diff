import Foundation
import SwiftSyntax

class ClassTracker: SyntaxVisitor, AnyTypeParser {
	var value = DataType()

	required init() {
		self.value.kind = .class
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
		value.isOpen = value.isOpen || ParseDecl<DeclTracker>(node: node).run(keyword: .open)
		value.isFinal = value.isFinal || ParseDecl<DeclTracker>(node: node).run(keyword: .final)
		return super.visit(node)
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

	override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
		value.name = node.identifier.text
		return super.visit(node)
	}

	override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
		var member = ParseAnyType<FunctionTracker>(node: node).run()
		member.name = "init"

		if node.optionalMark?.tokenKind == .postfixQuestionMark {
			member.name = member.name + "?"
		} else if node.optionalMark?.tokenKind == .exclamationMark {
			member.name = member.name + "!"
		}

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

	override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseAnyType<TypealiasTracker>(node: node).run()
		value.members.append(member)
		return super.visit(node)
	}

	override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
		let members = ParseMultiTypeCollection<VariableTracker>(node: node).run()
		value.members += members
		return super.visit(node)
	}

	override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		let member = ParseAnyType<FunctionTracker>(node: node).run()
		value.members.append(member)
		return super.visit(node)
	}
}
