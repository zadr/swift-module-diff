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

	override func visit(_ node: OriginallyDefinedInAttributeArgumentsSyntax) -> SyntaxVisitorContinueKind {
		// Handle module: "ModuleName" part
		var moduleParam = Parameter()
		moduleParam.name = "module"

		// Extract the module name from the string literal
		let moduleName = node.moduleName.segments.map { segment in
			if let stringSegment = segment.as(StringSegmentSyntax.self) {
				return stringSegment.content.text
			}
			return ""
		}.joined()
		moduleParam.type = "\"\(moduleName)\""
		value.parameters.append(moduleParam)

		// The platform versions will be handled by visit(_ node: PlatformVersionItemSyntax)
		// which gets called automatically for the platforms collection
		return super.visit(node)
	}

	override func visit(_ node: PlatformVersionItemSyntax) -> SyntaxVisitorContinueKind {
		// Handle platform version items (e.g., iOS 18.0, macOS 14.0)
		let platformVersion = node.platformVersion
		var parameter = Parameter()
		parameter.name = platformVersion.platform.text

		if let major = platformVersion.version?.major, let remainder = platformVersion.version?.components, !remainder.isEmpty {
			parameter.type = "\(major)." + remainder.map { $0.number.text }.joined(separator: ".")
		} else if let major = platformVersion.version?.major {
			parameter.type = "\(major)"
		}

		value.parameters.append(parameter)
		return super.visit(node)
	}

	override func visit(_ node: BackDeployedAttributeArgumentsSyntax) -> SyntaxVisitorContinueKind {
		// Handle @backDeployed(before: platformVersions...)
		// The platform versions will be handled by visit(_ node: PlatformVersionItemSyntax)
		// We just need to add the "before" label context
		// But since parameters are collected automatically, we don't need special handling
		return super.visit(node)
	}

	override func visit(_ node: DocumentationAttributeArgumentSyntax) -> SyntaxVisitorContinueKind {
		var parameter = Parameter()
		parameter.name = node.label.text

		if case .token(let tokenChoice) = node.value {
			parameter.type = tokenChoice.text
		} else if case .string(let stringLiteral) = node.value {
			let stringValue = stringLiteral.segments.map { segment in
				if let stringSegment = segment.as(StringSegmentSyntax.self) {
					return stringSegment.content.text
				}
				return ""
			}.joined()
			parameter.type = "\"\(stringValue)\""
		}

		value.parameters.append(parameter)
		return super.visit(node)
	}

	override func visit(_ node: DynamicReplacementAttributeArgumentsSyntax) -> SyntaxVisitorContinueKind {
		var parameter = Parameter()
		parameter.name = "for"
		parameter.type = node.declName.baseName.text
		value.parameters.append(parameter)
		return super.visit(node)
	}

	override func visit(_ node: ImplementsAttributeArgumentsSyntax) -> SyntaxVisitorContinueKind {
		var typeParam = Parameter()
		typeParam.name = node.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
		value.parameters.append(typeParam)

		var declParam = Parameter()
		declParam.name = node.declName.baseName.text

		if let args = node.declName.argumentNames {
			let argList = args.arguments.map { arg in
				arg.name.text + ":"
			}.joined()
			declParam.name += "(\(argList))"
		}
		value.parameters.append(declParam)

		return super.visit(node)
	}

	// MARK: - Advanced/Rare Attributes

	override func visit(_ node: LabeledSpecializeArgumentSyntax) -> SyntaxVisitorContinueKind {
		var parameter = Parameter()
		parameter.name = node.label.text
		parameter.type = node.value.description.trimmingCharacters(in: .whitespacesAndNewlines)
		value.parameters.append(parameter)
		return super.visit(node)
	}

	override func visit(_ node: SpecializeTargetFunctionArgumentSyntax) -> SyntaxVisitorContinueKind {
		var parameter = Parameter()
		parameter.name = "target"
		parameter.type = node.declName.baseName.text

		if let args = node.declName.argumentNames {
			let argList = args.arguments.map { arg in
				arg.name.text + ":"
			}.joined()
			parameter.type += "(\(argList))"
		}
		value.parameters.append(parameter)
		return super.visit(node)
	}

	override func visit(_ node: GenericWhereClauseSyntax) -> SyntaxVisitorContinueKind {

		var parameter = Parameter()
		parameter.name = "where"

		let whereText = node.requirements.map { req in
			req.description.trimmingCharacters(in: .whitespacesAndNewlines)
		}.joined(separator: ", ")
		parameter.type = whereText
		value.parameters.append(parameter)
		return super.visit(node)
	}

	override func visit(_ node: DifferentiableAttributeArgumentsSyntax) -> SyntaxVisitorContinueKind {
		if let kind = node.kindSpecifier {
			var parameter = Parameter()
			parameter.name = kind.text
			value.parameters.append(parameter)
		}

		return super.visit(node)
	}

	override func visit(_ node: DifferentiabilityWithRespectToArgumentSyntax) -> SyntaxVisitorContinueKind {
		var parameter = Parameter()
		parameter.name = "wrt"

		if case .argument(let singleArg) = node.arguments {
			parameter.type = singleArg.argument.text
		} else if case .argumentList(let argList) = node.arguments {
			let args = argList.arguments.map { $0.argument.text }.joined(separator: ", ")
			parameter.type = "(\(args))"
		}

		value.parameters.append(parameter)
		return super.visit(node)
	}

	override func visit(_ node: DerivativeAttributeArgumentsSyntax) -> SyntaxVisitorContinueKind {
		var parameter = Parameter()
		parameter.name = "of"
		parameter.type = node.originalDeclName.description.trimmingCharacters(in: .whitespacesAndNewlines)

		if let accessor = node.accessorSpecifier {
			parameter.type += "." + accessor.text
		}

		value.parameters.append(parameter)

		return super.visit(node)
	}

	override func visit(_ node: EffectsAttributeArgumentListSyntax) -> SyntaxVisitorContinueKind {
		for token in node {
			var parameter = Parameter()
			parameter.name = token.description.trimmingCharacters(in: .whitespacesAndNewlines)
			value.parameters.append(parameter)
		}
		return super.visit(node)
	}
}
