import Foundation
import SwiftSyntax

class AttributeTracker: SyntaxVisitor, AnyTypeParser {
	var value = Attribute()

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
		value.name = ParseAnyType<TypeNameTracker>(node: node.attributeName).run()
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
		var parameter = Parameter()

		// Handle identifier references (e.g., @attr(someIdentifier))
		if let name = node.expression.as(DeclReferenceExprSyntax.self)?.baseName.text {
			parameter.name = name
			value.parameters.append(parameter)
		}
		// Handle string literals (e.g., @_silgen_name("custom_name"))
		else if let stringLiteral = node.expression.as(StringLiteralExprSyntax.self) {
			// Extract the string value from the segments
			let stringValue = stringLiteral.segments.map { segment in
				if let stringSegment = segment.as(StringSegmentSyntax.self) {
					return stringSegment.content.text
				}
				return ""
			}.joined()
			parameter.name = "\"\(stringValue)\""
			value.parameters.append(parameter)
		}
		// Handle integer literals (e.g., @attr(42))
		else if let intLiteral = node.expression.as(IntegerLiteralExprSyntax.self) {
			parameter.name = intLiteral.literal.text
			value.parameters.append(parameter)
		}
		// Handle boolean literals (e.g., @attr(true))
		else if let boolLiteral = node.expression.as(BooleanLiteralExprSyntax.self) {
			parameter.name = boolLiteral.literal.text
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
