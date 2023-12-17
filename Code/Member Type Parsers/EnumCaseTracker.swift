import Foundation
import SwiftSyntax

class EnumCaseTracker: SyntaxVisitor, AnyTypeCollectionParser {
	var value = Member()
	var collection = [Member]()
	
	required init() {
		self.value.kind = .case
		super.init(viewMode: .sourceAccurate)
	}
	
	override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
		let attribute = ParseAnyType<AttributeTracker>(node: node).run()
		value.attributes.insert(attribute)
		return super.visit(node)
	}
	
	override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
		value.kind = .case
		return super.visit(node)
	}

	override func visit(_ node: EnumCaseElementSyntax) -> SyntaxVisitorContinueKind {
		value.name = node.name.text
		return super.visit(node)
	}

	override func visit(_ node: EnumCaseParameterSyntax) -> SyntaxVisitorContinueKind {
		var parameter = Parameter()
		if let firstName = node.firstName {
			parameter.name = firstName.text + (node.secondName != nil ? " " + node.secondName!.text : "")
		}
		parameter.type = ParseAnyType<TypeNameTracker>(node: node.type).run()
		parameter.isInout = ParseAnyType<InoutTracker>(node: node.type).run()
		
		value.parameters.append(parameter)
		return super.visit(node)
	}

	// MARK: -

	override func visitPost(_ node: EnumCaseElementSyntax) {
		collection.append(value)
		value.parameters.removeAll()
	}
}
