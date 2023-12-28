import Foundation
import SwiftSyntax

class EnumCaseTracker: SyntaxVisitor, AnyTypeCollectionParser {
	var value = Member()
	var collection = [Member]()
	
	required init() {
		value.kind = .case
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
		value.kind = .case

		let attributes = node.attributes.map { ParseAnyType<AttributeTracker>(node: $0).run() }
		value.attributes.formUnion(attributes)

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

		if ParseDecl<AttributedTypeTracker>(node: node.type).run(keyword: .inout) {
			parameter.decorators.insert(.inout)
		}

		value.parameters.append(parameter)
		return super.visit(node)
	}

	// MARK: -

	override func visitPost(_ node: EnumCaseElementSyntax) {
		collection.append(value)
		value.parameters.removeAll()
	}
}
