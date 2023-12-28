import Foundation
import SwiftSyntax

class AttributeTracker: SyntaxVisitor, AnyTypeParser {
	var value = Attribute()

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
		value.name = ParseAnyType<TypeNameTracker>(node: node.attributeName).run()

		if let argument = node.arguments, case .token(let tokenSyntax) = argument {
			var parameter = Parameter()
			parameter.name = tokenSyntax.text
			value.parameters.append(parameter)
		}

		return super.visit(node)
	}

	override func visit(_ node: AvailabilityArgumentSyntax) -> SyntaxVisitorContinueKind {
		if let entry = node.argument.as(PlatformVersionSyntax.self) {
			if let major = entry.version?.major, let remainder = entry.version?.components, !remainder.isEmpty {
				var parameter = Parameter()
				parameter.name = entry.platform.text
				parameter.type = "\(major)." + remainder.map { $0.number.text }.joined(separator: ".")
				value.parameters.append(parameter)
			} else if let major = entry.version?.major {
				var parameter = Parameter()
				parameter.name = entry.platform.text
				parameter.type = "\(major)"
				value.parameters.append(parameter)
			}
		} else {
			if case .token(let tokenSyntax) = node.argument {
				var parameter = Parameter()
				parameter.name = tokenSyntax.text
				value.parameters.append(parameter)
			}
		}

		return super.visit(node)
	}

	override func visit(_ node: LabeledExprSyntax) -> SyntaxVisitorContinueKind {
		if let name = node.expression.as(DeclReferenceExprSyntax.self)?.baseName.text {
			var parameter = Parameter()
			parameter.name = name
			value.parameters.append(parameter)
		}
		return super.visit(node)
	}

	override func visit(_ node: ObjCSelectorPieceSyntax) -> SyntaxVisitorContinueKind {
		if let nameNode = node.name?.text {
			var parameter = Parameter()
			parameter.name = nameNode
			value.parameters.append(parameter)
		}
		return super.visit(node)
	}
}
